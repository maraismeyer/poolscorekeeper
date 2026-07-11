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

    static func playerStats(matches: [Match], players: [String]) -> [PlayerStat] {
        var allNames = Set<String>()
        for m in matches {
            allNames.insert(m.player1)
            allNames.insert(m.player2)
        }
        let names = allNames.sorted()
        return names.compactMap { name in
            let wins = matches.filter { $0.winner == name }.count
            let losses = matches.filter {
                ($0.player1 == name || $0.player2 == name) && $0.winner != name
            }.count
            guard (wins + losses) > 0 else { return nil }
            return PlayerStat(name: name, wins: wins, losses: losses)
        }.sorted { $0.wins > $1.wins }
    }

    static func headToHead(matches: [Match], players: [String]) -> [H2HStat] {
        var results: [H2HStat] = []
        var allNames = Set<String>()
        for m in matches {
            allNames.insert(m.player1)
            allNames.insert(m.player2)
        }
        let sortedPlayers = allNames.sorted()

        for i in 0..<sortedPlayers.count {
            for j in (i+1)..<sortedPlayers.count {
                let p1 = sortedPlayers[i]
                let p2 = sortedPlayers[j]

                let relevant = matches.filter {
                    ($0.player1 == p1 || $0.player2 == p1) &&
                    ($0.player1 == p2 || $0.player2 == p2)
                }

                let w1 = relevant.filter { $0.winner == p1 }.count
                let w2 = relevant.filter { $0.winner == p2 }.count

                if (w1 + w2) > 0 {
                    results.append(H2HStat(player1: p1, player2: p2, wins1: w1, wins2: w2))
                }
            }
        }
        return results
    }

    static func breakStats(matches: [Match], players: [String]) -> (overall: Double, perPlayer: [BreakStat], total: Int)? {
        let tracked = matches.filter { !$0.breaker.isEmpty }
        guard !tracked.isEmpty else { return nil }

        let overallPct = Double(tracked.filter { $0.winner == $0.breaker }.count) / Double(tracked.count) * 100

        let perPlayer: [BreakStat] = players.compactMap { name in
            let broke = tracked.filter { $0.breaker == name }
            let notBroke = tracked.filter {
                $0.breaker != name && ($0.player1 == name || $0.player2 == name)
            }
            guard (broke.count + notBroke.count) > 0 else { return nil }
            return BreakStat(
                player: name,
                broke: broke.count,
                brokeWon: broke.filter { $0.winner == name }.count,
                notBroke: notBroke.count,
                notBrokeWon: notBroke.filter { $0.winner == name }.count
            )
        }.sorted { $0.brkPct > $1.brkPct }

        return (overall: overallPct, perPlayer: perPlayer, total: tracked.count)
    }
}
