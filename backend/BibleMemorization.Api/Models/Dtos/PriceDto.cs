namespace BibleMemorization.Api.Models.Dtos;

/// <summary>
/// Price of a paid package. Null when <c>IsFree</c> is true.
/// (docs 06/07: explicit, nullable price fields for paid-only attributes).
/// </summary>
public sealed record PriceDto
{
    /// <summary>Price amount (e.g. 4.99).</summary>
    public required decimal Amount { get; init; }

    /// <summary>ISO 4217 currency code (e.g. "USD").</summary>
    public required string Currency { get; init; }
}
