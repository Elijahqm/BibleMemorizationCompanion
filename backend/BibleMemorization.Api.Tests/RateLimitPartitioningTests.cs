using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace BibleMemorization.Api.Tests;

/// <summary>
/// The API runs behind nginx, which terminates the connection. Without forwarded headers
/// every request would look like it came from the proxy and all clients would share one
/// rate-limit bucket, so a handful of active users could throttle everyone.
/// </summary>
public sealed class RateLimitPartitioningTests
{
    // Matches PermitLimit in Program.cs.
    private const int PermitLimit = 100;

    private const string ClientA = "203.0.113.10";
    private const string ClientB = "203.0.113.11";

    [Fact]
    public async Task BehindALoopbackProxy_EachForwardedClientGetsItsOwnBucket()
    {
        // Same-host nginx: the connection arrives from loopback, which is trusted by default.
        using var factory = new ProxiedApiFactory(IPAddress.Loopback);
        var client = factory.CreateClient();

        await ExhaustBucketAsync(client, ClientA);

        Assert.Equal(HttpStatusCode.TooManyRequests, await GetStatusAsync(client, ClientA));

        // A different client must be unaffected — this is the whole point of the fix.
        Assert.Equal(HttpStatusCode.OK, await GetStatusAsync(client, ClientB));
    }

    [Fact]
    public async Task FromAnUntrustedConnection_TheForwardedHeaderIsIgnored()
    {
        // Anything but loopback is not a known proxy, so a client cannot forge its way into
        // a fresh bucket by sending the header itself.
        using var factory = new ProxiedApiFactory(IPAddress.Parse("198.51.100.5"));
        var client = factory.CreateClient();

        await ExhaustBucketAsync(client, ClientA);

        Assert.Equal(HttpStatusCode.TooManyRequests, await GetStatusAsync(client, ClientA));

        // Still throttled: both requests keyed on the real connection, not the header.
        Assert.Equal(HttpStatusCode.TooManyRequests, await GetStatusAsync(client, ClientB));
    }

    private static async Task ExhaustBucketAsync(HttpClient client, string forwardedFor)
    {
        for (var i = 0; i < PermitLimit; i++)
        {
            var status = await GetStatusAsync(client, forwardedFor);
            Assert.Equal(HttpStatusCode.OK, status);
        }
    }

    private static async Task<HttpStatusCode> GetStatusAsync(HttpClient client, string forwardedFor)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/catalog");
        request.Headers.Add("X-Forwarded-For", forwardedFor);

        using var response = await client.SendAsync(request);
        return response.StatusCode;
    }

    /// <summary>
    /// Boots the API with a fixed connection address. TestServer leaves RemoteIpAddress
    /// null, so without this the forwarded-headers middleware has no proxy address to
    /// evaluate and the scenario under test cannot happen.
    /// </summary>
    private sealed class ProxiedApiFactory : WebApplicationFactory<Program>
    {
        private readonly IPAddress _connectionAddress;

        public ProxiedApiFactory(IPAddress connectionAddress)
        {
            _connectionAddress = connectionAddress;
        }

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureServices(services =>
                services.AddSingleton<IStartupFilter>(
                    new SetConnectionAddress(_connectionAddress)));
        }

        // A startup filter runs ahead of the app's own pipeline, so the address is in place
        // before UseForwardedHeaders inspects it.
        private sealed class SetConnectionAddress(IPAddress address) : IStartupFilter
        {
            public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next)
                => app =>
                {
                    app.Use(async (context, nextMiddleware) =>
                    {
                        context.Connection.RemoteIpAddress = address;
                        await nextMiddleware();
                    });

                    next(app);
                };
        }
    }
}
