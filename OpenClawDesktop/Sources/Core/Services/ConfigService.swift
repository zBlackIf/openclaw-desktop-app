import Foundation

@MainActor
final class ConfigService: Sendable {
    nonisolated let gateway: GatewayClient

    init(gateway: GatewayClient) {
        self.gateway = gateway
    }

    func getConfig() async throws -> OpenClawConfig? {
        let response = try await gateway.send(method: RPCMethod.configGet)
        guard response.ok, let payload = response.payload else { return nil }

        // Decode the payload into OpenClawConfig
        let data = try JSONSerialization.data(withJSONObject: payload.value)
        return try JSONDecoder().decode(OpenClawConfig.self, from: data)
    }

    func patchConfig(_ patch: [String: Any]) async throws {
        // Serialize to JSON data on MainActor, then send as Sendable data
        let jsonData = try JSONSerialization.data(withJSONObject: patch)
        let response = try await gateway.sendJSON(method: RPCMethod.configPatch, jsonData: jsonData)
        if !response.ok {
            throw GatewayClient.ClientError.requestFailed(
                response.error?.message ?? "Config patch failed"
            )
        }
    }

    func setModel(_ model: String) async throws {
        try await patchConfig([
            "agent": ["model": model]
        ])
    }

    func setThinkingLevel(_ level: String) async throws {
        try await patchConfig([
            "agent": ["thinking": ["level": level]]
        ])
    }

    func setChannelConfig(channel: String, config: [String: Any]) async throws {
        try await patchConfig([
            "channels": [channel: config]
        ])
    }

    func applyFullConfig(_ config: [String: Any]) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: config)
        let response = try await gateway.sendJSON(method: RPCMethod.configApply, jsonData: jsonData)
        if !response.ok {
            throw GatewayClient.ClientError.requestFailed(
                response.error?.message ?? "Config apply failed"
            )
        }
    }
}
