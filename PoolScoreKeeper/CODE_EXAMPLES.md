# Code Examples - Before & After

This document shows the key code changes for reference.

---

## 1. SwiftData Relationships

### Before (String-based):
```swift
@Model
class Match {
    var player1: String = ""
    var player2: String = ""
    var winner: String = ""
    var breaker: String = ""
}
```

### After (Relationship-based):
```swift
@Model
class Match {
    var player1: Player?
    var player2: Player?
    var winner: Player?
    var breaker: Player?
    
    var participants: [Player] {
        [player1, player2].compactMap { $0 }
    }
    
    var isValid: Bool {
        guard let p1 = player1, let p2 = player2, let w = winner else {
            return false
        }
        return (w.id == p1.id || w.id == p2.id) && p1.id != p2.id
    }
}
```

---

## 2. Liquid Glass Design

### Before (Standard background):
```swift
struct StatChip: View {
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
            Text(label)
        }
        .padding()
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### After (Liquid Glass):
```swift
struct StatChip: View {
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
            Text(label)
        }
        .padding()
        .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), 
                     in: .rect(cornerRadius: 12))
    }
}
```

### Button Style - Before:
```swift
struct ToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(isActive ? Color.green : Color(.systemFill))
            .clipShape(Capsule())
    }
}
```

### Button Style - After:
```swift
struct ToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .glassEffect(
                isActive ? .regular.tint(.green.opacity(0.4)).interactive() 
                         : .regular.interactive(),
                in: .capsule
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
```

### Container - After:
```swift
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 12) {
        StatChip(number: "\(players.count)", label: "Players")
        StatChip(number: "\(matches.count)", label: "Matches")
        StatChip(number: "\(sessions)", label: "Sessions")
        StatChip(number: "\(breaks)", label: "Breaks")
    }
}
```

---

## 3. Swift Concurrency

### Before (DispatchQueue):
```swift
func showToast(_ message: String, isError: Bool = false) {
    withAnimation {
        toastMessage = message
        toastIsError = isError
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
        withAnimation { 
            toastMessage = nil 
        }
    }
}

// Usage
showToast("Match recorded!")
```

### After (Async/Await):
```swift
func showToast(_ message: String, isError: Bool = false) async {
    withAnimation {
        toastMessage = message
        toastIsError = isError
    }
    try? await Task.sleep(for: .seconds(3.5))
    withAnimation { 
        toastMessage = nil 
    }
}

// Usage
Task {
    await showToast("Match recorded!")
}
```

---

## 4. Haptic Feedback

### Adding a Player:
```swift
func addPlayer() {
    let name = newPlayerName.trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty else { return }
    
    context.insert(Player(name: name))
    
    #if os(iOS)
    // Haptic feedback
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
    #endif
    
    Task {
        await showToast("✓ \(name) added")
    }
}
```

### Recording a Match:
```swift
func recordMatch() {
    // ... validation ...
    
    context.insert(match)
    
    #if os(iOS)
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
    #endif
    
    Task {
        await showToast("✓ \(p1.name) vs \(p2.name) → \(winner.name) wins!")
    }
}
```

### Deleting a Match:
```swift
func deleteMatch(_ match: Match) {
    #if os(iOS)
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
    #endif
    
    withAnimation {
        context.delete(match)
    }
}
```

### Toggling Player Selection:
```swift
func togglePlayer(_ id: UUID) {
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    #endif
    
    if activePlayers.contains(id) {
        activePlayers.remove(id)
    } else {
        activePlayers.insert(id)
    }
}
```

---

## 5. Data Export

### Export Function:
```swift
@State private var showShareSheet = false
@State private var exportedData: URL?

func exportData() {
    // Create CSV content
    var csvContent = "Date,Player 1,Player 2,Winner,Breaker\n"
    for match in matches.sorted(by: { $0.date > $1.date }) {
        let dateString = match.date.formatted(.iso8601)
        let p1Name = match.player1?.name ?? "Unknown"
        let p2Name = match.player2?.name ?? "Unknown"
        let winnerName = match.winner?.name ?? "Unknown"
        let breakerName = match.breaker?.name ?? "None"
        csvContent += "\(dateString),\(p1Name),\(p2Name),\(winnerName),\(breakerName)\n"
    }
    
    // Save to temporary file
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("pool_stats_\(Date().timeIntervalSince1970).csv")
    
    do {
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        exportedData = tempURL
        showShareSheet = true
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    } catch {
        print("Export failed: \(error)")
    }
}
```

### Share Sheet Integration:
```swift
// In view
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            exportData()
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(matches.isEmpty)
    }
}
.sheet(isPresented: $showShareSheet) {
    if let url = exportedData {
        #if os(iOS)
        ShareSheet(activityItems: [url])
        #endif
    }
}

