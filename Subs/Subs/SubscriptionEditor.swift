//
//  SubscriptionEditor.swift
//  Ajouter ou modifier un abonnement.
//

import SwiftUI
import Combine
import UserNotifications

enum EditorResult {
    case saved, deleted, cancelled
}

struct SubscriptionEditor: View {
    @Environment(\.appTheme) private var theme
    @ObservedObject var store: SubscriptionStore
    let isNew: Bool
    let onFinish: (EditorResult) -> Void

    @State private var draft: Subscription
    @State private var priceText: String
    @State private var paymentDate: Date
    @State private var dateEdited = false
    @State private var confirmDelete = false
    @FocusState private var focusedField: Field?

    private enum Field { case name, price, url, notes }

    init(store: SubscriptionStore, original: Subscription, isNew: Bool, onFinish: @escaping (EditorResult) -> Void) {
        self.store = store
        self.isNew = isNew
        self.onFinish = onFinish
        _draft = State(initialValue: original)
        _priceText = State(initialValue: original.price > 0 ? Self.format(original.price) : "")
        _paymentDate = State(initialValue: original.nextPayment() ?? original.anchorDate)
    }

    private static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }

    /// Accepte "9,99", "9.99", "9 €"…
    private var parsedPrice: Double {
        let cleaned = priceText
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        return Double(cleaned) ?? 0
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            previewSection
            mainSection
            dateSection
            reminderSection
            lookSection
            shareSection
            cancelSection
            Section {
                TextField(loc("editor_notes_placeholder"), text: $draft.notes, axis: .vertical)
                    .lineLimit(2...6)
                    .focused($focusedField, equals: .notes)
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
        .navigationTitle(isNew ? loc("editor_new") : loc("editor_edit"))
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
                Button(loc("done")) { focusedField = nil }
            }
        }
        .confirmationDialog(loc("delete_confirm", draft.name), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(loc("delete"), role: .destructive) {
                store.delete(draft.id)
                onFinish(.deleted)
            }
            Button(loc("cancel"), role: .cancel) {}
        }
        .onAppear {
            if isNew && draft.name.isEmpty { focusedField = .name }
        }
    }

    // MARK: Sections

    private var previewSection: some View {
        Section {
            VStack(spacing: 10) {
                SubIconView(name: draft.name, color: draft.color, symbol: draft.symbol, size: 72)
                Text(draft.name.isEmpty ? loc("editor_name_placeholder") : draft.name)
                    .font(.headline)
                    .foregroundStyle(draft.name.isEmpty ? .secondary : .primary)
                if parsedPrice > 0 {
                    Text("\(L10n.money(parsedPrice / Double(max(1, draft.sharedWith)))) \(draft.cycle.perTitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
    }

    private var mainSection: some View {
        Section {
            TextField(loc("editor_name_placeholder"), text: $draft.name)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .price }
            HStack {
                Text(loc("editor_price"))
                Spacer()
                TextField("0", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .price)
                    .frame(maxWidth: 150)
                Text(L10n.currencySymbol)
                    .foregroundStyle(.secondary)
            }
            Picker(loc("editor_cycle"), selection: $draft.cycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.title).tag(cycle)
                }
            }
        } footer: {
            Text(loc("editor_price_footer"))
        }
    }

    private var dateSection: some View {
        Section {
            Toggle(isOn: $draft.isTrial.animation()) {
                Label(loc("editor_trial"), systemImage: "hourglass")
            }
            DatePicker(selection: Binding(get: { paymentDate }, set: { paymentDate = $0; dateEdited = true }),
                       displayedComponents: .date) {
                Label(draft.isTrial ? loc("editor_trial_end") : loc("editor_next_payment"), systemImage: "calendar")
            }
        } footer: {
            Text(draft.isTrial ? loc("editor_trial_footer") : loc("editor_date_footer"))
        }
    }

    private var reminderSection: some View {
        Section {
            Picker(selection: $draft.reminderDays) {
                ForEach(ReminderOption.allCases) { option in
                    Text(option.title).tag(option.rawValue)
                }
            } label: {
                Label(loc("editor_reminder"), systemImage: "bell.fill")
            }
        } footer: {
            if store.notificationStatus == .denied {
                Text(loc("editor_notif_denied"))
            } else {
                Text(loc("editor_reminder_footer"))
            }
        }
    }

    private var lookSection: some View {
        Section {
            Picker(selection: $draft.category) {
                ForEach(SubCategory.allCases) { category in
                    Label(category.title, systemImage: category.icon).tag(category)
                }
            } label: {
                Label(loc("editor_category"), systemImage: "tag.fill")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SubPalette.colors.indices, id: \.self) { index in
                        let selected = index == draft.colorIndex
                        Button {
                            draft.colorIndex = index
                            Haptics.tap()
                        } label: {
                            Circle()
                                .fill(SubPalette.colors[index])
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.heavy))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(3)
                                .overlay(Circle().strokeBorder(SubPalette.colors[index], lineWidth: selected ? 2 : 0))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
                symbolButton(nil)
                ForEach(SubPalette.symbols, id: \.self) { symbol in
                    symbolButton(symbol)
                }
            }
            .padding(.vertical, 6)
        } header: {
            Text(loc("editor_look"))
        }
    }

    private func symbolButton(_ symbol: String?) -> some View {
        let selected = draft.symbol == symbol
        return Button {
            draft.symbol = symbol
            Haptics.tap()
        } label: {
            SubIconView(name: draft.name, color: selected ? draft.color : Color.secondary.opacity(0.35),
                        symbol: symbol, size: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(selected ? theme.primary : Color.clear, lineWidth: 2)
                        .padding(-3)
                )
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(symbol ?? loc("editor_initial"))
    }

    private var shareSection: some View {
        Section {
            Stepper(value: $draft.sharedWith, in: 1...20) {
                Label(draft.sharedWith == 1 ? loc("editor_not_shared") : loc("editor_shared", draft.sharedWith),
                      systemImage: "person.2.fill")
            }
            if draft.sharedWith > 1 {
                LabeledContent(loc("editor_your_share"),
                               value: L10n.money(parsedPrice / Double(max(1, draft.sharedWith))))
            }
        } footer: {
            Text(loc("editor_shared_footer"))
        }
    }

    private var cancelSection: some View {
        Section {
            Toggle(isOn: $draft.billedByApple.animation()) {
                Label(loc("editor_apple"), systemImage: "creditcard.fill")
            }
            if !draft.billedByApple {
                TextField(loc("editor_url"), text: $draft.manageURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .url)
            }
        } header: {
            Text(loc("editor_cancel_section"))
        } footer: {
            Text(loc("editor_cancel_footer"))
        }
    }

    // MARK: Enregistrer

    private func save() {
        var sub = draft
        sub.name = sub.name.trimmingCharacters(in: .whitespacesAndNewlines)
        sub.price = parsedPrice
        sub.manageURL = sub.manageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if isNew || dateEdited {
            sub.anchorDate = Calendar.current.startOfDay(for: paymentDate)
        }
        if isNew {
            store.add(sub)
        } else {
            store.update(sub)
        }
        Haptics.success()
        onFinish(.saved)
    }
}
