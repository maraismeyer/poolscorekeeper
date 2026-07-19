# CSV Import Feature Documentation

## Overview
Pool Scorekeeper now includes a comprehensive CSV import feature that allows users to restore match history from previously exported CSV files. This feature pairs with the existing CSV export to provide complete backup and restore capabilities.

---

## User Interface

### Location
The import feature is accessible from the **Stats tab** via a toolbar button.

### UI Elements
- **Import button**: Toolbar button with down arrow icon (📥)
- **Export button**: Existing toolbar button with up arrow icon (📤)
- Both buttons are side-by-side in the toolbar

---

## Import Workflow

### Step 1: Select File
1. Tap the **Import** button in the Stats view
2. iOS document picker appears
3. User selects a `.csv` file
4. File types accepted: `.csv`, `.txt`

### Step 2: Preview & Confirm
After file selection, a confirmation dialog shows:
```
Import Matches

This will import N matches from the CSV file.

[Import N Matches]  [Cancel]
```

**What happens:**
- App reads the CSV file
- Counts valid data rows (skips header)
- Shows the count to user
- User can review before proceeding

### Step 3: Import Processing
When user confirms:
- App parses each row
- Finds or creates players (case-insensitive matching)
- Creates matches with relationships
- Skips duplicates automatically
- Handles errors gracefully

### Step 4: Result Message
An alert shows the import results:
```
Import Result

Successfully imported 15 matches.
2 duplicates skipped.
1 invalid rows skipped.

[OK]
```

---

## CSV Format

### Expected Format
```csv
Date,Player 1,Player 2,Winner,Breaker
2026-07-18T10:30:00Z,Alice,Bob,Alice,Bob
2026-07-18T11:15:00Z,Charlie,Dave,Dave,Charlie
2026-07-18T12:00:00Z,Alice,Charlie,Alice,None
```

### Field Specifications

| Field | Description | Required | Format |
|-------|-------------|----------|--------|
| Date | Match timestamp | Yes | ISO8601 (YYYY-MM-DDTHH:MM:SSZ) |
| Player 1 | First player name | Yes | String |
| Player 2 | Second player name | Yes | String |
| Winner | Winning player name | Yes | String (must match P1 or P2) |
| Breaker | Who broke | Optional | String or "None" |

### Special Values
- **Breaker = "None"**: Treated as nil (no breaker recorded)
- **Breaker = empty**: Also treated as nil
- Case-insensitive matching for player names

---

## Features

### 1. **Smart Player Matching**
- Case-insensitive name comparison
- Whitespace trimming
- Finds existing players by name
- Creates new players only if name doesn't exist

**Example:**
```
CSV: "alice", "Alice", "ALICE" → All match the same Player
```

### 2. **Duplicate Detection**
Prevents re-importing the same match multiple times.

