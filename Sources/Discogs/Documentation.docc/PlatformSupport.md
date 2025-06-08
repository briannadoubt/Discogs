# Platform Support

Learn about platform-specific features, capabilities, and considerations when using the Discogs Swift SDK across different Apple platforms.

## Overview

The Discogs Swift SDK supports all major Apple platforms: iOS, macOS, tvOS, watchOS, and visionOS. Each platform has unique characteristics and capabilities that you should consider when building your application.

## Supported Platforms

### Minimum Requirements

```swift
// Package.swift platform requirements
platforms: [
    .macOS(.v12),     // macOS Monterey 12.0+
    .iOS(.v15),       // iOS 15.0+
    .tvOS(.v15),      // tvOS 15.0+
    .watchOS(.v8),    // watchOS 8.0+
    .visionOS(.v1),   // visionOS 1.0+
]
```

### Platform Capabilities Matrix

| Feature | iOS | macOS | tvOS | watchOS | visionOS |
|---------|-----|-------|------|---------|----------|
| Full API Access | ✅ | ✅ | ✅ | ✅ | ✅ |
| Image Loading | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| Background Sync | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |
| Local Storage | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| Network Monitoring | ✅ | ✅ | ✅ | ✅ | ✅ |
| Concurrent Requests | ✅ | ✅ | ✅ | ⚠️ | ✅ |

**Legend**: ✅ Full Support, ⚠️ Limited Support

## iOS-Specific Features

### Background App Refresh

Enable background data synchronization:

```swift
import BackgroundTasks

class BackgroundSyncManager {
    private let discogsService: DiscogsServiceProtocol
    private let localStore: LocalStorageProtocol
    
    init(discogsService: DiscogsServiceProtocol, localStore: LocalStorageProtocol) {
        self.discogsService = discogsService
        self.localStore = localStore
        
        registerBackgroundTasks()
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourapp.sync-collection",
            using: nil
        ) { task in
            self.handleCollectionSync(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.sync-collection")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background sync: \(error)")
        }
    }
    
    private func handleCollectionSync(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                await syncUserCollection()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func syncUserCollection() async {
        // Implement collection sync logic
    }
}
```

### Scene Lifecycle Integration

Handle app lifecycle events:

```swift
import SwiftUI

@main
struct DiscogsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    @StateObject private var syncManager = BackgroundSyncManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(syncManager)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                syncManager.scheduleBackgroundSync()
            case .inactive:
                appState.pauseOperations()
            case .active:
                appState.resumeOperations()
            @unknown default:
                break
            }
        }
    }
}
```

### Network-Aware Operations

Adapt to different network conditions:

```swift
import Network

class NetworkAwareDiscogsService {
    private let discogsService: DiscogsServiceProtocol
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.networkStatus = path.status == .satisfied ? .connected : .disconnected
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    func searchWithNetworkAwareness(query: String) async throws -> SearchResults {
        // Adjust behavior based on network conditions
        let perPage: Int
        
        if isConstrained || isExpensive {
            perPage = 25 // Fewer results on constrained networks
        } else {
            perPage = 50 // Normal page size
        }
        
        return try await discogsService.search(query: query, perPage: perPage)
    }
}

enum NetworkStatus {
    case connected
    case disconnected
    case unknown
}
```

## macOS-Specific Features

### Menu Bar Integration

Create menu bar applications:

```swift
import Cocoa
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
        super.init()
        
        createStatusItem()
        createPopover()
    }
    
    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Discogs")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func createPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(discogsService: discogsService)
        )
    }
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

struct MenuBarContentView: View {
    let discogsService: DiscogsServiceProtocol
    @State private var searchQuery = ""
    @State private var recentSearches: [String] = []
    
    var body: some View {
        VStack {
            TextField("Search Discogs...", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    performSearch()
                }
            
            List(recentSearches, id: \.self) { search in
                Text(search)
                    .onTapGesture {
                        searchQuery = search
                        performSearch()
                    }
            }
        }
        .padding()
    }
    
    private func performSearch() {
        // Implement search logic
        if !searchQuery.isEmpty && !recentSearches.contains(searchQuery) {
            recentSearches.insert(searchQuery, at: 0)
            if recentSearches.count > 10 {
                recentSearches.removeLast()
            }
        }
    }
}
```

### Sandboxing Considerations

Handle macOS App Store sandboxing:

```swift
import Foundation

class SandboxAwareStorageManager {
    private let containerURL: URL
    
    init() throws {
        if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            // iCloud container for App Store apps
            containerURL = url
        } else {
            // Local application support for non-sandboxed apps
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
            containerURL = appSupport.appendingPathComponent(Bundle.main.bundleIdentifier ?? "DiscogsApp")
            
            try FileManager.default.createDirectory(at: containerURL, 
                                                   withIntermediateDirectories: true)
        }
    }
    
    func save<T: Codable>(_ object: T, to filename: String) throws {
        let url = containerURL.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url)
    }
    
    func load<T: Codable>(_ type: T.Type, from filename: String) throws -> T {
        let url = containerURL.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}
```

## tvOS-Specific Considerations

### Focus Engine Integration

Design for tvOS focus system:

```swift
struct TVArtistGridView: View {
    let artists: [Artist]
    @State private var focusedArtist: Artist?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                ForEach(artists, id: \.id) { artist in
                    TVArtistCardView(artist: artist)
                        .focusable(true) { isFocused in
                            if isFocused {
                                focusedArtist = artist
                            }
                        }
                        .scaleEffect(focusedArtist?.id == artist.id ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: focusedArtist?.id)
                }
            }
            .padding()
        }
    }
}

struct TVArtistCardView: View {
    let artist: Artist
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: artist.images.first?.uri ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray)
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(artist.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 220, height: 280)
    }
}
```

### Simplified UI for Distance Viewing

Optimize for TV viewing distance:

```swift
struct TVSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Search Discogs")
                .font(.largeTitle)
                .bold()
            
            TextField("Enter artist or album name...", text: $searchText)
                .font(.title2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 800)
                .onSubmit {
                    performSearch()
                }
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                        ForEach(searchResults, id: \.id) { result in
                            TVSearchResultView(result: result)
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                Text("Use the remote to search for music")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(60) // Larger padding for TV
    }
    
    private func performSearch() {
        Task {
            do {
                let results = try await discogsService.search(query: searchText)
                await MainActor.run {
                    searchResults = results.results
                }
            } catch {
                print("Search failed: \(error)")
            }
        }
    }
}
```

## watchOS-Specific Optimizations

### Complications Support

Create watch complications:

```swift
import ClockKit
import SwiftUI

struct DiscogsComplicationView: View {
    let entry: DiscogsComplicationEntry
    
    var body: some View {
        VStack {
            Image(systemName: "music.note")
                .foregroundColor(.accentColor)
            
            Text("\(entry.newReleasesCount)")
                .font(.caption2)
                .bold()
            
            Text("New")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DiscogsComplicationEntry: TimelineEntry {
    let date: Date
    let newReleasesCount: Int
    let relevance: TimelineEntryRelevance?
}

class DiscogsComplicationDataProvider {
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
    
    func getComplicationData() async -> DiscogsComplicationEntry {
        do {
            // Fetch user's watchlist or new releases
            let newReleasesCount = try await fetchNewReleasesCount()
            
            return DiscogsComplicationEntry(
                date: Date(),
                newReleasesCount: newReleasesCount,
                relevance: TimelineEntryRelevance(score: 50)
            )
        } catch {
            return DiscogsComplicationEntry(
                date: Date(),
                newReleasesCount: 0,
                relevance: nil
            )
        }
    }
    
    private func fetchNewReleasesCount() async throws -> Int {
        // Implement logic to count new releases
        return 0
    }
}
```

### Reduced Data Usage

Optimize for limited bandwidth:

```swift
class WatchOptimizedDiscogsService {
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
    
    func searchOptimized(query: String) async throws -> [MinimalSearchResult] {
        // Request smaller page size for watch
        let results = try await discogsService.search(query: query, perPage: 10)
        
        // Return minimal data structure
        return results.results.map { result in
            MinimalSearchResult(
                id: result.id,
                title: result.title,
                type: result.type
                // Omit images and other heavy data
            )
        }
    }
    
    func getArtistSummary(id: Int) async throws -> ArtistSummary {
        let artist = try await discogsService.getArtist(id: id)
        
        return ArtistSummary(
            id: artist.id,
            name: artist.name,
            releaseCount: artist.releases?.count ?? 0
            // Minimal data for watch display
        )
    }
}

struct MinimalSearchResult: Codable {
    let id: Int
    let title: String
    let type: String
}

struct ArtistSummary: Codable {
    let id: Int
    let name: String
    let releaseCount: Int
}
```

### Watch Connectivity

Sync data with iPhone app:

