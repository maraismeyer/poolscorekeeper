# Break Suggestion Feature Documentation

## Overview
The Pool Scorekeeper app now includes an intelligent break suggestion system that promotes fairness by recommending who should break based on the history between the two selected players.

---

## How It Works

### Logic
When you select Player 1 and Player 2 for a new match, the app:

1. **Searches match history** for the most recent game between these two players
2. **Identifies who broke** in that previous match
3. **Suggests the other player** to break this time

### Example
- **Last match**: Alice vs Bob → Alice broke
- **New match**: Alice vs Bob → **Suggestion: Bob should break**

This ensures fair alternation of breaking between players.

---

## Visual Indicators

### 1. Suggestion Banner
When players 1 and 2 are selected, you'll see a yellow suggestion banner:

```
💡 Suggestion: Bob should break (broke last time: Alice)
```

**Features:**
- 💡 Yellow lightbulb icon
- Player name who should break
- Reference to who broke last time
- Yellow background highlight

### 2. Button Highlighting
The suggested player's button has special visual treatment:

- **Yellow tint** in the glass effect
- **Pulsing yellow border** (animated)
- **Lightbulb icon** next to the player name

### 3. Button States
- **Suggested (not selected)**: Yellow tint + pulsing border + lightbulb
- **Selected**: Green tint (overrides suggestion styling)
- **Normal**: Standard glass effect

---

## Implementation Details

### Computed Property: `suggestedBreaker`
```swift
var suggestedBreaker: UUID? {
    guard let p1ID = selectedP1, let p2ID = selectedP2,
          let player1 = players.first(where: { $0.id == p1ID }),
          let player2 = players.first(where: { $0.id == p2ID }) else {
        return nil
    }
    
    // Find most recent match between these two players
    let previousMatches = matches
        .filter { match in
            guard let mp1 = match.player1, let mp2 = match.player2 else { return false }
            return (mp1.id == player1.id && mp2.id == player2.id) ||
                   (mp1.id == player2.id && mp2.id == player1.id)
        }
        .sorted { $0.date > $1.date }
    
    guard let lastMatch = previousMatches.first,
          let lastBreaker = lastMatch.breaker else {
        return nil
    }
    
    // Suggest the player who DIDN'T break last time
    if lastBreaker.id == player1.id {
        return player2.id
    } else if lastBreaker.id == player2.id {
        return player1.id
    }
    
    return nil
}
```

### Key Features
- ✅ Returns `nil` if no previous match exists
- ✅ Handles matches regardless of player order
- ✅ Uses most recent match (sorted by date)
- ✅ Safe unwrapping for optional breaker

---

## UI Components

### New Component: `SuggestedToggleButtonStyle`

```swift
struct SuggestedToggleButtonStyle: ButtonStyle {
    let isActive: Bool
    let isSuggested: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? .white : .primary)
            .glassEffect(
                isActive ? .regular.tint(.green.opacity(0.4)).interactive() : 
                isSuggested ? .regular.tint(.yellow.opacity(0.3)).interactive() :
                .regular.interactive(),
                in: .capsule
            )
            .overlay {
                if isSuggested && !isActive {
                    Capsule()
                        .strokeBorder(Color.yellow.opacity(0.6), lineWidth: 2)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true), 
                            value: isSuggested
                        )
                }
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

**Features:**
- Liquid Glass integration
- Three states: active (green), suggested (yellow), normal
- Animated pulsing border for suggestions
- Smooth press animations

---

## User Experience

### When Suggestion Appears
- ✅ Both Player 1 and Player 2 are selected
- ✅ Previous match exists between these players
- ✅ Previous match had a recorded breaker

### When No Suggestion
- ⚪ First time these players face each other
- ⚪ Previous match didn't record who broke
- ⚪ Players not yet selected

### Override Suggestion
Users can **always** choose either player to break. The suggestion is just that—a suggestion! It doesn't force or restrict choice.

---

## Edge Cases Handled

### 1. No Previous Matches
If Alice and Bob have never played before:
- No suggestion appears
- Both buttons have standard styling
- User can choose freely

### 2. Previous Match Without Breaker
If the last match between Alice and Bob didn't record who broke:
- No suggestion appears
- Both buttons have standard styling

### 3. Multiple Previous Matches
The app uses the **most recent** match to make the suggestion.

### 4. Player Order Doesn't Matter
Whether you select:
- Alice as P1, Bob as P2, OR
- Bob as P1, Alice as P2

The system correctly finds their match history and makes the same suggestion.

---

## Benefits

### ✅ Promotes Fairness
Ensures players alternate breaking, preventing one player from always having the advantage (or disadvantage) of the break.

###  ✅ No Manual Tracking
Players don't need to remember who broke last time—the app remembers for them!

### ✅ Still Flexible
The suggestion doesn't prevent users from choosing differently if they have a specific reason.

### ✅ Clear Visual Feedback
Multiple visual indicators make the suggestion impossible to miss.

### ✅ Smooth UX
Animations and glass effects make the feature feel polished and professional.

---

## Technical Highlights

### Performance
- **Efficient filtering**: Uses SwiftData @Query for fast access
- **Sorted once**: Matches sorted by date only when needed
- **Computed property**: Recalculates automatically when selections change

### Data Integrity
- **Safe unwrapping**: All optionals handled properly
- **UUID comparison**: Type-safe player identification
- **Relationship-based**: Uses SwiftData relationships for accuracy

### Visual Polish
- **Liquid Glass**: Modern Apple design language
- **Smooth animations**: 1.5s pulsing effect on suggestion
- **Color coding**: Yellow = suggestion, Green = selected
- **Icons**: Lightbulb reinforces the "suggestion" concept

---

## Future Enhancements

Potential improvements for future versions:

1. **Statistics Integration**
   - Show break win percentage for each player
   - Suggest based on who's winning more when they break

2. **Customization**
   - Allow users to disable suggestions
   - Choose strict alternation vs. smart suggestion

3. **History Display**
   - Show last 3 matches between players
   - Display who broke in each

4. **Sound/Haptics**
   - Subtle sound when suggestion appears
   - Different haptic for suggested vs. normal button

---

## Code Integration

The feature integrates seamlessly with existing code:

```swift
// In "Who Broke?" section
if let suggested = suggestedBreaker,
   let suggestedPlayer = players.first(where: { $0.id == suggested }) {
    // Show suggestion banner
    HStack(spacing: 6) {
        Image(systemName: "lightbulb.fill")
        Text("Suggestion: \(suggestedPlayer.name) should break")
        Text("(broke last time: \(p1.id == suggested ? p2.name : p1.name))")
    }
    // ... styling ...
}

// Button styling
.buttonStyle(SuggestedToggleButtonStyle(
    isActive: selectedBreaker == player.id,
    isSuggested: player.id == suggestedBreaker
))
```

---

## Summary

The break suggestion feature:
- ✅ **Enhances fairness** by tracking and suggesting alternation
- ✅ **Improves UX** with clear visual indicators
- ✅ **Maintains flexibility** - suggestions, not requirements
- ✅ **Uses modern design** with Liquid Glass and animations
- ✅ **Handles edge cases** gracefully
- ✅ **Integrates seamlessly** with existing architecture

**Result**: A more fair, user-friendly, and professional pool tracking experience! 🎱✨
