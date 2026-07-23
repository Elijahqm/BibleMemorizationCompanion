using System.Text.Json.Serialization;

namespace BibleMemorization.Api.Models.Enums;

/// <summary>
/// Catalog package type. Serialized as an explicit string
/// (doc 07: "Explicit enum-like strings for packageType").
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter<PackageType>))]
public enum PackageType
{
    [JsonStringEnumMemberName("book")]
    Book,

    [JsonStringEnumMemberName("season")]
    Season,

    [JsonStringEnumMemberName("audio_addon")]
    AudioAddon
}
