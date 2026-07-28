using BibleMemorization.Api.Models.Dtos;
using BibleMemorization.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace BibleMemorization.Api.Controllers;

/// <summary>
/// Read-only catalog endpoints (Phase 1). No authentication required (guest-first).
/// </summary>
[ApiController]
[Route("api/v1/catalog")]
public sealed class CatalogController : ControllerBase
{
    // Short client-side cache: the Store is visited rarely, so a full refetch
    // every few minutes is fine (doc 07: rely on HTTP caching headers).
    private const int CatalogCacheSeconds = 300;

    private readonly ICatalogService _catalogService;

    public CatalogController(ICatalogService catalogService)
    {
        _catalogService = catalogService;
    }

    /// <summary>Returns the full list of available packages.</summary>
    [HttpGet]
    [ResponseCache(Duration = CatalogCacheSeconds, Location = ResponseCacheLocation.Any)]
    [ProducesResponseType(typeof(CatalogResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<CatalogResponse>> GetCatalog(CancellationToken cancellationToken)
    {
        var catalog = await _catalogService.GetCatalogAsync(cancellationToken);
        return Ok(catalog);
    }

    /// <summary>Returns a single package by id, or 404 if it does not exist.</summary>
    [HttpGet("packages/{id}")]
    [ResponseCache(Duration = CatalogCacheSeconds, Location = ResponseCacheLocation.Any)]
    [ProducesResponseType(typeof(PackageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PackageDto>> GetPackage(string id, CancellationToken cancellationToken)
    {
        var package = await _catalogService.GetPackageAsync(id, cancellationToken);
        return package is null ? NotFound() : Ok(package);
    }
}
