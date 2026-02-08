import Foundation

@MainActor
final class ModelProviderService: Sendable {
    nonisolated let gateway: GatewayClient

    init(gateway: GatewayClient) {
        self.gateway = gateway
    }

    func getProviders() async throws -> [ModelProvider] {
        let response = try await gateway.send(method: RPCMethod.modelsProviders)
        guard response.ok, let payload = response.payload,
              let providersData = payload.arrayValue else {
            // Return default providers if gateway doesn't support this method
            return defaultProviders()
        }

        return providersData.compactMap { provDict -> ModelProvider? in
            guard let dict = provDict as? [String: Any] else { return nil }
            return ModelProvider(
                id: dict["id"] as? String ?? "",
                name: dict["name"] as? String ?? "",
                models: [],
                isAuthenticated: dict["authenticated"] as? Bool ?? false,
                status: ModelProvider.ProviderStatus(rawValue: dict["status"] as? String ?? "inactive") ?? .inactive
            )
        }
    }

    func getModelStatus() async throws -> (model: String, provider: String) {
        let response = try await gateway.send(method: RPCMethod.modelsStatus)
        guard response.ok, let payload = response.payload,
              let dict = payload.dictValue else {
            return ("unknown", "unknown")
        }
        return (
            model: dict["model"] as? String ?? "unknown",
            provider: dict["provider"] as? String ?? "unknown"
        )
    }

    private func defaultProviders() -> [ModelProvider] {
        [
            ModelProvider(
                id: "anthropic",
                name: "Anthropic",
                models: AIModel.knownModels.filter { $0.provider == "anthropic" },
                isAuthenticated: false,
                status: .inactive
            ),
            ModelProvider(
                id: "openai",
                name: "OpenAI",
                models: AIModel.knownModels.filter { $0.provider == "openai" },
                isAuthenticated: false,
                status: .inactive
            )
        ]
    }
}
