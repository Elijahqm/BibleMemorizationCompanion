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
    private readonly ILogger<JsonCatalogService> _logger;
    private readonly SemaphoreSlim _loadGate = new(1, 1);

    private CatalogResponse? _cachedCatalog;

    public JsonCatalogService(
        IHostEnvironment environment,
        IOptions<CatalogOptions> options,
        ILogger<JsonCatalogService> logger)
    {
        _filePath = Path.Combine(environment.ContentRootPath, options.Value.FilePath);
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

        _logger.LogInformation(
            "Loaded catalog version {CatalogVersion} with {PackageCount} package(s).",
            catalog.CatalogVersion, catalog.Packages.Count);

        return catalog;
    }
}
