import SwiftUI
import SwiftData

@main
struct PoolScorekeeperApp: App {
    let container: ModelContainer

    init() {
        do {
            // Create schema
            let schema = Schema([Player.self, Match.self])
            
            // PRODUCTION: Enable CloudKit for iCloud sync across devices
            // Let SwiftData manage the store URL for CloudKit compatibility
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic  // ← CloudKit enabled
            )
            
            container = try ModelContainer(for: schema, configurations: config)
            print("✅ SwiftData container created with CloudKit sync")
        } catch {
            // Fallback: If CloudKit fails, use local storage only
            print("⚠️ CloudKit unavailable, falling back to local storage: \(error)")
            do {
                let schema = Schema([Player.self, Match.self])
                let config = ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .none
                )
                container = try ModelContainer(for: schema, configurations: config)
                print("✅ SwiftData container created (local storage)")
            } catch {
                fatalError("Failed to create container: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
