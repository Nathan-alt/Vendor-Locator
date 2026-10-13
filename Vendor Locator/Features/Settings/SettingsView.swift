import SwiftUI

/// Manages token storage actions and displays configured service information.
struct SettingsView: View {
    @StateObject private var model: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(tokens: any TokenStoreProtocol, services: ServicePresentation) {
        _model = StateObject(
            wrappedValue: SettingsViewModel(tokenStore: tokens, services: services)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                sessionSection
                messageSection
                servicesSection
            }
            .navigationTitle(L10n.settings)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(L10n.done) { dismiss() } }
            }
            .appTheme()
            .onChange(of: scenePhase) { phase in
                if phase != .active {
                    model.clearSensitiveState()
                }
            }
        }
    }

    private var sessionSection: some View {
        Section {
            sessionControls
        } header: {
            Text(L10n.session)
        } footer: {
            Text(L10n.secureStorageNotice)
        }
    }

    @ViewBuilder
    private var sessionControls: some View {
        SecureField(L10n.sessionToken, text: $model.input)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        Button(L10n.saveSecurely) { model.saveToken() }
            .disabled(model.isSaveDisabled)
        Button(L10n.revealToken) { model.revealToken() }
        if let revealedToken = model.revealedToken {
            Text(revealedToken).font(DS.Typography.code).textSelection(.enabled)
            Button(L10n.hideToken) { model.hideToken() }
        }
        Button(L10n.clearToken, role: .destructive) { model.clearToken() }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let message = model.message {
            Section {
                DSMessageView(
                    message: message,
                    tone: model.messageIsError ? .error : .information
                )
                .accessibilityIdentifier("tokenStatus")
            }
        }
    }

    private var servicesSection: some View {
        Section(L10n.services) {
            LabeledContent(L10n.vendors, value: model.services.vendorSourceName)
            LabeledContent(
                L10n.places,
                value: model.services.isMockPlaces ? L10n.mock : L10n.google
            )
            LabeledContent(
                L10n.mapKey,
                value: model.services.isMapConfigured ? L10n.configured : L10n.notConfigured
            )
        }
    }
}

#if DEBUG
#Preview("Settings · Isolated storage") {
    SettingsView(
        tokens: PreviewTokenStoreImpl(),
        services: ServicePresentation(
            isMockPlaces: true,
            isMapConfigured: false,
            vendorSourceName: L10n.previewService
        )
    )
}
#Preview("Settings · Configured services") {
    SettingsView(
        tokens: PreviewTokenStoreImpl(),
        services: ServicePresentation(
            isMockPlaces: false,
            isMapConfigured: true,
            vendorSourceName: L10n.previewService
        )
    )

}
#endif
