import SwiftUI
import Ascend

/// Main view with tab navigation showcasing different SDK features
struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }
                .tag(0)
            
            // Experiments Tab
            ExperimentsView()
                .tabItem {
                    Label("Experiments", systemImage: "flask.fill")
                }
                .tag(1)
            
            // User Tab
            UserView()
                .tabItem {
                    Label("User", systemImage: "person.fill")
                }
                .tag(2)
            
            // Device Tab
            DeviceView()
                .tabItem {
                    Label("Device", systemImage: "iphone")
                }
                .tag(3)
        }
    }
}

// MARK: - Overview View

struct OverviewView: View {
    @State private var sdkStatus = "Checking..."
    @State private var isInitialized = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Ascend iOS SDK")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Example App")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // SDK Status Card
                    Card(title: "SDK Status", icon: "checkmark.circle.fill", color: isInitialized ? .green : .orange) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: isInitialized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(isInitialized ? .green : .orange)
                                Text(sdkStatus)
                                    .font(.body)
                            }
                            
                            if isInitialized {
                                Text("The SDK is ready to use!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Quick Info
                    if isInitialized {
                        HStack(spacing: 16) {
                            InfoBox(title: "Plugins", value: "\(Ascend.getRegisteredPlugins().count)")
                            InfoBox(title: "User ID", value: Ascend.user.getUserId().isEmpty ? "Not set" : "Set")
                        }
                    }
                    
                    // Features List
                    Card(title: "SDK Features", icon: "star.fill", color: .blue) {
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "flask.fill", text: "A/B Testing & Experiments")
                            FeatureRow(icon: "person.fill", text: "User Management")
                            FeatureRow(icon: "iphone", text: "Device Information")
                            FeatureRow(icon: "puzzlepiece.fill", text: "Plugin Architecture")
                            FeatureRow(icon: "arrow.clockwise", text: "Automatic Caching")
                        }
                    }
                    
                    // Code Example
                    Card(title: "Quick Start", icon: "code", color: .purple) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Initialize SDK")
                            Text("2. Set user")
                            Text("3. Get experiments plugin")
                            Text("4. Fetch and use experiment values")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Overview")
            .onAppear {
                checkSDKStatus()
            }
        }
    }
    
    private func checkSDKStatus() {
        isInitialized = Ascend.isInitialized()
        sdkStatus = isInitialized ? "Initialized" : "Not Initialized"
    }
}

// MARK: - Experiments View

struct ExperimentsView: View {
    @State private var experimentKey = "test-key"
    @State private var variableName = "color"
    @State private var stringValue: String?
    @State private var boolValue: Bool?
    @State private var intValue: Int?
    @State private var fetchStatus = "Ready"
    @State private var selectedType: ValueType? = nil
    
