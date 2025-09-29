# UserProfile State Management Refactoring Summary

This refactoring transforms `UserProfileStateService` into a solution that adheres to Blazor state management best practices.

## Refactoring Key Points

### 1. Immutable Data Structure (Single Source of Truth)
- **Old Version**: `UserProfile` was a mutable class, prone to "dirty reference" issues
- **New Version**: `UserProfile` changed to immutable record, ensuring single source of truth

```csharp
// New immutable UserProfile record
public sealed record UserProfile(
    string UserId,
    string UserName,
    string Email,
    // ... other properties
)
{
    public static UserProfile Empty => new(
        UserId: string.Empty,
        UserName: string.Empty,
        Email: string.Empty
    );
}
```

### 2. Precise Notification Mechanism
- **Old Version**: `event Func<Task>? OnChange` - Async events, prone to race conditions
- **New Version**: `event EventHandler<UserProfile>? Changed` - Sync events, directly passing new snapshots

```csharp
// New event definition
public event EventHandler<UserProfile>? Changed;

// Subscription method
UserProfileState.Changed += (sender, userProfile) => {
    // Receive new UserProfile snapshot
    InvokeAsync(StateHasChanged);
};
```

### 3. Concurrency Safety
- Use `SemaphoreSlim` to protect Initialize/Refresh operations
- Prevent data inconsistency caused by concurrent loading

```csharp
private readonly SemaphoreSlim _semaphore = new(1, 1);

public async Task EnsureInitializedAsync(string userId, CancellationToken cancellationToken = default)
{
    await _semaphore.WaitAsync(cancellationToken);
    try
    {
        // Safe initialization logic
    }
    finally
    {
        _semaphore.Release();
    }
}
```

### 4. Cache Control Optimization
- **Old Version**: Uses `UserName` as cache key, not stable enough
- **New Version**: Uses `UserId` as cache key, more stable and reliable

```csharp
private string GetApplicationUserCacheKey(string userId)
{
    return $"GetApplicationUserDto:UserId:{userId}";
}
```

### 5. Interface Design
Added `IUserProfileState` interface for clear separation of responsibilities:

```csharp
public interface IUserProfileState
{
    UserProfile Value { get; }
    event EventHandler<UserProfile>? Changed;
    
    Task EnsureInitializedAsync(string userId, CancellationToken cancellationToken = default);
    Task RefreshAsync(CancellationToken cancellationToken = default);
    void Set(UserProfile userProfile);
    void UpdateLocal(string? profilePictureDataUrl = null, ...);
    void ClearCache();
}
```

## Usage Methods

### 1. Initialize in Layout Component

```razor
@using CleanArchitecture.Blazor.Application.Common.Interfaces.Identity
@inject IUserProfileState UserProfileState

protected override async Task OnInitializedAsync()
{
    var authState = await AuthState;
    var userId = authState.User.GetUserId();
    
    if (!string.IsNullOrEmpty(userId))
    {
        await UserProfileState.EnsureInitializedAsync(userId);
        UserProfileState.Changed += OnUserProfileChanged;
    }
}

private void OnUserProfileChanged(object? sender, UserProfile userProfile)
{
    InvokeAsync(StateHasChanged);
}
```

### 2. Use Through Cascading Parameters

```razor
<CascadingValue Value="UserProfileState.Value" Name="UserProfile">
    @ChildContent
</CascadingValue>
```

### 3. Consume in Components

```razor
[CascadingParameter(Name = "UserProfile")] 
public UserProfile UserProfile { get; set; } = UserProfile.Empty;

// Or directly inject service
@inject IUserProfileState UserProfileState

// Access current value
var currentProfile = UserProfileState.Value;
```

### 4. Update State

```csharp
// Local state sync after database update
UserProfileState.UpdateLocal(
    profilePictureDataUrl: newPictureUrl,
    displayName: newDisplayName
);

// Or set complete new state
UserProfileState.Set(newUserProfile);

// Force refresh from database
await UserProfileState.RefreshAsync();
```

## Lifecycle Management

Service registered as `Scoped`, one instance per Blazor circuit/connection:

```csharp
services.AddScoped<IUserProfileState, UserProfileStateService>();
```

## Advantages

1. **Immutable Updates**: Use `record with` expressions, easy to compare and debug
2. **Single Source of Truth**: All components read the same snapshot from the same Store
3. **Precise Notifications**: Only trigger updates when truly changed
4. **Concurrency Safety**: Prevent state inconsistency caused by concurrent operations
5. **Cache Optimization**: Use stable UserId key, provide precise cache control
6. **Type Safety**: Strongly-typed interface, compile-time checking

## Migration Notes

1. Change all `UserProfileStateService` injections to `IUserProfileState`
2. Change `OnChange` event subscriptions to `Changed` events
3. Change `InitializeAsync(userName)` to `EnsureInitializedAsync(userId)`
4. Change `RefreshAsync(userName)` to `RefreshAsync()`
5. Change `UpdateUserProfile(...)` to `UpdateLocal(...)` or `Set(...)`
6. Use `Value` property to get current state, not `UserProfile` property

This refactoring significantly improves the reliability, performance, and development experience of state management.
