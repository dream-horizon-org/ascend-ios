import SwiftUI
import Ascend

/// Example app demonstrating how to use the Ascend iOS SDK
/// This app showcases all the main features of the package
@main
struct AscendExampleApp: App {
    
    init() {
        // Initialize the Ascend SDK when the app launches
        setupAscendSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
    
    /// Configure and initialize the Ascend SDK
    private func setupAscendSDK() {
        // 1. Configure Core Settings
        let coreConfig = AscendCoreConfig(
            apiKey: "example-api-key",
            environment: "development",
            enableDebugLogging: true
        )
        
        // 2. Configure HTTP Settings
        let httpConfig = HTTPConfig(
            apiBaseUrl: "https://api.ascend.com",
            timeout: 30.0,
            shouldRetry: true,
            maxRetries: 3,
            defaultHeaders: ["api-key": "some-api-key"]
        )
        
        // 3. Configure Experiments Plugin
        let experimentsConfig = AscendExperimentsConfiguration.development(
            apiBaseUrl: "http://localhost:8100",
            apiEndpoint: "/v1/allocations", // Use allocations endpoint
            defaultValues: [
                "test-key": .dictionary([
                    "color": .string("xyz"),
                    "age": .int(100)
                ]),
            ],
            headers: ["api-key": "test-key"]
        )
        
        // 4. Create SDK Configuration
        let config = AscendConfig(
            plugins: [AscendPlugin(type: .experiments, config: experimentsConfig)],
            httpConfig: httpConfig,
            coreConfig: coreConfig
        )
        
        // 5. Initialize the SDK
        do {
            try Ascend.initialize(with: config)
            print("✅ Ascend SDK initialized successfully")
            
            // Set a user (required for experiments)
            Ascend.user.setUser(userId: "example-user-\(UUID().uuidString.prefix(8))")
            
        } catch {
            print("❌ Failed to initialize Ascend SDK: \(error)")
        }
    }
}

