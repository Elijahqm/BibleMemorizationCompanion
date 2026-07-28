using System.Text.Json;
using BibleMemorization.Api.Configuration;
using BibleMemorization.Api.Models.Dtos;
using Microsoft.Extensions.Options;

namespace BibleMemorization.Api.Services;

/// <summary>
/// Catalog service backed by a static JSON file. The file is read once and cached
/// in memory, since the catalog is immutable at runtime in Phase 1.
/// </summary>
public sealed class JsonCatalogService : ICatalogService
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    private readonly string _filePath;
    private readonly Uri? _artifactBaseUri;
    private readonly ILogger<JsonCatalogService> _logger;
    private readonly SemaphoreSlim _loadGate = new(1, 1);

    private CatalogResponse? _cachedCatalog;

    public JsonCatalogService(
        IHostEnvironment environment,
        IOptions<CatalogOptions> options,
        ILogger<JsonCatalogService> logger)
    {
        _filePath = Path.Combine(environment.ContentRootPath, options.Value.FilePath);
        _artifactBaseUri = ParseArtifactBaseUri(options.Value.ArtifactBaseUrl);
        _logger = logger;
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
}
