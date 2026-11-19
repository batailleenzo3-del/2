//
//  AddSubscriptionView.swift
//  Choisir un service connu (ou créer le sien), puis compléter la fiche.
//

import SwiftUI
import Combine

struct AddSubscriptionView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: SubscriptionStore

    @State private var search = ""
    @State private var draft: Subscription?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    private var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filtered: [ServicePreset] {
        guard !trimmedSearch.isEmpty else { return Catalog.presets }
        return Catalog.presets.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
                || $0.category.title.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    customButton

                    let presets = filtered
                    ForEach(SubCategory.allCases) { category in
                        let items = presets.filter { $0.category == category }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(category.title, systemImage: category.icon)
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
            .navigationTitle(loc("add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: loc("add_search"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("cancel")) { dismiss() }
                }
            }
            .navigationDestination(item: $draft) { sub in
                SubscriptionEditor(store: store, original: sub, isNew: true) { result in
                    if result == .saved {
                        dismiss()
                    } else {
                        draft = nil
                    }
                }
            }
        }
    }

    private var customButton: some View {
        Button {
            draft = Subscription(name: trimmedSearch)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(theme.diagonalGradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(trimmedSearch.isEmpty ? loc("add_custom") : loc("add_custom_named", trimmedSearch))
                        .font(.headline)
                        .lineLimit(1)
                    Text(loc("add_custom_text"))
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

    private func presetButton(_ preset: ServicePreset) -> some View {
        Button {
            Haptics.tap()
            draft = preset.makeSubscription()
        } label: {
            HStack(spacing: 10) {
                SubIconView(name: preset.name, color: SubPalette.color(preset.colorIndex), symbol: preset.symbol, size: 36)
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
