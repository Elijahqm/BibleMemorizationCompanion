using BibleMemorization.Api.Models.Dtos;

namespace BibleMemorization.Api.Services;

/// <summary>
/// Read access to the package catalog. Phase 1 is backed by a static JSON file;
/// a later phase may back it with EF Core + MySQL behind the same interface.
/// </summary>
public interface ICatalogService
{
    /// <summary>Returns the full catalog.</summary>
    Task<CatalogResponse> GetCatalogAsync(CancellationToken cancellationToken = default);

    /// <summary>Returns a single package by id, or null if it does not exist.</summary>
    Task<PackageDto?> GetPackageAsync(string id, CancellationToken cancellationToken = default);
}