```swift
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var receivedData: [String: Any] = [:]
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendSearchQuery(_ query: String) {
        guard WCSession.default.isReachable else { return }
        
        let message = ["action": "search", "query": query]
        WCSession.default.sendMessage(message) { response in
            DispatchQueue.main.async {
                self.receivedData = response
            }
        } errorHandler: { error in
            print("Watch connectivity error: \(error)")
        }
    }
    
    func requestFavorites() {
        let message = ["action": "getFavorites"]
        WCSession.default.sendMessage(message) { response in
            DispatchQueue.main.async {
                self.receivedData = response
            }
        } errorHandler: { error in
            print("Failed to get favorites: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC activation failed: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle messages from iPhone app
        DispatchQueue.main.async {
            self.receivedData = message
        }
        
        replyHandler(["status": "received"])
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif
}
```

## visionOS-Specific Features

### Spatial Computing Integration

Create immersive experiences:

```swift
import SwiftUI
import RealityKit

struct VisionDiscogsView: View {
    @State private var searchResults: [SearchResult] = []
    @State private var selectedResult: SearchResult?
    
    var body: some View {
        NavigationSplitView {
            VisionSearchSidebar(results: searchResults)
        } detail: {
            if let selected = selectedResult {
                VisionDetailView(result: selected)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "music.note",
                    description: Text("Choose a release or artist to view details")
                )
            }
        }
        .ornament(attachmentAnchor: .scene(.top)) {
            VisionSearchBar { query in
                await performSearch(query)
            }
        }
    }
    
    private func performSearch(_ query: String) async {
        // Implement search logic
    }
}

struct VisionSearchBar: View {
    let onSearch: (String) async -> Void
    @State private var searchText = ""
    
    var body: some View {
        HStack {
            TextField("Search Discogs...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await onSearch(searchText)
                    }
                }
            
            Button("Search") {
                Task {
                    await onSearch(searchText)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .glassBackgroundEffect()
    }
}

struct VisionDetailView: View {
    let result: SearchResult
    
    var body: some View {
        VStack {
            // 3D album cover or artist visualization
            RealityView { content in
                // Add 3D content here
                let entity = ModelEntity()
                content.add(entity)
            }
            .frame(height: 300)
            
            VStack(alignment: .leading) {
                Text(result.title)
                    .font(.largeTitle)
                    .bold()
                
                Text(result.type.capitalized)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
```

### Hand Tracking Integration

Support gesture-based interaction:

```swift
struct VisionGestureView: View {
    @State private var currentArtist: Artist?
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            if let artist = currentArtist {
                ArtistCardView(artist: artist)
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                handleDragEnd(value)
                            }
                    )
            }
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        // Implement gesture-based navigation
        let threshold: CGFloat = 100
        
        if value.translation.x > threshold {
            // Swipe right - next artist
            loadNextArtist()
        } else if value.translation.x < -threshold {
            // Swipe left - previous artist
            loadPreviousArtist()
        }
    }
    
    private func loadNextArtist() {
        // Implementation
    }
    
    private func loadPreviousArtist() {
        // Implementation
    }
}
```

## Cross-Platform Compatibility

### Shared Code Patterns

Create platform-agnostic components:

```swift
// MARK: - Platform-agnostic view model
class ArtistViewModel: ObservableObject {
    @Published var artist: Artist?
    @Published var isLoading = false
    @Published var error: DiscogsError?
    
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
    
    @MainActor
    func loadArtist(id: Int) async {
        isLoading = true
        error = nil
        
        do {
            artist = try await discogsService.getArtist(id: id)
        } catch let discogsError as DiscogsError {
            error = discogsError
        } catch {
            error = DiscogsError.networkError(error)
        }
        
        isLoading = false
    }
}

// MARK: - Platform-specific views
#if os(iOS) || os(visionOS)
struct ArtistView: View {
    @StateObject private var viewModel: ArtistViewModel
    let artistId: Int
    
    var body: some View {
        NavigationView {
            ArtistContentView(viewModel: viewModel)
                .navigationTitle(viewModel.artist?.name ?? "Artist")
                .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadArtist(id: artistId)
        }
    }
}
#elseif os(macOS)
struct ArtistView: View {
    @StateObject private var viewModel: ArtistViewModel
    let artistId: Int
    
    var body: some View {
        HSplitView {
            ArtistSidebarView(artist: viewModel.artist)
                .frame(minWidth: 200)
            
            ArtistContentView(viewModel: viewModel)
                .frame(minWidth: 400)
        }
        .task {
            await viewModel.loadArtist(id: artistId)
        }
    }
}
#elseif os(tvOS)
struct ArtistView: View {
    @StateObject private var viewModel: ArtistViewModel
    let artistId: Int
    
    var body: some View {
        TVArtistDetailView(viewModel: viewModel)
            .task {
                await viewModel.loadArtist(id: artistId)
            }
    }
}
#elseif os(watchOS)
struct ArtistView: View {
    @StateObject private var viewModel: ArtistViewModel
    let artistId: Int
    
    var body: some View {
        WatchArtistView(viewModel: viewModel)
            .task {
                await viewModel.loadArtist(id: artistId)
            }
    }
}
#endif

// MARK: - Shared content view
struct ArtistContentView: View {
    @ObservedObject var viewModel: ArtistViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading artist...")
            } else if let artist = viewModel.artist {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ArtistHeaderView(artist: artist)
                        ArtistBiographyView(artist: artist)
                        ArtistDiscographyView(artist: artist)
                    }
                    .padding()
                }
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    // Retry action
                }
            }
        }
    }
}
```

