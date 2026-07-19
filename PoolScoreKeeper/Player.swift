import SwiftData
import Foundation

@Model
class Player {
    var id: UUID = UUID()
    var name: String = ""
    var addedOn: Date = Date()
    
    // CloudKit requires explicit inverse relationships
    // Each Match role gets its own inverse relationship array
    @Relationship(deleteRule: .nullify, inverse: \Match.player1)
    var matchesAsPlayer1: [Match]? = []
    
    @Relationship(deleteRule: .nullify, inverse: \Match.player2)
    var matchesAsPlayer2: [Match]? = []
    
    @Relationship(deleteRule: .nullify, inverse: \Match.winner)
    var matchesAsWinner: [Match]? = []
    
    @Relationship(deleteRule: .nullify, inverse: \Match.breaker)
    var matchesAsBreaker: [Match]? = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.addedOn = Date()
    }
}
