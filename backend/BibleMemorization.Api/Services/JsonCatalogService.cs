using System.Text.Json;
using BibleMemorization.Api.Configuration;
using BibleMemorization.Api.Models.Dtos;
using Microsoft.Extensions.Options;

namespace BibleMemorization.Api.Services;

/// <summary>
/// Catalog service backed by a static JSON file. The file is read once and cached
/// in memory, and automatically reloaded when the file changes on disk.
/// </summary>
public sealed class JsonCatalogService : ICatalogService, IDisposable
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    private readonly string _filePath;
    private readonly Uri? _artifactBaseUri;
    private readonly ILogger<JsonCatalogService> _logger;
    private readonly SemaphoreSlim _loadGate = new(1, 1);

    private CatalogResponse? _cachedCatalog;
    private FileSystemWatcher? _watcher;
    private Timer? _reloadTimer;

    public JsonCatalogService(
        IHostEnvironment environment,
        IOptions<CatalogOptions> options,
        ILogger<JsonCatalogService> logger)
    {
        _filePath = Path.Combine(environment.ContentRootPath, options.Value.FilePath);
        _artifactBaseUri = ParseArtifactBaseUri(options.Value.ArtifactBaseUrl);
        _logger = logger;

        StartWatching();
    }

    public async Task<CatalogResponse> GetCatalogAsync(CancellationToken cancellationToken = default)
    {
        if (_cachedCatalog is not null)
        {
            return _cachedCatalog;
        }

        await _loadGate.WaitAsync(cancellationToken);
        try
        {
            _cachedCatalog ??= await LoadCatalogAsync(cancellationToken);
            return _cachedCatalog;
        }
        finally
        {
            _loadGate.Release();
        }
    }

    public async Task<PackageDto?> GetPackageAsync(string id, CancellationToken cancellationToken = default)
    {
        var catalog = await GetCatalogAsync(cancellationToken);
        return catalog.Packages.FirstOrDefault(
            package => string.Equals(package.Id, id, StringComparison.OrdinalIgnoreCase));
    }

    private async Task<CatalogResponse> LoadCatalogAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_filePath))
        {
            throw new FileNotFoundException($"Catalog file not found at '{_filePath}'.", _filePath);
        }

        await using var stream = File.OpenRead(_filePath);
        var catalog = await JsonSerializer.DeserializeAsync<CatalogResponse>(
            stream, SerializerOptions, cancellationToken)
            ?? throw new InvalidOperationException($"Catalog file '{_filePath}' deserialized to null.");

        catalog = ResolveArtifactUrls(catalog);

        _logger.LogInformation(
            "Loaded catalog version {CatalogVersion} with {PackageCount} package(s).",
            catalog.CatalogVersion, catalog.Packages.Count);

        return catalog;
    }

    private static Uri? ParseArtifactBaseUri(string configuredBaseUrl)
    {
        if (string.IsNullOrWhiteSpace(configuredBaseUrl))
        {
            return null;
        }

        if (!Uri.TryCreate(configuredBaseUrl, UriKind.Absolute, out var baseUri))
        {
            throw new InvalidOperationException(
                $"Catalog:ArtifactBaseUrl must be an absolute URL, but was '{configuredBaseUrl}'.");
        }

        return baseUri;
    }

    /// <summary>
    /// The catalog file stores host-agnostic paths (e.g. "/packages/{id}/{version}/package.zip")
    /// so the same file can be served from any environment. When an artifact base URL is
    /// configured, resolve those paths into the absolute URLs the app consumes.
    /// </summary>
    private CatalogResponse ResolveArtifactUrls(CatalogResponse catalog)
    {
        if (_artifactBaseUri is null)
        {
            return catalog;
        }

        var packages = catalog.Packages
            .Select(package => package with
            {
                ArtifactUrl = ResolveUrl(package.ArtifactUrl),
                ManifestUrl = ResolveUrl(package.ManifestUrl)
            })
            .ToList();

        return catalog with { Packages = packages };
    }

    private string ResolveUrl(string url)
    {
        // Leave already-absolute entries untouched, so a single package can be hosted
        // elsewhere (e.g. a separate CDN) without opting the whole catalog out.
        // The scheme check matters: on Unix, Uri.TryCreate(UriKind.Absolute) accepts a
        // leading-slash path as an absolute file:// URI, which would match every
        // catalog entry and skip resolution entirely.
        if (Uri.TryCreate(url, UriKind.Absolute, out var parsed)
            && (parsed.Scheme == Uri.UriSchemeHttp || parsed.Scheme == Uri.UriSchemeHttps))
        {
            return url;
        }

        return new Uri(_artifactBaseUri!, url).ToString();
    }

    private void StartWatching()
    {
        var directory = Path.GetDirectoryName(_filePath);
        var fileName = Path.GetFileName(_filePath);

        if (directory is null || !Directory.Exists(directory))
        {
            _logger.LogWarning(
                "Catalog directory '{Directory}' does not exist. File watcher not started.", directory);
            return;
        }

        _watcher = new FileSystemWatcher(directory, fileName)
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.CreationTime | NotifyFilters.Size,
            EnableRaisingEvents = true
        };

        _watcher.Changed += OnCatalogFileChanged;
        _watcher.Created += OnCatalogFileChanged;
        _watcher.Deleted += OnCatalogFileChanged;
        _watcher.Renamed += OnCatalogFileChanged;

        _reloadTimer = new Timer(_ => ReloadCatalogAsync(), null, Timeout.Infinite, Timeout.Infinite);

        _logger.LogInformation(
            "Watching catalog file '{FilePath}' for changes.", _filePath);
    }

    private void OnCatalogFileChanged(object sender, FileSystemEventArgs e)
    {
        _logger.LogInformation(
            "Catalog file change detected ({ChangeType}). Scheduling reload.", e.ChangeType);

        // Debounce: reset the timer on every change event. The file may fire
        // multiple events (Created + Changed, etc.) for a single save operation.
        _reloadTimer?.Change(500, Timeout.Infinite);
    }

    private async void ReloadCatalogAsync()
    {
        await _loadGate.WaitAsync();
        try
        {
            _cachedCatalog = await LoadCatalogAsync(CancellationToken.None);
            _logger.LogInformation("Catalog reloaded successfully from disk.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to reload catalog from disk.");
        }
        finally
        {
            _loadGate.Release();
        }
    }

    public void Dispose()
    {
        _reloadTimer?.Dispose();
        if (_watcher is not null)
        {
            _watcher.Changed -= OnCatalogFileChanged;
            _watcher.Created -= OnCatalogFileChanged;
            _watcher.Deleted -= OnCatalogFileChanged;
            _watcher.Renamed -= OnCatalogFileChanged;
            _watcher.Dispose();
        }
        _loadGate.Dispose();
    }
}
