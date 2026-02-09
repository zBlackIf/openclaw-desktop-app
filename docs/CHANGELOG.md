# Changelog

## [0.2.0] - 2026-02-09

### Changed (API Alignment)
- Fixed Gateway handshake protocol to use proper `connect` method with protocol version, client metadata, role/scopes, and auth
- Aligned all RPC method names with real OpenClaw Gateway API (`chat.abort` instead of `agent.cancel`, `channels.status` instead of `channels.list`, `models.list` instead of `models.providers`)
- Rewrote event system from separate agent events to single `chat` event with kind-based dispatching (thinking, streaming, toolCall, toolResult, complete, error)
- Removed non-existent `agent.pause`/`agent.resume` RPC methods; replaced with `chat.abort` only

### Added
- Markdown rendering in chat messages with fenced code block support (syntax label, copy button)
- `MarkdownContentView` component using `AttributedString(markdown:)` for inline formatting
- `ErrorBannerView` with auto-dismiss for surfacing errors across all views
- Proper error handling in all views and services (replaced silent `catch {}` blocks)
- UserDefaults persistence for gateway URL, auth token, auto-connect, and last navigation item
- Session management: new session, reset, compact, patch session settings
- Session commands (`/new`, `/reset`, `/compact`) via `SessionService`
- 23 unit tests covering: AppState, GatewayProtocol encoding/decoding, AnyCodable round-trips, ConnectRequest, RPC method constants, event types, AIModel, GatewayClient errors

### Fixed
- `AnyCodable` encoding crash when auth is nil (no longer includes nil auth field in connect request)
- `SubAgentInfo.SubAgentStatus` no longer has `.paused` case (not supported by API)

## [0.1.0] - 2026-02-09

### Added
- Initial project scaffolding with Swift Package Manager
- Gateway WebSocket client (actor-based, auto-reconnect)
- Gateway protocol layer (request/response/event types)
- App shell with NavigationSplitView sidebar
- Chat interface with streaming message display
- Model Configuration UI with visual model picker
- Agent Monitor with thinking visualization and plan tree
- Sub-agent monitoring panel
- Channel list and setup wizard
- Session list and detail view
- Settings view with connection management
- Menu bar extra with connection status
- Reusable components (ConnectionIndicator, ModelBadge, StatusBadge, EmptyStateView)
- Core documentation (PRD, Architecture, Design System)
