# IP Geolocation Service Usage Guide

This project has implemented a complete IP geolocation service that calls the `http://ip-api.com/json/` API to obtain detailed geographic location information. This service complies with Clean Architecture framework design.

## Service Structure

### 1. Interface Definition (Application Layer)
- **File Location**: `src/Application/Common/Interfaces/IGeolocationService.cs`
- **Interface**: `IGeolocationService`
- **Functions**: 
  - `GetCountryAsync(string ipAddress)` - Get country code (using ipapi.co)
  - `GetGeolocationAsync(string ipAddress)` - Get detailed geographic location information (using ip-api.com)

### 2. Service Implementation (Infrastructure Layer)
- **File Location**: `src/Infrastructure/Services/GeolocationService.cs`
- **Class**: `GeolocationService`
- **Features**:
  - Uses HttpClient to call ip-api.com API for detailed information
  - Uses HttpClient to call ipapi.co API for country codes
  - Includes complete error handling and logging
  - Supports timeout and cancellation tokens
  - Returns structured geographic location information

### 3. Extension Methods
- **File Location**: `src/Infrastructure/Extensions/LoginAuditExtensions.cs`
- **Function**: Provides geolocation enhancement methods for LoginAudit entities

### 4. Helper Services
- **File Location**: `src/Infrastructure/Services/LoginAuditService.cs`
- **Function**: Demonstrates how to use the geolocation service in actual business scenarios

## Usage Examples

### 1. Basic Usage - Get Country Code

```csharp
public class ExampleController : ControllerBase
{
    private readonly IGeolocationService _geolocationService;

    public ExampleController(IGeolocationService geolocationService)
    {
        _geolocationService = geolocationService;
    }

    [HttpGet("country/{ip}")]
    public async Task<string?> GetCountry(string ip)
    {
        return await _geolocationService.GetCountryAsync(ip);
    }
}
```

### 2. Get Detailed Geographic Location Information

```csharp
[HttpGet("location/{ip}")]
public async Task<GeolocationInfo?> GetLocation(string ip)
{
    return await _geolocationService.GetGeolocationAsync(ip);
}
```

### 3. Use in Login Auditing

```csharp
public class AuthenticationService
{
    private readonly IGeolocationService _geolocationService;

    public async Task<LoginAudit> CreateLoginAudit(string userId, string userName, string ipAddress)
    {
        var loginAudit = new LoginAudit
        {
            UserId = userId,
            UserName = userName,
            IpAddress = ipAddress,
            LoginTimeUtc = DateTimeOffset.UtcNow
        };

        // Use extension method to add geolocation information
        await loginAudit.EnrichWithGeolocationAsync(_geolocationService);
        
        return loginAudit;
    }
}
```

### 4. Use LoginAuditService

```csharp
public class LoginController : ControllerBase
{
    private readonly LoginAuditService _loginAuditService;

    public LoginController(LoginAuditService loginAuditService)
    {
        _loginAuditService = loginAuditService;
    }

    [HttpPost("audit")]
    public async Task<LoginAudit> CreateAudit([FromBody] LoginRequest request)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        
        return await _loginAuditService.CreateLoginAuditAsync(
            request.UserId,
            request.UserName,
            clientIp,
            Request.Headers["User-Agent"].ToString(),
            "Internal",
            true
        );
    }
}
```

## API Response Examples

### GetCountryAsync Response
```
CN
```

### GetGeolocationAsync Response
Detailed information returned using ip-api.com API:
```json
{
  "ipAddress": "24.48.0.1",
  "country": "CA",
  "countryName": "Canada",
  "region": "Quebec",
  "city": "Montreal",
  "postalCode": "H1L",
  "latitude": 45.6026,
  "longitude": -73.5167,
  "timezone": "America/Toronto",
  "isp": "Le Groupe Videotron Ltee",
  "organization": "Videotron Ltee"
}
```

## Configuration Instructions

The service is already registered in `Infrastructure/DependencyInjection.cs`:

```csharp
services.AddHttpClient<IGeolocationService, GeolocationService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(10);
    client.DefaultRequestHeaders.Add("User-Agent", "CleanArchitectureBlazorServer/1.0");
});
```

## Error Handling

The service includes complete error handling:
- HTTP request exceptions
- Timeout handling
- JSON deserialization errors
- Invalid IP address handling
- API error response handling

## Logging

The service uses Microsoft.Extensions.Logging for logging:
- Debug level: Detailed information for successful requests
- Warning level: API errors or invalid responses
- Error level: Exception situations

## Important Notes

1. **API Selection**: 
   - `GetCountryAsync` uses ipapi.co API (has free usage limits, 1000 requests per day)
   - `GetGeolocationAsync` uses ip-api.com API (free version 45 requests per minute, no commercial use restrictions)
2. **Network Dependency**: Service depends on external APIs, requires network connection
3. **Performance Considerations**: Recommended for use in non-critical paths, or implement caching mechanism
4. **Privacy Considerations**: Ensure compliance with relevant privacy regulations when handling IP address information
5. **API Stability**: ip-api.com provides more stable service and more detailed geographic location information
