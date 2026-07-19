import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    @State private var activePlayers: Set<UUID> = []
    @State private var selectedP1: Player? = nil
    @State private var selectedP2: Player? = nil
    @State private var selectedBreaker: Player? = nil
    @State private var selectedWinner: Player? = nil
    @State private var toastMessage: String? = nil
    @State private var toastIsError: Bool = false

    var canRecord: Bool {
        selectedP1 != nil && selectedP2 != nil &&
        selectedBreaker != nil && selectedWinner != nil
    }

    var sessions: Int {
        Set(matches.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    // Break suggestion: whoever did NOT break last time breaks next (alternate)
    var breakSuggestion: Player? {
        guard let p1 = selectedP1, let p2 = selectedP2 else { return nil }
        let between = matches
            .filter {
                ($0.player1?.id == p1.id || $0.player2?.id == p1.id) &&
                ($0.player1?.id == p2.id || $0.player2?.id == p2.id)
            }
            .sorted { $0.timestamp > $1.timestamp }
        guard let last = between.first, let lastBreaker = last.breaker else { return nil }
        return lastBreaker.id == p1.id ? p2 : p1
    }

    var activePlayerList: [Player] {
        players.filter { activePlayers.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    allPlayersSection
                    tonightSection
                    recordMatchSection
                }
            }
            .background(Color.gray.opacity(0.1))
        }
    }

    // ── Header ──
    var headerSection: some View {
        ZStack {
            Color(red: 0.02, green: 0.18, blue: 0.09)
            VStack(spacing: 20) {
                Text("🎱").font(.system(size: 60))
                Text("Pool Scorekeeper")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Family pool stats tracker")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 12) {
                    StatChip(number: "\(players.count)", label: "Players")
                    StatChip(number: "\(matches.count)", label: "Matches")
                    StatChip(number: "\(sessions)", label: "Sessions")
                    StatChip(number: "\(matches.filter { $0.breaker != nil }.count)", label: "Breaks")
                }
            }
            .padding(24)
        }
    }

    // ── All Players ──
    var allPlayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("👥")
                Text("All Players").font(.headline)
            }
            HStack {
                TextField("Enter player name", text: $newPlayerName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                Button("Add") { addPlayer() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if players.isEmpty {
                Text("No players yet — add some above")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                ForEach(players) { player in
                    HStack {
                        Text(player.name).font(.subheadline)
                        Spacer()
                        Button("Remove") { removePlayer(player) }
                            .font(.caption).foregroundStyle(.red)
                            .buttonStyle(.bordered).controlSize(.mini)
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
    }

    // ── Who's Playing Tonight ──
    var tonightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("🟢")
                Text("Who's Playing Tonight?").font(.headline)
            }
            if players.isEmpty {
                Text("Add players above first")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(players) { player in
                        Button(player.name) { togglePlayer(player) }
                            .buttonStyle(ToggleButtonStyle(isActive: activePlayers.contains(player.id)))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    // ── Record a Match ──
    var recordMatchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("🎱")
                Text("Record a Match").font(.headline)
            }

            if let message = toastMessage {
                Text(message)
                    .font(.subheadline).fontWeight(.medium)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(toastIsError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .foregroundStyle(toastIsError ? .red : .green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if activePlayerList.count < 2 {
                Text("Select at least 2 players above to start recording")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                playerStep(number: 1, color: .blue, label: "Player 1",
                           options: activePlayerList.filter { $0.id != selectedP2?.id },
                           selection: selectedP1) { p in
                    selectedP1 = p; selectedBreaker = nil; selectedWinner = nil
                    applyBreakSuggestion()
                }
                playerStep(number: 2, color: .purple, label: "Player 2",
                           options: activePlayerList.filter { $0.id != selectedP1?.id },
                           selection: selectedP2) { p in
                    selectedP2 = p; selectedBreaker = nil; selectedWinner = nil
                    applyBreakSuggestion()
                }

                if let suggestion = breakSuggestion {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill").foregroundStyle(.yellow).font(.caption)
                        Text("Suggested breaker: \(suggestion.name)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let p1 = selectedP1, let p2 = selectedP2 {
                    playerStep(number: 3, color: .teal, label: "Who Broke?",
                               options: [p1, p2], selection: selectedBreaker) { p in
                        selectedBreaker = p
                    }
                    playerStep(number: 4, color: .orange, label: "Winner",
                               options: [p1, p2], selection: selectedWinner) { p in
                        selectedWinner = p
                    }
                }

                Button("Record Match") { recordMatch() }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(canRecord ? Color.green : Color.gray.opacity(0.3))
                    .foregroundStyle(canRecord ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .fontWeight(.bold).disabled(!canRecord)
            }
        }
        .padding(16)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    func playerStep(number: Int, color: Color, label: String,
                    options: [Player], selection: Player?,
                    action: @escaping (Player) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StepLabel(number: number, color: color, text: label)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { p in
                        Button(p.name) { action(p) }
                            .buttonStyle(ToggleButtonStyle(isActive: selection?.id == p.id))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // ── Actions ──
    func applyBreakSuggestion() {
        if selectedBreaker == nil, let s = breakSuggestion {
            selectedBreaker = s
        }
    }

    func addPlayer() {
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guard !players.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        context.insert(Player(name: name))
        newPlayerName = ""
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func removePlayer(_ player: Player) {
        activePlayers.remove(player.id)
        context.delete(player)
    }

    func togglePlayer(_ player: Player) {
        if activePlayers.contains(player.id) {
            activePlayers.remove(player.id)
        } else {
            activePlayers.insert(player.id)
        }
    }

    func recordMatch() {
        guard let p1 = selectedP1, let p2 = selectedP2,
              let winner = selectedWinner else { return }
        let match = Match(player1: p1, player2: p2, winner: winner, breaker: selectedBreaker)
        context.insert(match)
        showToast("✓ \(p1.name) vs \(p2.name) → \(winner.name) wins!")
        selectedP1 = nil; selectedP2 = nil
        selectedBreaker = nil; selectedWinner = nil
    }

    func showToast(_ message: String, isError: Bool = false) {
        withAnimation { toastMessage = message; toastIsError = isError }
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

    var playerStats: [(player: Player, wins: Int, losses: Int)] {
        players.compactMap { player in
            let wins = matches.filter { $0.winner?.id == player.id }.count
            let losses = matches.filter {
                ($0.player1?.id == player.id || $0.player2?.id == player.id) &&
                $0.winner?.id != player.id
            }.count
            guard wins + losses > 0 else { return nil }
            return (player, wins, losses)
        }.sorted { $0.wins > $1.wins }
    }

    var sessions: Int {
        Set(matches.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var filteredStats: [(player: Player, wins: Int, losses: Int)] {
        let cal = Calendar.current
        let dayMatches = matches.filter { cal.isDate($0.date, inSameDayAs: filterDate) }
        return players.compactMap { player in
            let wins = dayMatches.filter { $0.winner?.id == player.id }.count
            let losses = dayMatches.filter {
                ($0.player1?.id == player.id || $0.player2?.id == player.id) &&
                $0.winner?.id != player.id
            }.count
            guard wins + losses > 0 else { return nil }
            return (player, wins, losses)
        }.sorted { $0.wins > $1.wins }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        SummaryChip(value: "\(matches.count)", label: "Matches", color: .blue)
                        SummaryChip(value: "\(sessions)", label: "Sessions", color: .purple)
                        SummaryChip(value: "\(players.count)", label: "Players", color: .green)
                        SummaryChip(value: "\(matches.filter { $0.breaker != nil }.count)", label: "Breaks", color: .teal)
                    }
                    .padding(.horizontal, 16)

                    leaderboardCard
                    headToHeadCard
                    breakAnalysisCard
                    dateFilterCard
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Stats")
        }
    }

    var leaderboardCard: some View {
        StatsSectionCard(icon: "🥇", title: "All-Time Leaderboard") {
            if playerStats.isEmpty {
                EmptyStatText("Record some matches to see stats")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(playerStats.enumerated()), id: \.element.player.id) { index, stat in
                        HStack {
                            HStack(spacing: 8) {
                                Text(index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "  ")
                                Text(stat.player.name).fontWeight(index == 0 ? .bold : .regular)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(stat.wins)").frame(width: 35).foregroundStyle(.green).fontWeight(.semibold)
                            Text("\(stat.losses)").frame(width: 35).foregroundStyle(.red)
                            let total = stat.wins + stat.losses
                            let pct = total > 0 ? Double(stat.wins) / Double(total) * 100 : 0
                            Text(String(format: "%.0f%%", pct)).frame(width: 55, alignment: .trailing).fontWeight(.semibold)
                        }
                        .font(.subheadline).padding(.vertical, 6)
                        if index < playerStats.count - 1 { Divider() }
                    }
                }
            }
        }
    }

    var headToHeadCard: some View {
        StatsSectionCard(icon: "⚔️", title: "Head to Head") {
            let h2h = headToHeadData()
            if h2h.isEmpty {
                EmptyStatText("Record matches between players to see head-to-head")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(h2h.enumerated()), id: \.offset) { _, stat in
                        VStack(spacing: 6) {
                            HStack {
                                VStack(spacing: 2) {
                                    Text(stat.name1).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                                    Text("\(stat.wins1)").font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(stat.wins1 > stat.wins2 ? .green : .primary)
                                }.frame(maxWidth: .infinity)
                                Text("vs").font(.caption).foregroundStyle(.secondary)
                                VStack(spacing: 2) {
                                    Text(stat.name2).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                                    Text("\(stat.wins2)").font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(stat.wins2 > stat.wins1 ? .green : .primary)
                                }.frame(maxWidth: .infinity)
                            }
                        }
                        .padding(12).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    struct H2H { let name1: String; let name2: String; let wins1: Int; let wins2: Int }

    func headToHeadData() -> [H2H] {
        var results: [H2H] = []
        let sorted = players.sorted { $0.name < $1.name }
        for i in 0..<sorted.count {
            for j in (i+1)..<sorted.count {
                let p1 = sorted[i], p2 = sorted[j]
                let between = matches.filter {
                    ($0.player1?.id == p1.id || $0.player2?.id == p1.id) &&
                    ($0.player1?.id == p2.id || $0.player2?.id == p2.id)
                }
                let w1 = between.filter { $0.winner?.id == p1.id }.count
                let w2 = between.filter { $0.winner?.id == p2.id }.count
                if w1 + w2 > 0 {
                    results.append(H2H(name1: p1.name, name2: p2.name, wins1: w1, wins2: w2))
                }
            }
        }
        return results
    }

    var breakAnalysisCard: some View {
        StatsSectionCard(icon: "⚡", title: "Break Analysis") {
            let tracked = matches.filter { $0.breaker != nil }
            if tracked.isEmpty {
                EmptyStatText("Record matches with break data to see analysis")
            } else {
                let breakerWon = tracked.filter { $0.breaker?.id == $0.winner?.id }.count
                let pct = Double(breakerWon) / Double(tracked.count) * 100
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overall break win rate").font(.caption).foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", pct)).font(.system(size: 32, weight: .bold)).foregroundStyle(.teal)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Tracked games").font(.caption).foregroundStyle(.secondary)
                        Text("\(tracked.count)").font(.system(size: 32, weight: .bold))
                    }
                }
                .padding(12).background(Color.teal.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    var dateFilterCard: some View {
        StatsSectionCard(icon: "📅", title: "Stats by Date") {
            DatePicker("Select date", selection: $filterDate, displayedComponents: .date)
                .font(.subheadline)
            if filteredStats.isEmpty {
                EmptyStatText("No matches on this date")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredStats.enumerated()), id: \.element.player.id) { index, stat in
                        HStack {
                            Text(stat.player.name).frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(stat.wins > stat.losses ? .bold : .regular)
                            Text("\(stat.wins)W \(stat.losses)L").foregroundStyle(.secondary).font(.subheadline)
                        }
                        .font(.subheadline).padding(.vertical, 6)
                        if index < filteredStats.count - 1 { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @Query(sort: \Match.timestamp, order: .reverse) private var matches: [Match]
    @Query(sort: \Player.addedOn) private var players: [Player]
    @Environment(\.modelContext) private var context
    @State private var showClearConfirmation = false
    @State private var showImporter = false
    @State private var importResult: String? = nil
    @State private var showImportResult = false

    var grouped: [(Date, [Match])] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: matches) { match -> Date in
            let comps = cal.dateComponents([.year, .month, .day], from: match.date)
            return cal.date(from: comps) ?? match.date
        }
        return byDay.sorted { $0.key > $1.key }
    }

    var csvString: String {
        var lines = ["Date,Player 1,Player 2,Winner,Breaker"]
        let formatter = ISO8601DateFormatter()
        for match in matches.sorted(by: { $0.timestamp < $1.timestamp }) {
            let date = formatter.string(from: match.date)
            let p1 = match.player1?.name ?? ""
            let p2 = match.player2?.name ?? ""
            let w = match.winner?.name ?? ""
            let b = match.breaker?.name ?? "None"
            lines.append("\(date),\(p1),\(p2),\(w),\(b)")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if matches.isEmpty {
                        VStack(spacing: 16) {
                            Text("🎱").font(.system(size: 60))
                            Text("No matches recorded yet").font(.headline).foregroundStyle(.secondary)
                            Text("Record some matches on the Record tab").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 60)
                    } else {
                        ForEach(grouped, id: \.0) { (date, dayMatches) in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                                    .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                                    .textCase(.uppercase).kerning(0.6).padding(.horizontal, 16)
                                VStack(spacing: 0) {
                                    ForEach(dayMatches) { match in
                                        matchRow(match)
                                        if match.id != dayMatches.last?.id {
                                            Divider().padding(.leading, 16)
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
                    Menu {
                        ShareLink(item: csvString) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                        if !matches.isEmpty {
                            Button(role: .destructive) {
                                showClearConfirmation = true
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                handleImport(result)
            }
            .confirmationDialog("Clear All History?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Delete All Matches", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(matches.count) matches. This cannot be undone.")
            }
            .alert("Import Complete", isPresented: $showImportResult) {
                Button("OK") {}
            } message: {
                Text(importResult ?? "")
            }
        }
    }

    func matchRow(_ match: Match) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(match.player1?.name ?? "?").fontWeight(.semibold)
                    Text("vs").foregroundStyle(.secondary).font(.caption)
                    Text(match.player2?.name ?? "?").fontWeight(.semibold)
                    Text("→").foregroundStyle(.secondary)
                    Text(match.winner?.name ?? "?").foregroundStyle(.green).fontWeight(.bold)
                }
                .font(.subheadline)
                if let breaker = match.breaker {
                    Text("⚡ \(breaker.name) broke").font(.caption).foregroundStyle(.teal)
                }
            }
            Spacer()
            Button {
                context.delete(match)
            } label: {
                Image(systemName: "trash").font(.caption).foregroundStyle(.red)
            }
            .buttonStyle(.bordered).controlSize(.mini)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    func clearAll() {
        matches.forEach { context.delete($0) }
    }

    func findOrCreatePlayer(_ name: String) -> Player {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = players.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return existing
        }
        let newPlayer = Player(name: trimmed)
        context.insert(newPlayer)
        return newPlayer
    }

    func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importResult = "Could not access the file."
                showImportResult = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                importCSV(content)
            } catch {
                importResult = "Could not read the file: \(error.localizedDescription)"
                showImportResult = true
            }
        case .failure(let error):
            importResult = "Import failed: \(error.localizedDescription)"
            showImportResult = true
        }
    }

    func importCSV(_ content: String) {
        let formatter = ISO8601DateFormatter()
        var imported = 0, skipped = 0, duplicates = 0

        // Build a local lookup of existing players (by lowercased name) ONCE
        var playerLookup: [String: Player] = [:]
        for p in players {
            playerLookup[p.name.lowercased()] = p
        }

        // Helper that checks the local lookup first, creates if needed
        func resolvePlayer(_ name: String) -> Player {
            let key = name.lowercased()
            if let existing = playerLookup[key] {
                return existing
            }
            let newPlayer = Player(name: name)
            context.insert(newPlayer)
            playerLookup[key] = newPlayer
            return newPlayer
        }

        // Track imported matches locally to detect duplicates within this import
        var existingKeys = Set<String>()
        for m in matches {
            let key = "\(m.date.timeIntervalSince1970)-\(m.player1?.name ?? "")-\(m.player2?.name ?? "")-\(m.winner?.name ?? "")"
            existingKeys.insert(key)
        }

        let rows = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for (i, row) in rows.enumerated() {
            if i == 0 && row.lowercased().hasPrefix("date") { continue }
            let cols = row.components(separatedBy: ",")
            guard cols.count >= 4 else { skipped += 1; continue }

            let dateStr = cols[0].trimmingCharacters(in: .whitespaces)
            let p1Name = cols[1].trimmingCharacters(in: .whitespaces)
            let p2Name = cols[2].trimmingCharacters(in: .whitespaces)
            let wName = cols[3].trimmingCharacters(in: .whitespaces)
            let bName = cols.count >= 5 ? cols[4].trimmingCharacters(in: .whitespaces) : "None"

            guard !p1Name.isEmpty, !p2Name.isEmpty, !wName.isEmpty else { skipped += 1; continue }
            let date = formatter.date(from: dateStr) ?? Date()

            let dupKey = "\(date.timeIntervalSince1970)-\(p1Name)-\(p2Name)-\(wName)"
            if existingKeys.contains(dupKey) { duplicates += 1; continue }
            existingKeys.insert(dupKey)

            let p1 = resolvePlayer(p1Name)
            let p2 = resolvePlayer(p2Name)
            let winner = resolvePlayer(wName)
            let breaker: Player? = (bName.isEmpty || bName.lowercased() == "none") ? nil : resolvePlayer(bName)

            let match = Match(player1: p1, player2: p2, winner: winner, breaker: breaker)
            match.date = date
            match.timestamp = date
            context.insert(match)
            imported += 1
        }

        // Explicitly save so the data persists
        do {
            try context.save()
        } catch {
            print("Save failed: \(error)")
        }

        importResult = "Imported \(imported) matches.\n\(duplicates) duplicates skipped.\n\(skipped) invalid rows skipped."
        showImportResult = true
    }
}

// MARK: - Supporting Views
struct StatChip: View {
    let number: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(number).font(.system(size: 22, weight: .bold, design: .monospaced)).foregroundStyle(.white)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.55)).textCase(.uppercase)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ToggleButtonStyle: ButtonStyle {
    let isActive: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(isActive ? Color.green : Color(.systemFill))
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isActive ? Color.green : Color.gray.opacity(0.3), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct StepLabel: View {
    let number: Int
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(color).frame(width: 22, height: 22)
                Text("\(number)").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
            }
            Text(text.uppercased()).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary).kerning(0.6)
        }
    }
}

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
        .padding(16).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 16)
    }
}

struct SummaryChip: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(color)
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary).textCase(.uppercase).kerning(0.5)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EmptyStatText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
}