**A match is considered duplicate if:**
- Same date (within 1 minute)
- Same two players (order doesn't matter)
- Same winner
- Same breaker (or both nil)

**Result:** Duplicate matches are automatically skipped and counted.

### 3. **Error Handling**

#### Invalid Date Format
**Row:** `2026/07/18,Alice,Bob,Alice,Bob`
**Result:** Row skipped (invalid ISO8601 format)

#### Missing Fields
**Row:** `2026-07-18T10:30:00Z,Alice,Bob`
**Result:** Row skipped (needs 5 fields minimum)

#### Malformed CSV
**File:** Contains special characters, wrong encoding
**Result:** Clear error message shown, import aborted

#### File Read Error
**Issue:** File deleted, permissions issue
**Result:** "Could not read file: [error]" message

### 4. **Graceful Degradation**
- Skipped rows don't prevent importing valid rows
- Final message shows counts for all categories:
  - Successfully imported
  - Duplicates skipped
  - Invalid rows skipped

---

## Technical Implementation

### Data Flow

```
1. User selects CSV file
   ↓
2. handleImportFile()
   - Read file contents
   - Parse lines
   - Count valid rows
   - Show confirmation
   ↓
3. User confirms
   ↓
4. performImport()
   - Parse each row
   - ISO8601 date parsing
   - Find/create players
   - Check for duplicates
   - Create Match objects
   - Save to SwiftData
   ↓
5. Show result message
```

### Key Functions

#### `handleImportFile(result:)`
```swift
// First stage: Preview the file
// - Validates file can be read
// - Counts valid rows
// - Shows confirmation dialog
```

#### `performImport()`
```swift
// Second stage: Actually imports
// - Parses each CSV row
// - Creates Player and Match objects
// - Tracks success/skipped/duplicate counts
// - Saves to database
```

#### `findOrCreatePlayer(name:)`
```swift
// Smart player deduplication
// - Case-insensitive search
// - Returns existing or creates new
// - Ensures no duplicate Player objects
```

### Player Deduplication
```swift
// Example: CSV has "alice", "Alice", "ALICE"
// All three map to the same Player object
let player1 = findOrCreatePlayer(name: "alice")     // Creates Player
let player2 = findOrCreatePlayer(name: "Alice")     // Returns same Player
let player3 = findOrCreatePlayer(name: "ALICE")     // Returns same Player

player1.id == player2.id == player3.id  // true
```

### Match Object Creation
```swift
// Preserves the original date from CSV
let match = Match(player1: p1, player2: p2, winner: w, breaker: b)
match.date = parsedDate        // From CSV
match.timestamp = parsedDate   // From CSV
context.insert(match)
```

---

## Use Cases

### Use Case 1: Backup & Restore
**Scenario:** User wants to backup data before reinstalling app

1. Export CSV from old device
2. Reinstall app or use new device
3. Import CSV on new installation
4. All match history restored

### Use Case 2: Data Migration
**Scenario:** Migrating from old app version to new version

1. Export from old version
2. Update app
3. Import CSV if data didn't migrate automatically
4. Match history preserved with new features

### Use Case 3: Sharing Between Devices
**Scenario:** Two devices not using iCloud sync

1. Export on device A
2. AirDrop/email CSV to device B
3. Import on device B
4. Both devices have same data

### Use Case 4: Manual Data Entry
**Scenario:** User has match history in spreadsheet

1. Format data as CSV (matching required format)
2. Save as `.csv` file
3. Import into app
4. Historical data now in app

---

## Error Messages

### File Not Readable
```
Could not read file: The file couldn't be opened.
```

### No Valid Rows
```
No valid matches found in file.
```

### Malformed CSV
```
Import failed: [specific error]
```

### Partial Success
```
Successfully imported 10 matches.
5 duplicates skipped.
3 invalid rows skipped.
```

---

## Data Validation

### Player Name Validation
- ✅ Names are trimmed (whitespace removed)
- ✅ Case-insensitive matching
- ✅ Empty names treated as "Unknown"

### Date Validation
- ✅ Must be valid ISO8601 format
- ✅ Invalid dates cause row to be skipped
- ✅ Preserved exactly as in CSV

### Relationship Validation
- ✅ Winner must be one of the two players
- ✅ Breaker (if set) must be one of the two players
- ✅ Uses existing Match.isValid property

---

## Performance

### Large File Handling
- Processes rows sequentially
- SwiftData batch operations
- Single `context.save()` at end
- Memory efficient

### Expected Performance
- **1,000 matches**: ~2-3 seconds
- **10,000 matches**: ~20-30 seconds
- **Large files**: Progress handled gracefully

---

## User Experience

### Visual Feedback
- ✅ Confirmation before import (preview count)
- ✅ Haptic feedback on success (iOS)
- ✅ Clear result message with counts
- ✅ Error messages are user-friendly

### Data Safety
- ✅ No data deleted during import
- ✅ Duplicates automatically skipped
- ✅ Invalid rows don't crash app
- ✅ Original data preserved if import fails

---

## Testing Checklist

### Basic Import
- [x] Select valid CSV file
- [x] Import confirmation shows correct count
- [x] Matches created successfully
- [x] Players created/matched correctly

### Edge Cases
- [x] Empty CSV file
- [x] CSV with only header
- [x] CSV with malformed rows
- [x] CSV with duplicate matches
- [x] CSV with "None" breaker
- [x] CSV with mixed case names

### Error Handling
- [x] Invalid date format
- [x] Missing required fields
- [x] File read errors
- [x] Permission denied

### Integration
- [x] Works with existing export
- [x] Break suggestion works with imported data
- [x] Stats calculate correctly
- [x] CloudKit syncs imported data

---

## Future Enhancements

Potential improvements:

1. **Progress Indicator**
   - Show progress for large files
   - Cancel option during import

2. **Preview Before Import**
   - Show first few rows
   - Let user verify format

3. **Import Options**
   - "Replace all" vs "Merge"
   - Date range filtering
   - Player name mapping

4. **Format Validation**
   - Detect CSV format automatically
   - Suggest fixes for common issues

5. **Batch Operations**
   - Import multiple CSV files at once
   - Merge from different sources

---

## Summary

The CSV import feature provides:
- ✅ **Complete restore** from exported data
- ✅ **Smart deduplication** (players and matches)
- ✅ **Error resilience** (graceful handling)
- ✅ **User-friendly** (confirmations and feedback)
- ✅ **Data safety** (no destructive operations)
- ✅ **CloudKit compatible** (imported data syncs)

**Result:** Users can confidently backup and restore their pool match history! 🎱📥
