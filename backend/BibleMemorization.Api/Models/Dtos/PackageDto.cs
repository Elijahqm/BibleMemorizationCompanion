using BibleMemorization.Api.Models.Enums;

namespace BibleMemorization.Api.Models.Dtos;

/// <summary>
/// Catalog item as consumed by the mobile app.
/// Contract based on docs 06 (Catalog Item Model), 07 (API) and 08 (Data Models).
/// </summary>
public sealed record PackageDto
{
    /// <summary>Stable package identifier (e.g. "cb-daniel-1-6").</summary>
    public required string Id { get; init; }

    /// <summary>Title shown in the store (e.g. "CB Daniel 1-6").</summary>
    public required string Title { get; init; }

    /// <summary>Package type: book, season or audio_addon.</summary>
    public required PackageType PackageType { get; init; }

    /// <summary>Content language (ISO code, e.g. "es").</summary>
    public required string Language { get; init; }

    /// <summary>Semantic package version (immutable, e.g. "1.0.0").</summary>
    public required string Version { get; init; }

    /// <summary>Artifact size in bytes.</summary>
    public required long SizeBytes { get; init; }

    /// <summary>Whether the package is free.</summary>
    public required bool IsFree { get; init; }

    /// <summary>Package price. Null when <see cref="IsFree"/> is true.</summary>
    public PriceDto? Price { get; init; }

    /// <summary>
    /// Whether the user already owns this paid package.
    /// Always false in the guest-first phase (no entitlements yet).
    /// </summary>
    public bool Owned { get; init; }

    /// <summary>Direct URL to the .zip artifact (direct-link download).</summary>
    public required string ArtifactUrl { get; init; }

    /// <summary>URL to the package's manifest.json.</summary>
    public required string ManifestUrl { get; init; }

    /// <summary>SHA-256 checksum of the .zip artifact for integrity verification.</summary>
    public required string ChecksumSha256 { get; init; }

    /// <summary>Minimum app version compatible with this package.</summary>
    public required string MinAppVersion { get; init; }

    /// <summary>
    /// Id of the base package an audio add-on depends on.
    /// Only applies when <see cref="PackageType"/> is <see cref="PackageType.AudioAddon"/>.
    /// </summary>
    public string? BasePackageId { get; init; }
}
