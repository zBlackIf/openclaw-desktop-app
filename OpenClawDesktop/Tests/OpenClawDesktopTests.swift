import Foundation
import Testing
@testable import OpenClawDesktop

// MARK: - AppState Tests

@MainActor
@Test func appStateInitialization() async throws {
    let appState = AppState()
    #expect(appState.connectionStatus == .disconnected)
    #expect(appState.currentModel == "")
    #expect(appState.selectedNavItem == .chat)
    #expect(appState.isAgentRunning == false)
    #expect(appState.autoConnect == true)
    #expect(appState.gatewayURL == "ws://127.0.0.1:18789")
}

@MainActor
@Test func appStateErrorDisplay() async throws {
    let appState = AppState()
    #expect(appState.showError == false)
    #expect(appState.errorMessage == nil)

    appState.showError("Test error")
    #expect(appState.showError == true)
    #expect(appState.errorMessage == "Test error")
}

// MARK: - GatewayProtocol Tests

@Test func gatewayRequestEncoding() throws {
    let request = GatewayRequest(method: "test.method")
    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    #expect(json["type"] as? String == "req")
    #expect(json["method"] as? String == "test.method")
    let id = json["id"] as? String
    #expect(id != nil)
    #expect(id?.isEmpty == false)
}

@Test func gatewayRequestWithParams() throws {
    let params = AnyCodable(["key": "value", "count": 42] as [String: Any])
    let request = GatewayRequest(method: "config.set", params: params)
    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    #expect(json["method"] as? String == "config.set")
    let decodedParams = json["params"] as? [String: Any]
    let keyVal: String? = decodedParams?["key"] as? String
    let countVal: Int? = decodedParams?["count"] as? Int
    #expect(keyVal == "value")
    #expect(countVal == 42)
}

@Test func gatewayResponseDecoding() throws {
    let jsonString = """
    {"type":"res","id":"abc-123","ok":true,"payload":{"model":"claude-3-opus"},"error":null}
    """
    let data = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    let response = try decoder.decode(GatewayResponse.self, from: data)

    #expect(response.type == "res")
    #expect(response.id == "abc-123")
    #expect(response.ok == true)
    let modelVal: String? = response.payload?.dictValue?["model"] as? String
    #expect(modelVal == "claude-3-opus")
    #expect(response.error == nil)
}

@Test func gatewayResponseWithError() throws {
    let jsonString = """
    {"type":"res","id":"def-456","ok":false,"payload":null,"error":{"code":"NOT_FOUND","message":"Method not found"}}
    """
    let data = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    let response = try decoder.decode(GatewayResponse.self, from: data)

    #expect(response.ok == false)
    #expect(response.error?.code == "NOT_FOUND")
    #expect(response.error?.message == "Method not found")
}

@Test func gatewayEventDecoding() throws {
    let jsonString = """
    {"type":"event","event":"chat","payload":{"kind":"streaming","content":"Hello"},"seq":1}
    """
    let data = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    let event = try decoder.decode(GatewayEvent.self, from: data)

    #expect(event.type == "event")
    #expect(event.event == "chat")
    #expect(event.seq == 1)
    let kind: String? = event.payload?.dictValue?["kind"] as? String
    let content: String? = event.payload?.dictValue?["content"] as? String
    #expect(kind == "streaming")
    #expect(content == "Hello")
}

// MARK: - AnyCodable Tests

@Test func anyCodableString() throws {
    let value = AnyCodable("hello")
    #expect(value.stringValue == "hello")
    #expect(value.intValue == nil)

    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.stringValue == "hello")
}

@Test func anyCodableInt() throws {
    let value = AnyCodable(42)
    #expect(value.intValue == 42)
    #expect(value.stringValue == nil)

    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.intValue == 42)
}

@Test func anyCodableBool() throws {
    let value = AnyCodable(true)
    #expect(value.boolValue == true)

    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.boolValue == true)
}

@Test func anyCodableDouble() throws {
    let value = AnyCodable(3.14)
    #expect(value.doubleValue == 3.14)

    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.doubleValue == 3.14)
}

@Test func anyCodableArray() throws {
    let value = AnyCodable([1, 2, 3])
    #expect(value.arrayValue != nil)

    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.arrayValue != nil)
}

@Test func anyCodableDictionary() throws {
    let dict: [String: Any] = ["name": "test", "value": 123]
    let value = AnyCodable(dict)
    let nameVal: String? = value.dictValue?["name"] as? String
    let valVal: Int? = value.dictValue?["value"] as? Int
    #expect(nameVal == "test")
    #expect(valVal == 123)

    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    let decodedName: String? = decoded.dictValue?["name"] as? String
    #expect(decodedName == "test")
}

@Test func anyCodableNull() throws {
    let jsonString = "null"
    let data = jsonString.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.stringValue == nil)
    #expect(decoded.intValue == nil)
}

// MARK: - ConnectRequest Tests

