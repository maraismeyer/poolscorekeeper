import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Root View
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Record", systemImage: "8.circle.fill") {
                RecordView()
            }
            Tab("Stats", systemImage: "chart.bar.fill") {
                StatsView()
            }
            Tab("History", systemImage: "clock.fill") {
                HistoryView()
            }
        }
        .tint(.green)
    }
}

// MARK: - Record View
struct RecordView: View {
    @Query(sort: \Player.addedOn) private var players: [Player]
    @Query private var matches: [Match]
    @Environment(\.modelContext) private var context

    @State private var newPlayerName = ""
    @State private var activePlayers: Set<String> = []
    @State private var selectedP1: String? = nil
    @State private var selectedP2: String? = nil
    @State private var selectedBreaker: String? = nil
    @State private var selectedWinner: String? = nil
    @State private var toastMessage: String? = nil
    @State private var toastIsError: Bool = false

    var canRecord: Bool {
        selectedP1 != nil && selectedP2 != nil &&
        selectedBreaker != nil && selectedWinner != nil
    }

    var sessions: Int {
        Set(matches.map {
            Calendar.current.startOfDay(for: $0.date)
        }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // ── Header ──
                    ZStack {
                        Color(red: 0.02, green: 0.18, blue: 0.09)
                        VStack(spacing: 20) {
                            Text("🎱")
                                .font(.system(size: 60))
                            Text("Pool Scorekeeper")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("Family pool stats tracker")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                            HStack(spacing: 12) {
                                StatChip(number: "\(players.count)", label: "Players")
                                StatChip(number: "\(matches.count)", label: "Matches")
                                StatChip(number: "\(sessions)", label: "Sessions")
                                StatChip(number: "\(matches.filter { !$0.breaker.isEmpty }.count)", label: "Breaks")
                            }
                        }
                        .padding(24)
                    }

                    // ── All Players ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("👥")
                            Text("All Players")
                                .font(.headline)
                        }
                        HStack {
                            TextField("Enter player name", text: $newPlayerName)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                            Button("Add") {
                                addPlayer()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        if players.isEmpty {
                            Text("No players yet — add some above")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(players) { player in
                                HStack {
                                    Text(player.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Button("Remove") {
                                        removePlayer(player)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    // ── Who's Playing Tonight ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("🟢")
                            Text("Who's Playing Tonight?")
                                .font(.headline)
                        }
                        if players.isEmpty {
                            Text("Add players above first")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100))
                            ], spacing: 8) {
                                ForEach(players) { player in
                                    Button(player.name) {
                                        togglePlayer(player.name)
                                    }
                                    .buttonStyle(ToggleButtonStyle(
                                        isActive: activePlayers.contains(player.name)
                                    ))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    // ── Record a Match ──
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Text("🎱")
                            Text("Record a Match")
                                .font(.headline)
                        }
                        if let message = toastMessage {
                            Text(message)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(toastIsError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                .foregroundStyle(toastIsError ? .red : .green)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        if activePlayers.count < 2 {
                            Text("Select at least 2 players above to start recording")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            StepLabel(number: 1, color: .blue, text: "Player 1")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(activePlayers.sorted().filter { $0 != selectedP2 }, id: \.self) { name in
                                        Button(name) {
                                            selectedP1 = name
                                            selectedBreaker = nil
                                            selectedWinner = nil
                                        }
                                        .buttonStyle(ToggleButtonStyle(isActive: selectedP1 == name))
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            StepLabel(number: 2, color: .purple, text: "Player 2")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(activePlayers.sorted().filter { $0 != selectedP1 }, id: \.self) { name in
                                        Button(name) {
                                            selectedP2 = name
                                            selectedBreaker = nil
                                            selectedWinner = nil
                                        }
                                        .buttonStyle(ToggleButtonStyle(isActive: selectedP2 == name))
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            StepLabel(number: 3, color: .teal, text: "Who Broke?")
                            if let p1 = selectedP1, let p2 = selectedP2 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([p1, p2], id: \.self) { name in
                                            Button(name) { selectedBreaker = name }
                                                .buttonStyle(ToggleButtonStyle(isActive: selectedBreaker == name))
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            } else {
                                Text("Select players 1 & 2 first")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            StepLabel(number: 4, color: .orange, text: "Winner")
                            if let p1 = selectedP1, let p2 = selectedP2 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([p1, p2], id: \.self) { name in
                                            Button(name) { selectedWinner = name }
                                                .buttonStyle(ToggleButtonStyle(isActive: selectedWinner == name))
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            } else {
                                Text("Select players 1 & 2 first")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Button("Record Match") {
                                recordMatch()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(canRecord ? Color.green : Color.gray.opacity(0.3))
                            .foregroundStyle(canRecord ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .fontWeight(.bold)
                            .disabled(!canRecord)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                }
            }
            .background(Color.gray.opacity(0.1))
        }
    }

    func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guard !players.map(\.name).contains(name) else { return }
        context.insert(Player(name: name))
        newPlayerName = ""
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func removePlayer(_ player: Player) {
        context.delete(player)
    }

    func togglePlayer(_ name: String) {
        if activePlayers.contains(name) {
            activePlayers.remove(name)
        } else {
            activePlayers.insert(name)
        }
    }

    func recordMatch() {
        guard let p1 = selectedP1,
              let p2 = selectedP2,
              let breaker = selectedBreaker,
              let winner = selectedWinner else { return }
        let match = Match(player1: p1, player2: p2,
                          winner: winner, breaker: breaker)
        context.insert(match)
        showToast("✓ \(p1) vs \(p2) → \(winner) wins!")
        selectedP1 = nil
        selectedP2 = nil
        selectedBreaker = nil
        selectedWinner = nil
    }

    func showToast(_ message: String, isError: Bool = false) {
        withAnimation {
            toastMessage = message
            toastIsError = isError
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { toastMessage = nil }
        }
    }
}
// MARK: - Stats View
struct StatsView: View {
    @Query private var matches: [Match]
    @Query(sort: \Player.addedOn) private var players: [Player]
    @State private var filterDate = Date()

    var playerNames: [String] {
        var names = Set<String>()
        for m in matches {
            names.insert(m.player1)
            names.insert(m.player2)
        }
        return names.sorted()
    }

    var allTimeStats: [PlayerStat] {
        StatsEngine.playerStats(matches: matches, players: playerNames)
    }

    var filteredStats: [PlayerStat] {
        let cal = Calendar.current
        let filtered = matches.filter {
            cal.isDate($0.date, inSameDayAs: filterDate)
        }
        return StatsEngine.playerStats(matches: filtered, players: playerNames)
    }

    var h2h: [H2HStat] {
        StatsEngine.headToHead(matches: matches, players: playerNames)
    }

    var breakData: (overall: Double, perPlayer: [BreakStat], total: Int)? {
        StatsEngine.breakStats(matches: matches, players: playerNames)
    }

    var sessions: Int {
        Set(matches.map {
            Calendar.current.startOfDay(for: $0.date)
        }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    HStack(spacing: 10) {
                        SummaryChip(value: "\(matches.count)", label: "Matches", color: .blue)
                        SummaryChip(value: "\(sessions)", label: "Sessions", color: .purple)
                        SummaryChip(value: "\(players.count)", label: "Players", color: .green)
                        SummaryChip(value: "\(matches.filter { !$0.breaker.isEmpty }.count)", label: "Breaks", color: .teal)
                    }
                    .padding(.horizontal, 16)

                    StatsSectionCard(icon: "🥇", title: "All-Time Leaderboard") {
                        if allTimeStats.isEmpty {
                            EmptyStatText("Record some matches to see stats")
                        } else {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Player")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("W")
                                        .frame(width: 35, alignment: .center)
                                    Text("L")
                                        .frame(width: 35, alignment: .center)
                                    Text("Win%")
                                        .frame(width: 55, alignment: .trailing)
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 8)

                                ForEach(Array(allTimeStats.enumerated()), id: \.element.name) { index, stat in
                                    HStack {
                                        HStack(spacing: 8) {
                                            Text(index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "  ")
                                                .font(.system(size: 14))
                                            Text(stat.name)
                                                .fontWeight(index == 0 ? .bold : .regular)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("\(stat.wins)")
                                            .frame(width: 35, alignment: .center)
                                            .foregroundStyle(.green)
                                            .fontWeight(.semibold)
                                        Text("\(stat.losses)")
                                            .frame(width: 35, alignment: .center)
                                            .foregroundStyle(.red)
                                        Text(String(format: "%.0f%%", stat.winPct))
                                            .frame(width: 55, alignment: .trailing)
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .padding(.vertical, 6)

                                    if index < allTimeStats.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    StatsSectionCard(icon: "⚔️", title: "Head to Head") {
                        if h2h.isEmpty {
                            EmptyStatText("Record matches between players to see head-to-head stats")
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(Array(h2h.enumerated()), id: \.offset) { _, stat in
                                    VStack(spacing: 6) {
                                        HStack {
                                            VStack(spacing: 2) {
                                                Text(stat.player1)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .lineLimit(1)
                                                Text("\(stat.wins1)")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundStyle(stat.wins1 > stat.wins2 ? .green : .primary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            Text("vs")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            VStack(spacing: 2) {
                                                Text(stat.player2)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .lineLimit(1)
                                                Text("\(stat.wins2)")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundStyle(stat.wins2 > stat.wins1 ? .green : .primary)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        if let leader = stat.leader {
                                            Text("\(leader) leads")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.green)
                                                .clipShape(Capsule())
                                        } else {
                                            Text("Tied")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.gray.opacity(0.2))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.systemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    StatsSectionCard(icon: "⚡", title: "Break Analysis") {
                        if let bd = breakData {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Overall break win rate")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "%.0f%%", bd.overall))
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.teal)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Tracked games")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(bd.total)")
                                            .font(.system(size: 32, weight: .bold))
                                    }
                                }
                                .padding(12)
                                .background(Color.teal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Player")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("Broke")
                                            .frame(width: 50, alignment: .center)
                                        Text("Win%")
                                            .frame(width: 50, alignment: .center)
                                        Text("Edge")
                                            .frame(width: 50, alignment: .trailing)
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 8)

                                    ForEach(Array(bd.perPlayer.enumerated()), id: \.element.player) { index, stat in
                                        HStack {
                                            Text(stat.player)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .font(.subheadline)
                                            Text("\(stat.brokeWon)/\(stat.broke)")
                                                .frame(width: 50, alignment: .center)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Text(String(format: "%.0f%%", stat.brkPct))
                                                .frame(width: 50, alignment: .center)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.teal)
                                            Text(stat.advantage >= 0 ?
                                                 String(format: "+%.0f%%", stat.advantage) :
                                                 String(format: "%.0f%%", stat.advantage))
                                                .frame(width: 50, alignment: .trailing)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(stat.advantage >= 0 ? .green : .red)
                                        }
                                        .padding(.vertical, 6)

                                        if index < bd.perPlayer.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        } else {
                            EmptyStatText("Record matches with break data to see analysis")
                        }
                    }

                    StatsSectionCard(icon: "📅", title: "Stats by Date") {
                        DatePicker("Select date", selection: $filterDate, displayedComponents: .date)
                            .font(.subheadline)
                        if filteredStats.isEmpty {
                            EmptyStatText("No matches on this date")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(filteredStats.enumerated()), id: \.element.name) { index, stat in
                                    HStack {
                                        Text(stat.name)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fontWeight(stat.wins > stat.losses ? .bold : .regular)
                                        Text("\(stat.wins)W \(stat.losses)L")
                                            .foregroundStyle(.secondary)
                                            .font(.subheadline)
                                    }
                                    .font(.subheadline)
                                    .padding(.vertical, 6)

                                    if index < filteredStats.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Stats")
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @Query(sort: \Match.timestamp, order: .reverse) private var matches: [Match]
    @Environment(\.modelContext) private var context
    @State private var showClearConfirmation = false

    var grouped: [(Date, [Match])] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: matches) { match -> Date in
            let components = cal.dateComponents([.year, .month, .day], from: match.date)
            return cal.date(from: components) ?? match.date
        }
        return byDay.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if matches.isEmpty {
                        VStack(spacing: 16) {
                            Text("🎱")
                                .font(.system(size: 60))
                            Text("No matches recorded yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Record some matches on the Record tab")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(grouped, id: \.0) { (date, dayMatches) in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .kerning(0.6)
                                    .padding(.horizontal, 16)

                                VStack(spacing: 0) {
                                    ForEach(dayMatches) { match in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 6) {
                                                    Text(match.player1)
                                                        .fontWeight(.semibold)
                                                    Text("vs")
                                                        .foregroundStyle(.secondary)
                                                        .font(.caption)
                                                    Text(match.player2)
                                                        .fontWeight(.semibold)
                                                    Text("→")
                                                        .foregroundStyle(.secondary)
                                                    Text(match.winner)
                                                        .foregroundStyle(.green)
                                                        .fontWeight(.bold)
                                                }
                                                .font(.subheadline)

                                                if !match.breaker.isEmpty {
                                                    Text("⚡ \(match.breaker) broke")
                                                        .font(.caption)
                                                        .foregroundStyle(.teal)
                                                }
                                            }
                                            Spacer()
                                            Button {
                                                context.delete(match)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.mini)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)

                                        if match.id != dayMatches.last?.id {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(.systemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                "Clear All History?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Matches", role: .destructive) {
                    clearAllMatches()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all \(matches.count) matches. This cannot be undone.")
            }
        }
    }

    func clearAllMatches() {
        matches.forEach { context.delete($0) }
    }
}
// MARK: - StatChip
struct StatChip: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ToggleButtonStyle
struct ToggleButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? Color.green : Color(.systemFill))
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isActive ? Color.green : Color.gray.opacity(0.3),
                    lineWidth: 1.5
                )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

// MARK: - StepLabel
struct StepLabel: View {
    let number: Int
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(text.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .kerning(0.6)
        }
    }
}

// MARK: - StatsSectionCard
struct StatsSectionCard<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon).font(.system(size: 16))
                Text(title).font(.headline)
            }
            content()
        }
        .padding(16)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}

// MARK: - SummaryChip
struct SummaryChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - EmptyStatText
struct EmptyStatText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}
