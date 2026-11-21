//
//  DeadlinesScreen.swift
//  Onglet « Échéances » : liste, ajout, fiche et formulaire d'une échéance.
//

import SwiftUI
import Combine
import UIKit

/// Valeur de navigation vers la fiche d'une échéance (différente de celle d'un abonnement).
nonisolated struct DeadlineRef: Hashable, Sendable {
    let id: UUID
}

// MARK: - Onglet

struct DeadlinesScreen: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: SubscriptionStore
    @ObservedObject var purchases: PurchaseManager

    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var showDone = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if store.deadlines.isEmpty {
                        emptyState
                    } else {
                        overviewCard
                        if store.notificationStatus == .denied && !store.activeDeadlines.isEmpty {
                            notificationsBanner
                        }
                        section(loc("dl_section_expired"), store.activeDeadlines.filter { $0.daysLeft < 0 })
                        section(loc("dl_section_soon"), store.activeDeadlines.filter { (0...90).contains($0.daysLeft) })
                        section(loc("dl_section_later"), store.activeDeadlines.filter { $0.daysLeft > 90 })
                        doneSection
                        if !purchases.isPro { freeCounter }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background { AppBackground() }
            .overlay(alignment: .bottomTrailing) {
                if !store.deadlines.isEmpty { addButton }
            }
            .navigationTitle(loc("dl_title"))
            .navigationDestination(for: DeadlineRef.self) { ref in
                DeadlineDetailView(store: store, deadlineID: ref.id)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddDeadlineView(store: store)
                .appAppearance()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchases: purchases)
                .appAppearance()
        }
    }

    private func addTapped() {
        Haptics.tap()
        if store.canAddDeadline(isPro: purchases.isPro) {
            showAdd = true
        } else {
            showPaywall = true
        }
    }

    private var addButton: some View {
        Button(action: addTapped) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(theme.diagonalGradient, in: Circle())
                .shadow(color: theme.primary.opacity(0.45), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 16)
        .accessibilityLabel(loc("dl_add_title"))
    }

    // MARK: Vide

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 30)
            Image(systemName: "hourglass")
                .font(.system(size: 54))
                .foregroundStyle(theme.diagonalGradient)
                .frame(width: 140, height: 140)
                .glassBackground(in: Circle())
            VStack(spacing: 10) {
                Text(loc("dl_empty_title"))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(loc("dl_empty_text"))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: addTapped) {
                PrimaryButtonLabel(title: loc("dl_empty_button"), icon: "plus")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
    }

    // MARK: Résumé

    private var overviewCard: some View {
        let active = store.activeDeadlines
        let expired = active.filter(\.isExpired).count
        let soon = active.filter { (0...30).contains($0.daysLeft) }.count
        return VStack(alignment: .leading, spacing: 12) {
            if let next = active.first(where: { $0.daysLeft >= 0 }) {
                Text(loc("dl_next"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(next.name)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.diagonalGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(next.statusText) · \(L10n.longDate(next.date))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Label(loc("dl_all_good"), systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
            HStack(spacing: 8) {
                pill(icon: "exclamationmark.triangle.fill", color: .red, text: loc("dl_pill_expired", expired))
                pill(icon: "clock.fill", color: .orange, text: loc("dl_pill_soon", soon))
                pill(icon: "hourglass", color: theme.primary, text: loc("dl_pill_total", active.count))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func pill(icon: String, color: Color, text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon).foregroundStyle(color)
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassBackground(in: Capsule())
    }

    private var notificationsBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(loc("notif_off_title"))
                    .font(.subheadline.bold())
                Spacer()
                Text(loc("enable"))
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.primary)
            }
            .foregroundStyle(.primary)
            .glassCard(cornerRadius: 22, padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: Listes

    @ViewBuilder
    private func section(_ title: String, _ items: [Deadline]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: title, trailing: "\(items.count)")
                ForEach(items) { item in
                    NavigationLink(value: DeadlineRef(id: item.id)) {
                        DeadlineRow(deadline: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var doneSection: some View {
        let done = store.doneDeadlines
        if !done.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.snappy) { showDone.toggle() }
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(loc("dl_done_section", done.count))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showDone ? 0 : -90))
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                if showDone {
                    ForEach(done) { item in
                        NavigationLink(value: DeadlineRef(id: item.id)) {
                            DeadlineRow(deadline: item).opacity(0.75)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var freeCounter: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text(loc("dl_free_counter", store.activeDeadlines.count, AppConfig.freeDeadlineLimit))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(loc("unlock"))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(theme.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassBackground(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ajout

struct AddDeadlineView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: SubscriptionStore

    @State private var search = ""
    @State private var draft: Deadline?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    private var trimmedSearch: String { search.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var filtered: [DeadlinePreset] {
        guard !trimmedSearch.isEmpty else { return DeadlineCatalog.presets }
        return DeadlineCatalog.presets.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
                || $0.kind.title.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    customButton
                    let presets = filtered
                    ForEach(DeadlineKind.allCases) { kind in
                        let items = presets.filter { $0.kind == kind }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(kind.title, systemImage: kind.icon)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(items) { preset in
                                        presetButton(preset)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.immediately)
            .background { AppBackground() }
            .navigationTitle(loc("dl_add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: loc("dl_search"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("cancel")) { dismiss() }
                }
            }
            .navigationDestination(item: $draft) { item in
                DeadlineEditor(store: store, original: item, isNew: true) { result in
                    if result == .saved { dismiss() } else { draft = nil }
                }
            }
        }
    }

    private var customButton: some View {
        Button {
            draft = Deadline(name: trimmedSearch)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(theme.diagonalGradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(trimmedSearch.isEmpty ? loc("dl_add_custom") : loc("add_custom_named", trimmedSearch))
                        .font(.headline)
                        .lineLimit(1)
                    Text(loc("dl_add_custom_text"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(14)
            .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
        }
        .buttonStyle(.plain)
    }

    private func presetButton(_ preset: DeadlinePreset) -> some View {
        Button {
            Haptics.tap()
            draft = preset.makeDeadline()
        } label: {
            HStack(spacing: 10) {
                DeadlineIcon(kind: preset.kind, size: 36)
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .glassBackground(in: RoundedRectangle(cornerRadius: 18, style: .continuous), interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Formulaire

struct DeadlineEditor: View {
    @Environment(\.appTheme) private var theme
    @ObservedObject var store: SubscriptionStore
    let isNew: Bool
    let onFinish: (EditorResult) -> Void

    @State private var draft: Deadline
    @State private var confirmDelete = false
    @FocusState private var focused: Bool

    init(store: SubscriptionStore, original: Deadline, isNew: Bool, onFinish: @escaping (EditorResult) -> Void) {
        self.store = store
        self.isNew = isNew
        self.onFinish = onFinish
        _draft = State(initialValue: original)
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    DeadlineIcon(kind: draft.kind, size: 72)
                    Text(draft.name.isEmpty ? loc("dl_name_placeholder") : draft.name)
                        .font(.headline)
                        .foregroundStyle(draft.name.isEmpty ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.clear)

            Section {
                TextField(loc("dl_name_placeholder"), text: $draft.name)
                    .textInputAutocapitalization(.sentences)
                    .focused($focused)
                Picker(selection: $draft.kind) {
                    ForEach(DeadlineKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon).tag(kind)
                    }
                } label: {
                    Label(loc("editor_category"), systemImage: "tag.fill")
                }
                DatePicker(selection: $draft.date, displayedComponents: .date) {
                    Label(loc("dl_date"), systemImage: "calendar")
                }
            } footer: {
                Text(loc("dl_date_footer"))
            }

            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(DeadlineReminder.options, id: \.self) { days in
                        reminderChip(days)
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Text(loc("dl_reminders"))
            } footer: {
                if store.notificationStatus == .denied {
                    Text(loc("editor_notif_denied"))
                } else {
                    Text(loc("dl_reminders_footer"))
                }
            }

            Section {
                Picker(selection: $draft.renewMonths) {
                    ForEach(DeadlineRenewal.options, id: \.self) { months in
                        Text(DeadlineRenewal.title(months)).tag(months)
                    }
                } label: {
                    Label(loc("dl_renew"), systemImage: "arrow.triangle.2.circlepath")
                }
            } footer: {
                Text(loc("dl_renew_footer"))
            }

            Section {
                TextField(loc("dl_notes_placeholder"), text: $draft.notes, axis: .vertical)
                    .lineLimit(2...6)
            } header: {
                Text(loc("editor_notes"))
            }

            if !isNew {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label(loc("delete"), systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { AppBackground() }
        .tint(theme.primary)
        .navigationTitle(isNew ? loc("dl_editor_new") : loc("editor_edit"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("cancel")) { onFinish(.cancelled) }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(loc("save")) { save() }
                    .fontWeight(.bold)
                    .disabled(!canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(loc("done")) { focused = false }
            }
        }
        .confirmationDialog(loc("delete_confirm", draft.name), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(loc("delete"), role: .destructive) {
                store.deleteDeadline(draft.id)
                onFinish(.deleted)
            }
            Button(loc("cancel"), role: .cancel) {}
        }
        .onAppear {
            if isNew && draft.name.isEmpty { focused = true }
        }
    }

    private func reminderChip(_ days: Int) -> some View {
        let selected = draft.reminders.contains(days)
        return Button {
            Haptics.tap()
            if selected {
                draft.reminders.removeAll { $0 == days }
            } else {
                draft.reminders.append(days)
                draft.reminders.sort(by: >)
            }
        } label: {
            Text(DeadlineReminder.chip(days))
                .font(.subheadline.weight(selected ? .bold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background {
                    if selected {
                        Capsule().fill(theme.diagonalGradient)
                    } else {
                        Capsule().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func save() {
        var item = draft
        item.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.date = Calendar.current.startOfDay(for: item.date)
        if isNew {
            store.addDeadline(item)
        } else {
            store.updateDeadline(item)
        }
        Haptics.success()
        onFinish(.saved)
    }
}

// MARK: - Fiche

struct DeadlineDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: SubscriptionStore
    let deadlineID: UUID

    @State private var showEditor = false
    @State private var showRenew = false
    @State private var renewDate = Date.now
    @State private var confirmDelete = false
    @State private var confetti = 0

    var body: some View {
        Group {
            if let item = store.deadline(deadlineID) {
                content(item)
            } else {
                ContentUnavailableView(loc("detail_missing"), systemImage: "questionmark.circle")
            }
        }
        .background { AppBackground() }
        .overlay { ConfettiView(trigger: confetti) }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ item: Deadline) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                header(item)
                infoCard(item)
                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(loc("editor_notes"), systemImage: "note.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(item.notes)
                            .textSelection(.enabled)
                    }
                    .glassCard()
                }
                actions(item)
            }
            .padding(16)
            .padding(.bottom, 20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(loc("edit")) { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                DeadlineEditor(store: store, original: item, isNew: false) { result in
                    showEditor = false
                    if result == .deleted { dismiss() }
                }
            }
            .appAppearance()
        }
        .sheet(isPresented: $showRenew) {
            renewSheet(item)
                .presentationDetents([.medium, .large])
                .appAppearance()
        }
        .confirmationDialog(loc("delete_confirm", item.name), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(loc("delete"), role: .destructive) {
                store.deleteDeadline(item.id)
                dismiss()
            }
            Button(loc("cancel"), role: .cancel) {}
        }
    }

    private func header(_ item: Deadline) -> some View {
        VStack(spacing: 12) {
            DeadlineIcon(kind: item.kind, size: 84)
            Text(item.name)
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Label(item.kind.title, systemImage: item.kind.icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if item.isActive {
                Text(item.statusText)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(item.statusColor)
                    .multilineTextAlignment(.center)
            } else {
                Label(loc("dl_done_label"), systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .glassBackground(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func infoCard(_ item: Deadline) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent {
                Text(L10n.longDate(item.date)).multilineTextAlignment(.trailing)
            } label: {
                Label(loc("dl_date"), systemImage: "calendar")
            }
            Divider()
            LabeledContent {
                Text(item.reminders.isEmpty
                     ? loc("reminder_none")
                     : item.reminders.sorted(by: >).map { DeadlineReminder.chip($0) }.joined(separator: ", "))
                    .multilineTextAlignment(.trailing)
            } label: {
                Label(loc("dl_reminders"), systemImage: "bell.fill")
            }
            if item.renewMonths > 0 {
                Divider()
                LabeledContent {
                    Text(DeadlineRenewal.title(item.renewMonths))
                } label: {
                    Label(loc("dl_renew"), systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .font(.subheadline)
        .glassCard()
    }

    private func actions(_ item: Deadline) -> some View {
        VStack(spacing: 12) {
            if item.isActive {
                Button {
                    renewDate = item.suggestedRenewalDate
                    showRenew = true
                } label: {
                    PrimaryButtonLabel(title: loc("dl_mark_renewed"), icon: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)
                Button {
                    store.markDeadlineDone(item.id)
                    Haptics.success()
                } label: {
                    Label(loc("dl_mark_done"), systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .glassBackground(in: Capsule(), interactive: true)
                }
                .buttonStyle(.plain)
                Text(loc("dl_mark_done_hint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            } else {
                Button {
                    store.reactivateDeadline(item.id)
                    Haptics.tap()
                } label: {
                    PrimaryButtonLabel(title: loc("dl_reactivate"), icon: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label(loc("delete"), systemImage: "trash")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .glassBackground(in: Capsule(), interactive: true)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func renewSheet(_ item: Deadline) -> some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(loc("dl_new_date"), selection: $renewDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                } footer: {
                    Text(loc("dl_renew_sheet_footer"))
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackground() }
            .tint(theme.primary)
            .navigationTitle(loc("dl_mark_renewed"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("cancel")) { showRenew = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("save")) {
                        store.renewDeadline(item.id, to: renewDate)
                        showRenew = false
                        Haptics.success()
                        confetti += 1
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
