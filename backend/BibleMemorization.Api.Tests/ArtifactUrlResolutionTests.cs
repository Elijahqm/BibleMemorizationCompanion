using System.Text.Json;

namespace BibleMemorization.Api.Tests;

/// <summary>
/// The catalog file stores host-agnostic paths so the same file can be served from any
/// environment; the API resolves them against Catalog:ArtifactBaseUrl. These tests pin
/// both halves of that behaviour.
/// </summary>
public sealed class ArtifactUrlResolutionTests
{
    private const string BaseUrl = "https://artifacts.example.com";

    [Fact]
    public async Task WithBaseUrlConfigured_ArtifactAndManifestUrlsAreAbsolute()
    {
        using var factory = CatalogApiFactory.WithArtifactBaseUrl(BaseUrl);
        var client = factory.CreateClient();

        foreach (var package in await GetPackagesAsync(client))
        {
            var id = package.GetProperty("id").GetString();

            Assert.Equal(
                $"{BaseUrl}/packages/{id}/1.0.0/package.zip",
                package.GetProperty("artifactUrl").GetString());
            Assert.Equal(
                $"{BaseUrl}/packages/{id}/1.0.0/manifest.json",
                package.GetProperty("manifestUrl").GetString());
        }
    }

    [Fact]
    public async Task WithoutBaseUrlConfigured_UrlsStayRelativeToTheApiOrigin()
    {
        using var factory = CatalogApiFactory.WithoutArtifactBaseUrl();
        var client = factory.CreateClient();

        foreach (var package in await GetPackagesAsync(client))
        {
            var artifactUrl = package.GetProperty("artifactUrl").GetString();

            Assert.StartsWith("/packages/", artifactUrl);
            Assert.StartsWith("/packages/", package.GetProperty("manifestUrl").GetString());
        }
    }

    [Fact]
    public async Task WithBaseUrlConfigured_NoUrlPointsAtADeveloperHost()
    {
        // Regression guard for the localhost-pinned catalog the reviewer flagged: the
        // committed catalog must never carry an environment-specific host.
        using var factory = CatalogApiFactory.WithArtifactBaseUrl(BaseUrl);
        var client = factory.CreateClient();

        foreach (var package in await GetPackagesAsync(client))
        {
            Assert.DoesNotContain("localhost", package.GetProperty("artifactUrl").GetString());
            Assert.DoesNotContain("localhost", package.GetProperty("manifestUrl").GetString());
        }
    }

    [Fact]
    public async Task ResolvedArtifactUrlsAreWellFormedAbsoluteHttpUris()
    {
        // Uri.TryCreate(UriKind.Absolute) alone is not enough on Unix, where a leading
        // slash parses as an absolute file:// URI. The scheme is what actually matters.
        using var factory = CatalogApiFactory.WithArtifactBaseUrl(BaseUrl);
        var client = factory.CreateClient();

        foreach (var package in await GetPackagesAsync(client))
        {
            var artifactUrl = package.GetProperty("artifactUrl").GetString();

            Assert.True(
                Uri.TryCreate(artifactUrl, UriKind.Absolute, out var uri),
                $"'{artifactUrl}' is not an absolute URI.");
            Assert.Equal(Uri.UriSchemeHttps, uri!.Scheme);
        }
    }

    private static async Task<List<JsonElement>> GetPackagesAsync(HttpClient client)
    {
        using var document = JsonDocument.Parse(await client.GetStringAsync("/api/v1/catalog"));

        return document.RootElement
            .GetProperty("packages")
            .EnumerateArray()
            .Select(package => package.Clone())
            .ToList();
    }
}
