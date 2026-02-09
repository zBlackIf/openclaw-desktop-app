import Foundation

@MainActor
final class ModelProviderService: Sendable {
    nonisolated let gateway: GatewayClient

    init(gateway: GatewayClient) {
        self.gateway = gateway
    }

    func getProviders() async throws -> [ModelProvider] {
        let response = try await gateway.send(method: RPCMethod.modelsList)
        guard response.ok, let payload = response.payload,
              let providersData = payload.arrayValue else {
            // Return default providers if gateway doesn't support this method
            return defaultProviders()
        }

        return providersData.compactMap { provDict -> ModelProvider? in
            guard let dict = provDict as? [String: Any] else { return nil }
            let providerId = dict["id"] as? String ?? ""
            // Try to get models from gateway response, fall back to known models for this provider
            let models = AIModel.knownModels.filter { $0.provider == providerId }
            return ModelProvider(
                id: providerId,
                name: dict["name"] as? String ?? providerId.capitalized,
                models: models,
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
