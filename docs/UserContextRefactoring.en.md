# UserContext Refactoring Documentation

## Overview

This refactoring replaces the original `ICurrentUserAccessor` with a new `UserContext` and `IUserContextAccessor` architecture.

## New Architecture Components

### 1. UserContext
```csharp
public sealed record UserContext(
    string UserId,
    string UserName,
    string? TenantId = null,
    string? Email = null,
    IReadOnlyList<string>? Roles = null,
    string? SuperiorId = null
);
```

### 2. IUserContextAccessor
- Uses `AsyncLocal` for call chain isolation
- Supports nested `Push/Pop` operations
- Registered as `Singleton`

### 3. IUserContextLoader
- Loads `UserContext` through `ClaimsPrincipal` using `UserManager`
- Provides `LoadAsync` and `LoadAndSetAsync` methods

### 4. UserContextHubFilter
- SignalR Hub filter
- Automatically sets user context when connection is established

## Usage Methods

### Basic Usage

```csharp
// Inject in service
public class MyService
{
    private readonly IUserContextAccessor _userContextAccessor;

    public MyService(IUserContextAccessor userContextAccessor)
    {
        _userContextAccessor = userContextAccessor;
    }

    public void DoSomething()
    {
        var currentUser = _userContextAccessor.Current;
        if (currentUser != null)
        {
            // Use user information
            var userId = currentUser.UserId;
            var userName = currentUser.UserName;
            var roles = currentUser.Roles;
        }
    }
}
```

### Nested Context

```csharp
// Push new user context
using (var scope = _userContextAccessor.Push(newUserContext))
{
    // Within this scope, Current returns newUserContext
    var context = _userContextAccessor.Current;
    
    // Execute operations requiring specific user context
    await DoSomethingWithUserContext();
}
// Context automatically popped when scope ends
```

### Manual Context Setting

```csharp
// Set current user context
_userContextAccessor.Set(userContext);

// Clear current user context
_userContextAccessor.Clear();
```

### Using in SignalR Hub

```csharp
public class MyHub : Hub
{
    private readonly IUserContextAccessor _userContextAccessor;

    public MyHub(IUserContextAccessor userContextAccessor)
    {
        _userContextAccessor = userContextAccessor;
    }

    public async Task SendMessage(string message)
    {
        var currentUser = _userContextAccessor.Current;
        if (currentUser != null)
        {
            await Clients.All.SendAsync("ReceiveMessage", currentUser.UserName, message);
        }
    }
}
```

## Migration Guide

### Migrating from ICurrentUserAccessor

**Old Code:**
```csharp
@inject ICurrentUserAccessor CurrentUserAccessor

var sessionInfo = CurrentUserAccessor.SessionInfo;
var userId = sessionInfo?.UserId;
```

**New Code:**
```csharp
@inject IUserContextAccessor UserContextAccessor

var userContext = UserContextAccessor.Current;
var userId = userContext?.UserId;
```

### Migrating from SessionInfo

**Old Code:**
```csharp
var sessionInfo = new SessionInfo(userId, userName, displayName, ipAddress, tenantId, profilePicture, status);
```

**New Code:**
```csharp
var userContext = new UserContext(userId, userName, tenantId, email, roles, superiorId);
```

> **Note:** `SessionInfo` has been completely removed, all Fusion components now directly use `UserContext`.

## Advantages

1. **Thread Safety**: Uses `AsyncLocal` to ensure thread safety
2. **Call Chain Isolation**: Each async call chain has independent user context
3. **Nested Support**: Supports nested context management
4. **Performance Optimization**: Reduces unnecessary database queries
5. **Type Safety**: Uses strongly-typed `UserContext` record
6. **Backward Compatibility**: Maintains compatibility with existing code through adapters

## Notes

1. `IUserContextAccessor` is registered as `Singleton`, but uses `AsyncLocal` internally to ensure thread safety
2. In SignalR connections, `UserContextHubFilter` automatically sets user context
3. The existing `ICurrentUserAccessor` has been completely removed, all code now uses the new `IUserContextAccessor`
4. The new `UserContext` doesn't include `IPAddress` and `ProfilePictureDataUrl`. If these are needed, you can extend `UserContext` or use other methods to obtain this information 