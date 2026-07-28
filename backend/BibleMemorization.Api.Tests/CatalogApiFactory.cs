using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BibleMemorization.Api.Tests;

/// <summary>
/// Boots the real API in memory. Tests that care about a specific artifact base URL
/// pass one explicitly, so they do not depend on the developer's appsettings.
/// </summary>
public sealed class CatalogApiFactory : WebApplicationFactory<Program>
{
    private readonly string? _artifactBaseUrl;

    public CatalogApiFactory() : this(artifactBaseUrl: null)
    {
    }

    private CatalogApiFactory(string? artifactBaseUrl)
    {
        _artifactBaseUrl = artifactBaseUrl;
    }

    /// <summary>Factory serving the catalog with the given artifact base URL.</summary>
    public static CatalogApiFactory WithArtifactBaseUrl(string artifactBaseUrl)
        => new(artifactBaseUrl);

    /// <summary>Factory serving the catalog with no artifact base URL configured.</summary>
    public static CatalogApiFactory WithoutArtifactBaseUrl()
        => new(string.Empty);

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        if (_artifactBaseUrl is not null)
        {
            builder.UseSetting("Catalog:ArtifactBaseUrl", _artifactBaseUrl);
        }
    }
}
