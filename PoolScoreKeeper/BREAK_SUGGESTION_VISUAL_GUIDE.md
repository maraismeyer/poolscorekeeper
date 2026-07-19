# Break Suggestion - Visual Guide

## 🎯 What You'll See

This guide shows exactly what the break suggestion feature looks like in the app.

---

## Scenario: Alice vs Bob

### Initial State
```
┌─────────────────────────────────────┐
│  STEP 3 - WHO BROKE?                │
├─────────────────────────────────────┤
│  ┌──────────┐   ┌──────────┐       │
│  │  Alice   │   │   Bob    │       │
│  └──────────┘   └──────────┘       │
│  (standard    │   (standard)        │
│   glass)      │                     │
└─────────────────────────────────────┘
```
**Status**: First match between Alice and Bob
**Suggestion**: None (no history)

---

### After Recording First Match
**Match recorded**: Alice vs Bob → Alice broke → Bob won

---

### Second Match - With Suggestion!

```
┌─────────────────────────────────────┐
│  STEP 3 - WHO BROKE?                │
├─────────────────────────────────────┤
│  ╔═══════════════════════════════╗  │
│  ║  💡 Suggestion: Bob should    ║  │
│  ║     break                     ║  │
│  ║  (broke last time: Alice)     ║  │
│  ╚═══════════════════════════════╝  │
│  Yellow background                  │
│                                     │
│  ┌──────────┐   ╔══════════════╗   │
│  │  Alice   │   ║ Bob 💡       ║   │
│  └──────────┘   ╚══════════════╝   │
│  (standard)     (SUGGESTED!)        │
│                 • Yellow tint       │
│                 • Pulsing border    │
│                 • Lightbulb icon    │
└─────────────────────────────────────┘
```

---

## Button States Explained

### 1. Normal Button (Alice)
```
┌─────────────┐
│   Alice     │
└─────────────┘
```
- Standard Liquid Glass effect
- No special highlighting
- Can still be tapped

### 2. Suggested Button (Bob)
```
╔═════════════╗  ← Pulsing yellow border
║  Bob 💡     ║  ← Lightbulb icon
╚═════════════╝
```
- Yellow glass tint (0.3 opacity)
- Animated pulsing border
- Lightbulb icon next to name
- Still interactive

### 3. Selected Button (when you tap Bob)
```
┌─────────────┐
│ ✓ Bob       │  ← Changes to checkmark
└─────────────┘
```
- Green glass tint (0.4 opacity)
- Suggestion styling removed
- Standard active state

---

## Full Recording Flow with Suggestions

### Match 1: Setting the Stage
```
STEP 1: Player 1
→ Select: Alice

STEP 2: Player 2
→ Select: Bob

STEP 3: Who Broke?
┌──────────┐  ┌──────────┐
│  Alice   │  │   Bob    │
└──────────┘  └──────────┘
(No suggestion - first match)
→ User selects: Alice

STEP 4: Winner
→ Select: Bob

✅ Match recorded: Alice broke, Bob won
```

### Match 2: Suggestion Appears!
```
STEP 1: Player 1
→ Select: Alice

STEP 2: Player 2  
→ Select: Bob

STEP 3: Who Broke?
╔═══════════════════════════════╗
║  💡 Suggestion: Bob should    ║
║     break                     ║
║  (broke last time: Alice)     ║
╚═══════════════════════════════╝

┌──────────┐  ╔══════════════╗
│  Alice   │  ║ Bob 💡       ║ ← SUGGESTED!
└──────────┘  ╚══════════════╝
→ User follows suggestion: Bob

STEP 4: Winner
→ Select: Alice

✅ Match recorded: Bob broke, Alice won
```

### Match 3: Alternates Again
```
STEP 3: Who Broke?
╔═══════════════════════════════╗
║  💡 Suggestion: Alice should  ║
║     break                     ║
║  (broke last time: Bob)       ║
╚═══════════════════════════════╝

╔══════════════╗  ┌──────────┐
║ Alice 💡     ║  │   Bob    │ 
╚══════════════╝  └──────────┘
← NOW Alice is suggested!
```

---

## Animation Details

