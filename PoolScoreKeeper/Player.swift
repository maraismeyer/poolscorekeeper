import SwiftData
import Foundation

@Model
class Player {
    var name: String = ""
    var addedOn: Date = Date()
    
    init(name: String) {
        self.name = name
        self.addedOn = Date()
    }
}