    enum ValueType {
        case string
        case boolean
        case integer
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    Card(title: "Experiment Input", icon: "textfield", color: .blue) {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("API Path")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter API path", text: $experimentKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Variable Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter variable name", text: $variableName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    // Values Display
                    Card(title: "Experiment Values", icon: "flask.fill", color: .purple) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Three buttons horizontally
                            HStack(spacing: 12) {
                                Button(action: { selectedType = selectedType == .string ? nil : .string }) {
                                    Text("String")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedType == .string ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedType == .string ? .blue : .primary)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: { selectedType = selectedType == .boolean ? nil : .boolean }) {
                                    Text("Boolean")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedType == .boolean ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedType == .boolean ? .blue : .primary)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: { selectedType = selectedType == .integer ? nil : .integer }) {
                                    Text("Integer")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedType == .integer ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedType == .integer ? .blue : .primary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Show value below when button is clicked
                            if let selectedType = selectedType {
                                VStack(alignment: .leading, spacing: 8) {
                                    Divider()
                                    
                                    switch selectedType {
                                    case .string:
                                        if let stringValue = stringValue {
                                            Text(stringValue)
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        } else {
                                            Text("No value")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    case .boolean:
                                        if let boolValue = boolValue {
                                            Text("\(boolValue)")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        } else {
                                            Text("No value")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    case .integer:
                                        if let intValue = intValue {
                                            Text("\(intValue)")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        } else {
                                            Text("No value")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: loadValues) {
                            Label("Load Values", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: fetchExperiments) {
                            Label("Fetch from API", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Status
                    Text(fetchStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Experiments")
            .onAppear {
                loadValues()
            }
        }
    }
    
    private func loadValues() {
        guard let experiments = try? Ascend.getPlugin(AscendExperiments.self) else {
            fetchStatus = "Experiments plugin not available"
            return
        }

        stringValue = experiments.getStringValue(for: experimentKey, with: variableName)
        boolValue = experiments.getBoolValue(for: experimentKey, with: variableName)
        intValue = experiments.getIntValue(for: experimentKey, with: variableName)
        
        fetchStatus = "Values loaded"
    }
    
    private func fetchExperiments() {
        guard let experiments = try? Ascend.getPlugin(AscendExperiments.self) else {
            fetchStatus = "Experiments plugin not available"
            return
        }
        
        fetchStatus = "Fetching..."
        
        experiments.fetchExperiments(for: [experimentKey: .string("default")]) { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    fetchStatus = "Error: \(error)"
                } else if let response = response {
                    fetchStatus = "Fetched \(response.data?.count ?? 0) experiments"
                    loadValues()
                } else {
                    fetchStatus = "No response"
                }
            }
        }
        
        print("experiments.fetchExperiments")
    }
}

// MARK: - User View

struct UserView: View {
    @State private var userId = ""
    @State private var guestId = ""
    @State private var newUserId = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current User Info
                    Card(title: "Current User", icon: "person.fill", color: .blue) {
                        VStack(alignment: .leading, spacing: 12) {
                            ValueRow(label: "User ID", value: userId.isEmpty ? "Not set" : userId)
                            ValueRow(label: "Guest ID", value: guestId.isEmpty ? "Not set" : guestId)
                            ValueRow(label: "Authenticated", value: Ascend.user.isAuthenticated() ? "Yes" : "No")
                        }
                    }
                    
                    // Set User
                    Card(title: "Set User", icon: "person.badge.plus", color: .green) {
                        VStack(spacing: 12) {
                            TextField("Enter User ID", text: $newUserId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: setUser) {
                                Text("Set User")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Actions
                    Button(action: setGuest) {
                        Label("Set Guest User", systemImage: "person.crop.circle.badge.questionmark")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("User Management")
            .onAppear {
                refreshUserInfo()
            }
        }
    }
    
    private func refreshUserInfo() {
        userId = Ascend.user.getUserId()
        guestId = Ascend.user.getGuestId()
    }
    
    private func setUser() {
        guard !newUserId.isEmpty else { return }
        Ascend.user.setUser(userId: newUserId)
        newUserId = ""
        refreshUserInfo()
    }
    
    private func setGuest() {
        let guestId = "guest-\(UUID().uuidString.prefix(8))"
        Ascend.user.setGuest(guestId: guestId)
        refreshUserInfo()
    }
}

// MARK: - Device View

struct DeviceView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Device Info
                    Card(title: "Device Information", icon: "iphone", color: .blue) {
                        VStack(alignment: .leading, spacing: 12) {
                            ValueRow(label: "Model", value: Ascend.deviceInfo.getDeviceModel())
                            ValueRow(label: "System", value: "\(Ascend.deviceInfo.getSystemName()) \(Ascend.deviceInfo.getSystemVersion())")
                            ValueRow(label: "App Version", value: Ascend.deviceInfo.getAppVersion())
                            ValueRow(label: "Network", value: Ascend.deviceInfo.isNetworkAvailable() ? "Available" : "Unavailable")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Device Info")
        }
    }
}

// MARK: - Helper Views

struct Card<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ValueRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    MainView()
}

