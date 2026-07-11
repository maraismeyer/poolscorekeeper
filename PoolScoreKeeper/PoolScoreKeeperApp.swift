import SwiftUI
import SwiftData

@main
struct PoolScorekeeperApp: App {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(cloudKitDatabase: .automatic)
            container = try ModelContainer(for: Player.self, Match.self,
                                           configurations: config)
        } catch {
            do {
                container = try ModelContainer(for: Player.self, Match.self)
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
