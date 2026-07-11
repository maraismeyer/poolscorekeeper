import SwiftData
import Foundation

@Model
class Match {
    var id: UUID = UUID()
    var date: Date = Date()
    var player1: String = ""
    var player2: String = ""
    var winner: String = ""
    var breaker: String = ""
    var timestamp: Date = Date()
    
    init(player1: String, player2: String, winner: String, breaker: String) {
        self.id = UUID()
        self.date = Date()
        self.player1 = player1
        self.player2 = player2
        self.winner = winner
        self.breaker = breaker
        self.timestamp = Date()
    }
}
