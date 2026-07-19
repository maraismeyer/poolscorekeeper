# Migration Guide for Existing Data

## ⚠️ Important: Breaking Changes

The update from string-based to relationship-based data models is a **breaking change**. If you have existing data in your app, you'll need to handle migration.

---

## Option 1: Fresh Start (Recommended for Testing)

If you don't have important production data:

1. Delete the app from your device/simulator
2. Clean build folder (Cmd+Shift+K)
3. Build and run
4. SwiftData will create the new schema automatically

---

## Option 2: Data Migration (For Production Data)

If you need to preserve existing data, you'll need to create a migration strategy.

### Step 1: Create Migration Plan

SwiftData doesn't automatically migrate from String to Relationship types. You'll need to:

1. Export existing data to CSV (if you have the old version running)
2. Or create a custom migration

### Step 2: Custom Migration Code

Add this to your app's initialization (one-time migration):

```swift
import SwiftData

actor DataMigrator {
    let modelContainer: ModelContainer
    
    init(container: ModelContainer) {
        self.modelContainer = container
    }
    
    func migrateOldMatches() async throws {
        let context = ModelContext(modelContainer)
        
        // This is pseudocode - you'd need to adapt based on your old schema
        // Fetch all old matches with string-based players
        // For each match:
        //   1. Find or create Player objects
        //   2. Create new Match with relationships
        //   3. Delete old match
        
        try context.save()
    }
}
```

---

## Option 3: Manual Data Re-entry

If you only have a small amount of data:

1. Take screenshots of your current stats
2. Note down all matches in the history
3. Delete and reinstall the app
4. Re-enter the data manually

---

## Recommended Approach for Your App

Since this appears to be a family pool tracker (likely not thousands of records), I recommend:

### For Development/Testing:
- **Option 1**: Fresh start

### For Production (if you already have users):
- Add a version check in your app
- Detect schema version
- Show a migration screen
- Export to CSV first
- Then import after migration

---

## Testing Migration

1. **Create test data** with old version
2. **Export** important stats
3. **Backup** the app data
4. **Test migration** on a copy
5. **Verify** all data migrated correctly
6. **Deploy** to production

---

## Alternative: Gradual Migration

Keep both models temporarily:

1. Add new `Match2` model with relationships
2. Create matches in both formats
3. Show "Migrate" button in settings
4. Once migrated, remove old model

---

## SwiftData Schema Versioning (Advanced)

For future-proof migrations:

```swift
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Player.self, Match.self]
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [PlayerV2.self, MatchV2.self]
    }
}

struct PoolScorekeeperVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Player.self, Match.self]
    }
}

typealias PoolScorekeeper = PoolScorekeeperVersionedSchema
```

---

## Quick Fix: Add Version to App

Add to your app:

```swift
import SwiftData

@main
struct PoolScoreKeeperApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Add migration policy
            let schema = Schema([Player.self, Match.self])
            let config = ModelConfiguration(
                schema: schema,
                // This will delete and recreate if schema changes
                // Remove for production!
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(
                for: schema,
                configurations: config
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

---

## For Your Current Situation

Since you're implementing all improvements now, I recommend:

### 🎯 Best Practice

1. **Accept data loss** for this update (if no production users)
2. **Document** the schema change in release notes
3. **Add version tracking** for future updates
4. **Implement export** first (already done!) so users can backup

The export functionality we just added will help users preserve their data as CSV before updating!

---

## Summary

- ✅ New installations: Work automatically
- ✅ Fresh starts: Delete app and reinstall  
- ⚠️ Existing data: Needs migration strategy
- 💾 Export feature: Backup safety net

For a family app in development, a fresh start is usually the cleanest approach!
