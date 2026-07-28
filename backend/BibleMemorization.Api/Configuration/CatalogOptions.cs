namespace BibleMemorization.Api.Configuration;

/// <summary>Options for the JSON-backed catalog source.</summary>
public sealed class CatalogOptions
{
    public const string SectionName = "Catalog";

    /// <summary>Path to the catalog JSON file, relative to the content root.</summary>
    public string FilePath { get; set; } = "Data/catalog.v1.json";

    /// <summary>
    /// Absolute base URL prepended to the catalog's relative artifact paths
    /// (e.g. "https://api.example.com"). Empty means the relative paths are served
    /// as-is, for the client to resolve against the API origin.
    /// </summary>
    public string ArtifactBaseUrl { get; set; } = "";
}