### Platform Detection

Handle platform-specific behavior:

```swift
enum Platform {
    case iOS
    case macOS
    case tvOS
    case watchOS
    case visionOS
    
    static var current: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(visionOS)
        return .visionOS
        #endif
    }
    
    var supportsBackgroundTasks: Bool {
        switch self {
        case .iOS, .macOS, .visionOS:
            return true
        case .tvOS, .watchOS:
            return false
        }
    }
    
    var defaultPageSize: Int {
        switch self {
        case .iOS, .macOS, .visionOS:
            return 50
        case .tvOS:
            return 25
        case .watchOS:
            return 10
        }
    }
    
    var supportsLargeImages: Bool {
        switch self {
        case .iOS, .macOS, .tvOS, .visionOS:
            return true
        case .watchOS:
            return false
        }
    }
}

class PlatformAwareDiscogsService {
    private let discogsService: DiscogsServiceProtocol
    
    init(discogsService: DiscogsServiceProtocol) {
        self.discogsService = discogsService
    }
    
    func search(query: String) async throws -> SearchResults {
        return try await discogsService.search(
            query: query,
            perPage: Platform.current.defaultPageSize
        )
    }
    
    func getOptimizedImageURL(from artist: Artist) -> String? {
        let images = artist.images
        
        switch Platform.current {
        case .watchOS:
            // Use smallest available image
            return images.min(by: { $0.width < $1.width })?.uri
        case .tvOS, .visionOS:
            // Use largest available image
            return images.max(by: { $0.width < $1.width })?.uri
        default:
            // Use medium size image
            return images.first { $0.width <= 500 }?.uri ?? images.first?.uri
        }
    }
}
```

## Performance Considerations

### Platform-Specific Optimizations

```swift
class PlatformOptimizedCacheManager {
    private let platform = Platform.current
    private var cache: NSCache<NSString, AnyObject>
    
    init() {
        cache = NSCache<NSString, AnyObject>()
        
        // Platform-specific cache configuration
        switch platform {
        case .iOS, .visionOS:
            cache.countLimit = 500
            cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        case .macOS:
            cache.countLimit = 1000
            cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        case .tvOS:
            cache.countLimit = 200
            cache.totalCostLimit = 25 * 1024 * 1024 // 25MB
        case .watchOS:
            cache.countLimit = 50
            cache.totalCostLimit = 5 * 1024 * 1024 // 5MB
        }
    }
    
    func optimizedRequestBehavior() -> RequestConfiguration {
        switch platform {
        case .watchOS:
            return RequestConfiguration(
                timeout: 10.0,
                maxConcurrentRequests: 2,
                enableImagePrefetch: false
            )
        case .tvOS:
            return RequestConfiguration(
                timeout: 15.0,
                maxConcurrentRequests: 4,
                enableImagePrefetch: true
            )
        default:
            return RequestConfiguration(
                timeout: 30.0,
                maxConcurrentRequests: 8,
                enableImagePrefetch: true
            )
        }
    }
}

struct RequestConfiguration {
    let timeout: TimeInterval
    let maxConcurrentRequests: Int
    let enableImagePrefetch: Bool
}
```

## Related Topics

- <doc:BestPractices>
- <doc:Authentication>
- <doc:ErrorHandling>
- <doc:Testing>
