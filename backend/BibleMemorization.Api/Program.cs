using System.Threading.RateLimiting;
using BibleMemorization.Api.Configuration;
using BibleMemorization.Api.Services;
using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Net.Http.Headers;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Catalog: JSON-backed source, read once and cached (singleton).
builder.Services.Configure<CatalogOptions>(
    builder.Configuration.GetSection(CatalogOptions.SectionName));
builder.Services.AddSingleton<ICatalogService, JsonCatalogService>();

// Structured (JSON) console logs outside Development for easier log ingestion.
// Each entry carries the request TraceId, giving basic request tracing out of the box.
if (!builder.Environment.IsDevelopment())
{
    builder.Logging.ClearProviders();
    builder.Logging.AddJsonConsole();
}

// Request logging (method, path, status, duration) for tracing.
builder.Services.AddHttpLogging(options =>
{
    options.LoggingFields =
        HttpLoggingFields.RequestMethod
        | HttpLoggingFields.RequestPath
        | HttpLoggingFields.ResponseStatusCode
        | HttpLoggingFields.Duration;
});

// Basic rate limiting: fixed window per client IP (doc 07: "Basic rate limiting").
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var clientKey = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(clientKey, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 100,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    // OpenAPI document at /openapi/v1.json
    app.MapOpenApi();
    // Scalar UI to test the APIs at /scalar
    app.MapScalarApiReference();
}
else
{
    // Enforce HTTPS strictly in non-development environments.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseHttpLogging();

app.UseRateLimiter();

// Serve package artifacts (package.zip, manifest.json, package.sha256) from wwwroot.
// Paths are immutable per version, e.g. /packages/{id}/{version}/package.zip (docs 06/09),
// so artifacts can be cached aggressively by clients and CDNs.
var artifactContentTypes = new FileExtensionContentTypeProvider();
artifactContentTypes.Mappings[".sha256"] = "text/plain";
app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = artifactContentTypes,
    OnPrepareResponse = context =>
    {
        context.Context.Response.Headers[HeaderNames.CacheControl] =
            "public,max-age=31536000,immutable";
    }
});

app.UseAuthorization();

app.MapControllers();

app.Run();
