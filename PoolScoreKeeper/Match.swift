import SwiftData
import Foundation

@Model
class Match {
    var id: UUID = UUID()
    var date: Date = Date()
    var timestamp: Date = Date()
    
    // Simple relationships (no inverses for simplicity)
    var player1: Player?
    var player2: Player?
    var winner: Player?
    var breaker: Player?
    
    // Computed property for validation
    var isValid: Bool {
        guard let p1 = player1, let p2 = player2, let w = winner else {
            return false
        }
        let winnerValid = (w.id == p1.id || w.id == p2.id)
        let playersValid = p1.id != p2.id
        let breakerValid = breaker == nil || breaker?.id == p1.id || breaker?.id == p2.id
        
        return winnerValid && playersValid && breakerValid
    }
    
    init(player1: Player, player2: Player, winner: Player, breaker: Player?) {
        self.id = UUID()
        self.date = Date()
        self.timestamp = Date()
        self.player1 = player1
        self.player2 = player2
        self.winner = winner
        self.breaker = breaker
    }
}
