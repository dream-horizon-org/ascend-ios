# Ascend iOS SDK

[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Unified iOS SDK for experiments, feature flags, and A/B testing with a plugin-based architecture.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [License](#license)

## Features

- ✅ **Type-Safe** - Full type validation matching Android implementation
- ✅ **Plugin Architecture** - Modular, extensible design
- ✅ **Automatic Caching** - Three-tier fallback (cache → API → defaults)
- ✅ **Thread Safe** - Concurrent operations with proper synchronization
- ✅ **Retry Logic** - Exponential backoff with jitter
- ✅ **Lifecycle Integration** - Automatic foreground refresh

## Requirements

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## Installation

### Swift Package Manager (Recommended)

#### Using Xcode

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the repository URL: `https://github.com/dream11/ascend-ios`
4. Select **Up to Next Major Version** with `1.0.0`
5. Click **Add Package**

#### Using Package.swift

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dream11/ascend-ios.git", from: "1.0.0")
]
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'Ascend', :git => 'https://github.com/dream11/ascend-ios.git', :tag => '1.0.0'
end
```

Then run:

```bash
pod install
```

## Example App

We've included a complete example app demonstrating how to use the Ascend iOS SDK. Check out the [Example App](Example/README.md) for:

- ✅ Complete integration examples
- ✅ UI showcasing all SDK features
- ✅ Code samples for common use cases
- ✅ Step-by-step setup instructions

To run the example app:
1. Open `Example/AscendExample.xcodeproj` in Xcode
2. Add the Ascend package as a local dependency
3. Build and run on a simulator

## Quick Start

### 1. Import the SDK

```swift
import Ascend
```

### 2. Configure and Initialize

```swift
// Configure core settings
let coreConfig = AscendCoreConfig(
    apiKey: "your-api-key",
    environment: "production"
)

// Configure HTTP settings
let httpConfig = HTTPConfig(
    apiBaseUrl: "https://api.ascend.com",
    defaultHeaders: ["api-key": "your-api-key"]
)

// Configure experiments plugin
let experimentsConfig = AscendExperimentsConfiguration.production(
    apiBaseUrl: "https://api.ascend.com",
    defaultValues: [
        "my_experiment": .dictionary([
            "color": .string("blue"),
            "enabled": .bool(true)
        ])
    ]
)

// Create main configuration
let config = AscendConfig(
    plugins: [AscendPlugin(type: .experiments, config: experimentsConfig)],
    httpConfig: httpConfig,
    coreConfig: coreConfig
)

// Initialize SDK
do {
    try Ascend.initialize(with: config)
    Ascend.user.setUser(userId: "user123")
} catch {
    print("Initialization failed: \(error)")
}
```

### 3. Use Experiments

```swift
// Get the experiments plugin
let experiments = try Ascend.getPlugin(AscendExperiments.self)

// Get experiment values
let color = experiments.getStringValue(for: "my_experiment", with: "color")
let enabled = experiments.getBoolValue(for: "my_experiment", with: "enabled")

// Fetch experiments
experiments.fetchExperiments(for: ["my_experiment": .string("default")]) { response, error in
    if let error = error {
        print("Error: \(error)")
    } else if let response = response {
        print("Loaded \(response.data?.count ?? 0) experiments")
    }
}
```

## Usage

### AppDelegate Initialization

```swift
import UIKit
import Ascend

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Ascend SDK
        let config = AscendConfig(
            plugins: [AscendPlugin(type: .experiments, config: experimentsConfig)],
            httpConfig: httpConfig,
            coreConfig: coreConfig
        )
        
        do {
            try Ascend.initialize(with: config)
        } catch {
            print("Failed to initialize Ascend: \(error)")
        }
        
        return true
    }
}
```

### SceneDelegate Initialization (iOS 13+)

```swift
import UIKit
import Ascend

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, 
               options connectionOptions: UIScene.ConnectionOptions) {
        
        if !Ascend.isInitialized() {
            // Initialize Ascend SDK
            // ... same initialization code as AppDelegate
        }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        // ... rest of scene setup
    }
}
```

## API Reference

### Getting Experiment Values

```swift
let experiments = try Ascend.getPlugin(AscendExperiments.self)

// Boolean values
let isEnabled = experiments.getBoolValue(for: "experiment_key", with: "enabled")

// Integer values
let maxRetries = experiments.getIntValue(for: "experiment_key", with: "maxRetries")

// String values
let buttonColor = experiments.getStringValue(for: "experiment_key", with: "color")

// Double values
let timeout = experiments.getDoubleValue(for: "experiment_key", with: "timeout")

// Long values
let cacheTTL = experiments.getLongValue(for: "experiment_key", with: "ttl")
```

### Advanced Options

```swift
// Don't cache the result
let value = experiments.getStringValue(
    for: "experiment_key",
    with: "variable",
    dontCache: true
)

// Ignore cache and fetch fresh
let freshValue = experiments.getStringValue(
    for: "experiment_key",
    with: "variable",
    ignoreCache: true
)
```

### Fetching and Refreshing Experiments

```swift
// Fetch specific experiments
experiments.fetchExperiments(for: [
    "exp1": .string("default"),
    "exp2": .dictionary(["key": .string("value")])
]) { response, error in
    // Handle response
}

// Refresh all experiments
experiments.refreshExperiments { response, error in
    // Handle response
}

// Get all variables as JSON
if let jsonString = experiments.getAllVariablesJSON(for: "experiment_key") {
    print("Variables: \(jsonString)")
}

// Get experiment variants
let variants = experiments.getExperimentVariants()
for (experimentKey, variant) in variants {
    print("\(experimentKey): \(variant.variantName)")
}
```

### Configuration

```swift
// Production configuration (recommended)
let config = AscendExperimentsConfiguration.production(
    apiBaseUrl: "https://api.ascend.com",
    defaultValues: [
        "experiment_key": .dictionary([
            "key": .string("value")
        ])
    ]
)

// Development configuration (debug logging enabled)
let config = AscendExperimentsConfiguration.development(
    apiBaseUrl: "https://api.ascend.com",
    defaultValues: [...],
    headers: ["api-key": "key"]
)
```

## Architecture

The Ascend iOS SDK follows a **plugin-based architecture** for flexibility and extensibility:

- **Core Module** - Configuration, user management, device info, lifecycle events
- **Common Module** - Logging, networking, storage, serialization utilities
- **Experiments Plugin** - A/B testing, feature flags, experiment management
- **Plugin System** - Registers and manages all plugins with dependency handling

Key components include:
- Automatic caching with three-tier fallback
- Retry logic with exponential backoff and jitter
- Thread-safe operations with proper synchronization
- Comprehensive error handling throughout the SDK

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "SDK not initialized" | Call `Ascend.initialize(with:)` before use. Initialize in `AppDelegate`/`SceneDelegate` |
| "Plugin not found" | Ensure plugin is in `plugins` array: `AscendPlugin(type: .experiments, ...)` |
| Experiments not loading | Check API URL, verify API key, enable `enableDebugLogging: true` |
| Type mismatch warnings | Verify `data_type` in API response matches expected type |

### Enable Debug Logging

```swift
let coreConfig = AscendCoreConfig(
    apiKey: "your-api-key",
    environment: "production",
    enableDebugLogging: true  // Enable debug logs
)
```

## Support

- 📧 **Email**: support@dream11.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/dream11/ascend-ios/issues)

## License

Ascend iOS SDK is available under the MIT license. See the [LICENSE](LICENSE) file for more information.
