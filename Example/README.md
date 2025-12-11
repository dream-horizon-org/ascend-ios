# Ascend iOS SDK - Example App

This example app demonstrates how to integrate and use the Ascend iOS SDK in your iOS application.

## Overview

The Example app showcases all the main features of the Ascend SDK:

- ✅ **SDK Initialization** - How to configure and initialize the SDK
- ✅ **Experiments** - Fetching and using experiment values (string, bool, int, double, long)
- ✅ **User Management** - Setting users, guest IDs, and authentication
- ✅ **Device Information** - Accessing device and app information
- ✅ **Plugin System** - Understanding the plugin architecture

## Getting Started

### Prerequisites

- Xcode 12.0 or later
- iOS 13.0 or later
- Swift 5.0 or later

### Setup

1. **Open the Project**
   ```bash
   cd Example
   open AscendExample.xcodeproj
   ```

2. **Add the Ascend Package**
   - In Xcode, select the project (blue icon)
   - Select the `AscendExample` target
   - Go to the **Package Dependencies** tab
   - Click the **+** button
   - Click **Add Local...**
   - Navigate to the parent directory (`../`) and select the `ascend-ios` folder
   - Click **Add**

3. **Build and Run**
   - Select an iOS Simulator (e.g., iPhone 15)
   - Press `⌘R` to build and run

## App Structure

### Main Components

- **AscendExampleApp.swift** - App entry point with SDK initialization
- **MainView.swift** - Main UI with tab navigation
  - **OverviewView** - SDK status and features overview
  - **ExperimentsView** - Experiment fetching and value retrieval
  - **UserView** - User management operations
  - **DeviceView** - Device information display

## Code Examples

### 1. Initialize the SDK

```swift
import Ascend

// Configure core settings
let coreConfig = AscendCoreConfig(
    apiKey: "your-api-key",
    environment: "development",
    enableDebugLogging: true
)

// Configure HTTP settings
let httpConfig = HTTPConfig(
    apiBaseUrl: "https://api.example.com",
    timeout: 30.0,
    shouldRetry: true,
    maxRetries: 3,
    defaultHeaders: ["api-key": "your-api-key"]
)

// Configure experiments plugin
let experimentsConfig = AscendExperimentsConfiguration.development(
    apiBaseUrl: "https://api.example.com",
    defaultValues: [
        "my_experiment": .dictionary([
            "color": .string("blue"),
            "enabled": .bool(true)
        ])
    ],
    headers: ["api-key": "your-api-key"]
)

// Create configuration
let config = AscendConfig(
    plugins: [AscendPlugin(type: .experiments, config: experimentsConfig)],
    httpConfig: httpConfig,
    coreConfig: coreConfig
)

// Initialize
try Ascend.initialize(with: config)
Ascend.user.setUser(userId: "user-123")
```

### 2. Get Experiment Values

```swift
// Get the experiments plugin
let experiments = try Ascend.getPlugin(AscendExperiments.self)

// Get string value
if let color = experiments.getStringValue(for: "button_experiment", with: "color") {
    print("Color: \(color)")
}

// Get boolean value
let isEnabled = experiments.getBoolValue(for: "button_experiment", with: "enabled")

// Get integer value
if let size = experiments.getIntValue(for: "button_experiment", with: "size") {
    print("Size: \(size)")
}
```

### 3. Fetch Experiments from API

```swift
experiments.fetchExperiments(for: ["button_experiment": .string("default")]) { response, error in
    if let error = error {
        print("Error: \(error)")
    } else if let response = response {
        print("Fetched \(response.data?.count ?? 0) experiments")
    }
}
```

### 4. User Management

```swift
// Set user
Ascend.user.setUser(userId: "user-123")

// Set guest
Ascend.user.setGuest(guestId: "guest-456")

// Get current user ID
let userId = Ascend.user.getUserId()

// Check if authenticated
let isAuthenticated = Ascend.user.isAuthenticated()
```

### 5. Device Information

```swift
// Get device model
let model = Ascend.deviceInfo.getDeviceModel()

// Get system version
let systemVersion = Ascend.deviceInfo.getSystemVersion()

// Check network availability
let hasNetwork = Ascend.deviceInfo.isNetworkAvailable()

// Get app version
let appVersion = Ascend.deviceInfo.getAppVersion()
```

## Features Demonstrated

### Experiments Tab
- Input API path and variable name
- Load experiment values (string, bool, int)
- Fetch experiments from API
- View experiment data

### User Tab
- View current user information
- Set new user ID
- Set guest user
- Check authentication status

### Device Tab
- View device model and system info
- Check network availability
- View app version information

## Notes

- The example uses mock data for testing (see `ExperimentsAPI.swift`)
- Replace API URLs and keys with your actual values
- The SDK supports automatic caching and retry logic
- All operations are thread-safe

## Learn More

For more information about the Ascend iOS SDK, see the main [README](../README.md).

## License

This example app is part of the Ascend iOS SDK and follows the same license.