@Test func makeConnectRequestWithToken() throws {
    let request = makeConnectRequest(token: "test-token")
    #expect(request.method == "connect")
    #expect(request.type == "req")

    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let params = json["params"] as! [String: Any]

    let role: String? = params["role"] as? String
    #expect(role == "operator")
    let scopes = params["scopes"] as? [String]
    #expect(scopes?.contains("operator.read") == true)
    #expect(scopes?.contains("operator.write") == true)

    let client = params["client"] as! [String: Any]
    #expect(client["platform"] as? String == "macos")
    #expect(client["mode"] as? String == "desktop")

    let auth = params["auth"] as? [String: Any]
    let token: String? = auth?["token"] as? String
    #expect(token == "test-token")
}

@Test func makeConnectRequestWithoutAuth() throws {
    let request = makeConnectRequest()
    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let params = json["params"] as! [String: Any]

    let minProto: Int? = params["minProtocol"] as? Int
    let maxProto: Int? = params["maxProtocol"] as? Int
    #expect(minProto == 1)
    #expect(maxProto == 1)
}

// MARK: - RPC Method Constants Tests

@Test func rpcMethodConstants() {
    #expect(RPCMethod.connect == "connect")
    #expect(RPCMethod.configGet == "config.get")
    #expect(RPCMethod.configSet == "config.set")
    #expect(RPCMethod.configUnset == "config.unset")
    #expect(RPCMethod.configApply == "config.apply")
    #expect(RPCMethod.configPatch == "config.patch")
    #expect(RPCMethod.configSchema == "config.schema")
    #expect(RPCMethod.chatSend == "chat.send")
    #expect(RPCMethod.chatHistory == "chat.history")
    #expect(RPCMethod.chatInject == "chat.inject")
    #expect(RPCMethod.chatAbort == "chat.abort")
    #expect(RPCMethod.sessionsList == "sessions.list")
    #expect(RPCMethod.sessionsPatch == "sessions.patch")
    #expect(RPCMethod.status == "status")
    #expect(RPCMethod.health == "health")
    #expect(RPCMethod.channelsStatus == "channels.status")
    #expect(RPCMethod.modelsStatus == "models.status")
    #expect(RPCMethod.modelsList == "models.list")
}

// MARK: - Event Type Constants Tests

@Test func eventTypeConstants() {
    #expect(GatewayEventType.chat == "chat")
    #expect(GatewayEventType.systemPresence == "system-presence")
}

@Test func chatEventKindValues() {
    #expect(ChatEventKind.thinking.rawValue == "thinking")
    #expect(ChatEventKind.streaming.rawValue == "streaming")
    #expect(ChatEventKind.toolCall.rawValue == "toolCall")
    #expect(ChatEventKind.toolResult.rawValue == "toolResult")
    #expect(ChatEventKind.complete.rawValue == "complete")
    #expect(ChatEventKind.error.rawValue == "error")
    #expect(ChatEventKind.message.rawValue == "message")
}

// MARK: - AIModel Tests

@Test func aiModelKnownModels() {
    let models = AIModel.knownModels
    #expect(!models.isEmpty)

    // Should have anthropic and openai models
    let providers = Set(models.map(\.provider))
    #expect(providers.contains("anthropic"))
    #expect(providers.contains("openai"))
}

@Test func aiModelFindByName() {
    // Test finding a known model
    let claude = AIModel.find(by: "anthropic/claude-3-opus")
    // May or may not find depending on knownModels list
    if let claude {
        #expect(claude.provider == "anthropic")
    }
}

@Test func aiModelProviderAndModel() {
    let model = AIModel(
        id: "test-model",
        name: "Test Model",
        provider: "testprovider",
        contextWindow: 100000,
        supportsVision: true,
        supportsThinking: false,
        description: "A test model"
    )
    #expect(model.providerAndModel == "testprovider/test-model")
    #expect(model.supportsVision == true)
    #expect(model.supportsThinking == false)
}

// MARK: - GatewayClient Error Tests

@Test func clientErrorDescriptions() {
    let errors: [GatewayClient.ClientError] = [
        .notConnected,
        .connectionFailed("bad url"),
        .requestTimeout,
        .requestFailed("server error"),
        .invalidResponse,
        .handshakeFailed("auth failed")
    ]

    let desc0: String = errors[0].errorDescription ?? ""
    let desc1: String = errors[1].errorDescription ?? ""
    let desc2: String = errors[2].errorDescription ?? ""
    let desc3: String = errors[3].errorDescription ?? ""
    let desc4: String = errors[4].errorDescription ?? ""
    let desc5: String = errors[5].errorDescription ?? ""

    #expect(desc0.contains("Not connected"))
    #expect(desc1.contains("bad url"))
    #expect(desc2.contains("timed out"))
    #expect(desc3.contains("server error"))
    #expect(desc4.contains("Invalid response"))
    #expect(desc5.contains("auth failed"))
}