### Pulsing Border
```
Time: 0.0s  ╔═════════╗  (opacity: 0.6)
      0.75s ╔─────────╗  (opacity: 0.3)
      1.5s  ╔═════════╗  (opacity: 0.6)
      
Repeats forever while suggested & not selected
```

### Color Transitions
```
Normal → Suggested:
  Gray → Yellow (0.2s ease)

Suggested → Selected:
  Yellow → Green (0.1s ease)
  
Selected → Normal:
  Green → Gray (0.2s ease)
```

---

## Real Code Output

When you tap through the UI, here's what you'll see:

### Console Output (Debug)
```
🎱 Selected Player 1: Alice
🎱 Selected Player 2: Bob
🔍 Checking match history...
📊 Found 1 previous match
⚡ Last match: Alice broke
💡 Suggesting: Bob
```

### Toast Messages
```
After Match 1:
╔════════════════════════════╗
║ ✓ Alice vs Bob → Bob wins! ║
╚════════════════════════════╝
(Green background)

After Match 2:
╔════════════════════════════════╗
║ ✓ Alice vs Bob → Alice wins!  ║
╚════════════════════════════════╝
```

---

## Different Scenarios

### Scenario A: Override Suggestion
```
Suggestion: Bob 💡
User taps: Alice (override)
Result: Alice breaks (no problem!)
```
The suggestion is just a suggestion, not a requirement.

### Scenario B: New Opponents
```
Players: Charlie vs Dave
Previous matches: None
Suggestion: (none shown)
Buttons: Both standard
```

### Scenario C: One-Sided History
```
Match 1: Alice vs Charlie → Alice broke
Match 2: Alice vs Charlie → Suggests Charlie 💡
Match 3: Alice vs Charlie → Suggests Alice 💡
Match 4: Alice vs Charlie → Suggests Charlie 💡
```
Keeps alternating perfectly!

---

## Mobile View (Horizontal Scroll)

On smaller screens, the buttons scroll horizontally:

```
┌─────────────────────────────────────┐
│  STEP 3 - WHO BROKE?                │
├─────────────────────────────────────┤
│  💡 Suggestion: Bob should break    │
│                                     │
│  ← [Alice] [Bob 💡] →               │
│      ↑ Scroll horizontally          │
└─────────────────────────────────────┘
```

The suggestion banner stays fixed while buttons scroll.

---

## Accessibility Considerations

### VoiceOver Support
```
Button: "Alice"
Label: "Alice, breaker selection button"

Button: "Bob 💡"
Label: "Bob, breaker selection button, suggested"
Hint: "This player is suggested to break based on previous match"
```

### Dynamic Type
Text scales appropriately:
- Large text: Banner wraps to multiple lines
- Extra large: Buttons stack vertically

---

## Color Palette

### Suggestion Colors
- **Banner Background**: `Color.yellow.opacity(0.1)`
- **Banner Text**: `.secondary`
- **Lightbulb**: `.yellow`
- **Button Tint**: `Color.yellow.opacity(0.3)`
- **Border**: `Color.yellow.opacity(0.6)`

### Other States
- **Active**: `Color.green.opacity(0.4)`
- **Normal**: `.clear` (glass only)
- **Error**: `Color.red.opacity(0.1)`

---

## Summary

The break suggestion feature is designed to be:

1. **🎯 Noticeable**: Multiple visual indicators
2. **📖 Clear**: Explains who broke last time
3. **✨ Polished**: Smooth animations
4. **🎨 Beautiful**: Liquid Glass integration
5. **♿ Accessible**: VoiceOver support
6. **📱 Responsive**: Works on all screen sizes
7. **🎮 Fair**: Promotes equal breaking chances

---

## Tips for Users

💡 **Pro Tip 1**: The suggestion remembers forever - even if you play other opponents in between!

💡 **Pro Tip 2**: You can always override the suggestion if you have a house rule or agreement.

💡 **Pro Tip 3**: The pulsing border helps you spot the suggestion quickly, especially in a dark room!

💡 **Pro Tip 4**: If you don't see a suggestion, it means it's your first match with that opponent.

---

**Enjoy fair and balanced pool games! 🎱✨**