// ShareSheet component
#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
```

---

## 6. Data Validation

### Match Validation:
```swift
@Model
class Match {
    // ... properties ...
    
    var isValid: Bool {
        guard let p1 = player1, let p2 = player2, let w = winner else {
            return false
        }
        
        // Winner must be one of the players
        let winnerValid = (w.id == p1.id || w.id == p2.id)
        
        // Players must be different
        let playersValid = p1.id != p2.id
        
        // Breaker must be one of the players (if set)
        let breakerValid = breaker == nil || 
                          breaker?.id == p1.id || 
                          breaker?.id == p2.id
        
        return winnerValid && playersValid && breakerValid
    }
}
```

### Using Validation:
```swift
func recordMatch() {
    // ... get players ...
    
    let match = Match(player1: p1, player2: p2, winner: winner, breaker: breaker)
    
    guard match.isValid else {
        Task {
            await showToast("Invalid match data", isError: true)
        }
        return
    }
    
    context.insert(match)
    // ... success feedback ...
}
```

### Filtering in Stats:
```swift
static func playerStats(matches: [Match], players: [Player]) -> [PlayerStat] {
    // ... code ...
    
    for match in matches where match.isValid {
        // Only process valid matches
    }
}
```

### Duplicate Player Check:
```swift
func addPlayer() {
    let name = newPlayerName.trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty else { return }
    
    guard !players.map(\.name).contains(name) else { 
        Task {
            await showToast("Player '\(name)' already exists", isError: true)
        }
        return 
    }
    
    context.insert(Player(name: name))
    // ... success feedback ...
}
```

---

## 7. Player Selection (UUID-based)

### Before (String-based):
```swift
@State private var activePlayers: Set<String> = []
@State private var selectedP1: String? = nil

// Toggle
func togglePlayer(_ name: String) {
    if activePlayers.contains(name) {
        activePlayers.remove(name)
    } else {
        activePlayers.insert(name)
    }
}
```

### After (UUID-based):
```swift
@State private var activePlayers: Set<UUID> = []
@State private var selectedP1: UUID? = nil

var activatedPlayers: [Player] {
    players.filter { activePlayers.contains($0.id) }
}

// Toggle
func togglePlayer(_ id: UUID) {
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    #endif
    
    if activePlayers.contains(id) {
        activePlayers.remove(id)
    } else {
        activePlayers.insert(id)
    }
}
```

---

## 8. Stats Engine Updates

### Before (String-based):
```swift
static func playerStats(matches: [Match], players: [String]) -> [PlayerStat] {
    var allNames = Set<String>()
    for m in matches {
        allNames.insert(m.player1)
        allNames.insert(m.player2)
    }
    let names = allNames.sorted()
    return names.compactMap { name in
        let wins = matches.filter { $0.winner == name }.count
        // ...
    }
}
```

### After (Player objects):
```swift
static func playerStats(matches: [Match], players: [Player]) -> [PlayerStat] {
    var playerStatsDict: [UUID: (name: String, wins: Int, losses: Int)] = [:]
    
    // Initialize with all players
    for player in players {
        playerStatsDict[player.id] = (name: player.name, wins: 0, losses: 0)
    }
    
    // Count wins and losses
    for match in matches where match.isValid {
        guard let p1 = match.player1, let p2 = match.player2, 
              let winner = match.winner else { continue }
        
        if winner.id == p1.id {
            playerStatsDict[p1.id]?.wins += 1
            playerStatsDict[p2.id]?.losses += 1
        } else if winner.id == p2.id {
            playerStatsDict[p2.id]?.wins += 1
            playerStatsDict[p1.id]?.losses += 1
        }
    }
    
    return playerStatsDict.values
        .filter { $0.wins + $0.losses > 0 }
        .map { PlayerStat(name: $0.name, wins: $0.wins, losses: $0.losses) }
        .sorted { $0.wins > $1.wins }
}
```

---

## 9. UI Improvements

### Toast with Animation:
```swift
if let message = toastMessage {
    Text(message)
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(toastIsError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        .foregroundStyle(toastIsError ? .red : .green)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.scale.combined(with: .opacity))  // ← New!
}
```

### Button with Opacity:
```swift
Button("Record Match") {
    recordMatch()
}
.buttonStyle(.glass)
.frame(maxWidth: .infinity)
.padding(.vertical, 12)
.fontWeight(.bold)
.disabled(!canRecord)
.opacity(canRecord ? 1.0 : 0.5)  // ← New!
```

---

## Summary

All improvements maintain backward compatibility where possible and use modern Swift patterns:

- ✅ Type-safe relationships
- ✅ Modern UI with Liquid Glass
- ✅ Async/await for cleaner code
- ✅ Platform-appropriate feedback
- ✅ Data portability
- ✅ Robust validation

These examples can serve as reference for future enhancements!
