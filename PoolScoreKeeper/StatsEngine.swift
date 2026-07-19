import Foundation

struct PlayerStat {
    let name: String
    let wins: Int
    let losses: Int
    var total: Int { wins + losses }
    var winPct: Double { total > 0 ? Double(wins) / Double(total) * 100 : 0 }
}

struct H2HStat {
    let player1: String
    let player2: String
    let wins1: Int
    let wins2: Int
    var leader: String? {
        if wins1 > wins2 { return player1 }
        if wins2 > wins1 { return player2 }
        return nil
    }
}

struct BreakStat {
    let player: String
    let broke: Int
    let brokeWon: Int
    let notBroke: Int
    let notBrokeWon: Int
    var brkPct: Double { broke > 0 ? Double(brokeWon) / Double(broke) * 100 : 0 }
    var noBrkPct: Double { notBroke > 0 ? Double(notBrokeWon) / Double(notBroke) * 100 : 0 }
    var advantage: Double { brkPct - noBrkPct }
}

enum StatsEngine {

    static func playerStats(matches: [Match], players: [Player]) -> [PlayerStat] {
        var playerStatsDict: [UUID: (name: String, wins: Int, losses: Int)] = [:]
        
        // Initialize with all players
        for player in players {
            playerStatsDict[player.id] = (name: player.name, wins: 0, losses: 0)
        }
        
        // Count wins and losses
        for match in matches where match.isValid {
            guard let p1 = match.player1, let p2 = match.player2, let winner = match.winner else { continue }
            
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

    static func headToHead(matches: [Match], players: [Player]) -> [H2HStat] {
        var results: [H2HStat] = []
        let sortedPlayers = players.sorted { $0.name < $1.name }

        for i in 0..<sortedPlayers.count {
            for j in (i+1)..<sortedPlayers.count {
                let p1 = sortedPlayers[i]
                let p2 = sortedPlayers[j]

                let relevant = matches.filter { match in
                    guard match.isValid,
                          let mp1 = match.player1, let mp2 = match.player2 else { return false }
                    return (mp1.id == p1.id || mp2.id == p1.id) &&
                           (mp1.id == p2.id || mp2.id == p2.id)
                }

                let w1 = relevant.filter { $0.winner?.id == p1.id }.count
                let w2 = relevant.filter { $0.winner?.id == p2.id }.count

                if (w1 + w2) > 0 {
                    results.append(H2HStat(player1: p1.name, player2: p2.name, wins1: w1, wins2: w2))
                }
            }
        }
        return results
    }

    static func breakStats(matches: [Match], players: [Player]) -> (overall: Double, perPlayer: [BreakStat], total: Int)? {
        let tracked = matches.filter { $0.isValid && $0.breaker != nil }
        guard !tracked.isEmpty else { return nil }

        let overallPct = Double(tracked.filter { $0.winner?.id == $0.breaker?.id }.count) / Double(tracked.count) * 100

        let perPlayer: [BreakStat] = players.compactMap { player in
            let broke = tracked.filter { $0.breaker?.id == player.id }
            let notBroke = tracked.filter { match in
                guard let b = match.breaker else { return false }
                return b.id != player.id && 
                       (match.player1?.id == player.id || match.player2?.id == player.id)
            }
            guard (broke.count + notBroke.count) > 0 else { return nil }
            return BreakStat(
                player: player.name,
                broke: broke.count,
                brokeWon: broke.filter { $0.winner?.id == player.id }.count,
                notBroke: notBroke.count,
                notBrokeWon: notBroke.filter { $0.winner?.id == player.id }.count
            )
        }.sorted { $0.brkPct > $1.brkPct }

        return (overall: overallPct, perPlayer: perPlayer, total: tracked.count)
    }
}
