namespace BibleMemorization.Api.Configuration;

/// <summary>Options for the JSON-backed catalog source.</summary>
public sealed class CatalogOptions
{
    public const string SectionName = "Catalog";

    /// <summary>Path to the catalog JSON file, relative to the content root.</summary>
    public string FilePath { get; set; } = "Data/catalog.v1.json";
}
