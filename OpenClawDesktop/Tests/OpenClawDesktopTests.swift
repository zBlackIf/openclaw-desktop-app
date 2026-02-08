import Testing

@Test func appStateInitialization() async throws {
    let appState = AppState()
    #expect(appState.connectionStatus == .disconnected)
    #expect(appState.currentModel == "")
    #expect(appState.selectedNavItem == .chat)
}
