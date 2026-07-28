using System.Net;
using System.Text.Json;
using BibleMemorization.Api.Models.Enums;

namespace BibleMemorization.Api.Tests;

/// <summary>
/// Contract tests for the payloads the Flutter app consumes. These pin the wire shape,
/// not the implementation, so mobile integration cannot regress silently.
/// </summary>
public sealed class CatalogContractTests : IClassFixture<CatalogApiFactory>
{
    private static readonly string[] AllowedPackageTypes = ["book", "season", "audio_addon"];

    private readonly CatalogApiFactory _factory;

    public CatalogContractTests(CatalogApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetCatalog_ReturnsExpectedTopLevelShapeAndNonEmptyPackages()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/catalog");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = document.RootElement;

        Assert.Equal(JsonValueKind.String, root.GetProperty("catalogVersion").ValueKind);
        Assert.Equal(JsonValueKind.String, root.GetProperty("publishedAt").ValueKind);

        var packages = root.GetProperty("packages");
        Assert.Equal(JsonValueKind.Array, packages.ValueKind);
        Assert.NotEmpty(packages.EnumerateArray());
    }

    [Fact]
    public async Task GetCatalog_EveryPackageCarriesTheFieldsTheAppRequires()
    {
        var client = _factory.CreateClient();

        using var document = JsonDocument.Parse(
            await client.GetStringAsync("/api/v1/catalog"));

        string[] requiredFields =
        [
            "id", "title", "packageType", "language", "version", "sizeBytes",
            "isFree", "owned", "artifactUrl", "manifestUrl", "checksumSha256", "minAppVersion"
        ];

        foreach (var package in document.RootElement.GetProperty("packages").EnumerateArray())
        {
            var id = package.GetProperty("id").GetString();

            foreach (var field in requiredFields)
            {
                Assert.True(
                    package.TryGetProperty(field, out var value) && value.ValueKind != JsonValueKind.Null,
                    $"Package '{id}' is missing required field '{field}'.");
            }
        }
    }

    [Fact]
    public async Task GetPackage_ReturnsOkForAKnownId()
    {
        var client = _factory.CreateClient();

        // Take an id from the catalog itself rather than hard-coding one, so the test
        // keeps working as packages are added or renamed.
        using var catalog = JsonDocument.Parse(await client.GetStringAsync("/api/v1/catalog"));
        var knownId = catalog.RootElement.GetProperty("packages")[0].GetProperty("id").GetString();

        var response = await client.GetAsync($"/api/v1/catalog/packages/{knownId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var package = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(knownId, package.RootElement.GetProperty("id").GetString());
    }

    [Fact]
    public async Task GetPackage_ReturnsNotFoundForAnUnknownId()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/catalog/packages/does-not-exist");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetCatalog_SerializesPackageTypeAsAnEnumLikeString()
    {
        var client = _factory.CreateClient();

        using var document = JsonDocument.Parse(await client.GetStringAsync("/api/v1/catalog"));

        foreach (var package in document.RootElement.GetProperty("packages").EnumerateArray())
        {
            var packageType = package.GetProperty("packageType");

            // A numeric value here would mean the enum lost its string converter,
            // which silently breaks the app's parser.
            Assert.Equal(JsonValueKind.String, packageType.ValueKind);
            Assert.Contains(packageType.GetString(), AllowedPackageTypes);
        }
    }

    [Theory]
    [InlineData(PackageType.Book, "book")]
    [InlineData(PackageType.Season, "season")]
    [InlineData(PackageType.AudioAddon, "audio_addon")]
    public void PackageType_SerializesToItsDocumentedString(PackageType packageType, string expected)
    {
        // Covers the values the current catalog does not exercise yet.
        var json = JsonSerializer.Serialize(packageType, JsonSerializerOptions.Web);

        Assert.Equal($"\"{expected}\"", json);
    }
}
