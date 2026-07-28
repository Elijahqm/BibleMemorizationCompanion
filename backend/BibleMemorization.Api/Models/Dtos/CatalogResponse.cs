namespace BibleMemorization.Api.Models.Dtos;

/// <summary>
/// Response of GET /api/v1/catalog.
/// Shape based on doc 07 (Example Catalog Response Shape).
/// </summary>
public sealed record CatalogResponse
{
    /// <summary>Version of the published catalog (e.g. "1").</summary>
    public required string CatalogVersion { get; init; }

    /// <summary>Catalog publication timestamp (UTC).</summary>
    public required DateTimeOffset PublishedAt { get; init; }

    /// <summary>List of available packages.</summary>
    public required IReadOnlyList<PackageDto> Packages { get; init; }
}
