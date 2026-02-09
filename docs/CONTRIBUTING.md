# Contributing to OpenClaw Desktop App

## For AI Agents

This project is designed to be easily understood and extended by AI agents. Key reference documents:

1. **`docs/PRD.md`** - What the app should do (features, requirements, user stories)
2. **`docs/ARCHITECTURE.md`** - How the app is built (layers, data flow, concurrency)
3. **`docs/DESIGN_SYSTEM.md`** - How the app looks (colors, typography, components, layouts)
4. **`docs/CHANGELOG.md`** - What has changed

### Architecture Quick Reference

- **Pattern**: MVVM + Service Layer
- **Concurrency**: Swift 6 strict concurrency. GatewayClient is an Actor. Services and ViewModels are @MainActor.
- **State**: @Observable (Observation framework). Global state via AppState in SwiftUI Environment.
- **WebSocket**: URLSessionWebSocketTask (no dependencies)
- **Build**: `swift build` via Swift Package Manager

### Adding a New Feature

1. Create View in `Sources/Features/YourFeature/`
2. Create ViewModel (annotate with `@MainActor @Observable`)
3. Add Service methods if needed (in `Sources/Core/Services/`)
4. Add RPC method constants to `GatewayProtocol.swift` if using new Gateway methods
5. Add navigation item to `AppState.NavigationItem` if it's a top-level section
6. Update the detail view switch in `ContentView.swift`
7. Update documentation

### Key Rules

- All data crossing actor boundaries must be `Sendable`. Use `Data` serialization for `[String: Any]` types.
- ViewModels must be `@MainActor @Observable`
- Services must be `@MainActor` with `nonisolated let gateway: GatewayClient`
- Use `sending` parameter annotation for actor method params when needed
- Zero external dependencies policy - use Foundation/SwiftUI only

## For Humans

### Prerequisites

- macOS 14+ (Sonoma)
- Xcode 15+ or Swift 5.9+
- OpenClaw installed and Gateway running for testing

### Building

```bash
cd OpenClawDesktop
swift build
```

### Running

Open the generated `.app` in Xcode or run via:
```bash
swift run OpenClawDesktop
```

### Testing

```bash
swift test
```

Currently 23 unit tests covering:
- AppState initialization and error display
- GatewayProtocol encoding/decoding (requests, responses, events)
- AnyCodable round-trip encoding (string, int, bool, double, array, dictionary, null)
- ConnectRequest generation (with/without auth)
- RPC method constants validation
- Event type and ChatEventKind constants
- AIModel data model
- GatewayClient error descriptions

### Gateway API Reference

**RPC Methods** (used in `RPCMethod` constants):
| Method | Description |
|--------|-------------|
| `connect` | Handshake with protocol version, client metadata, auth |
| `config.get/set/unset/patch/apply/schema` | Configuration management |
| `chat.send/history/inject/abort` | Chat messaging and agent control |
| `sessions.list/patch` | Session management |
| `channels.status` | Channel status |
| `models.status/list` | Model information |
| `status/health` | System status |

**Events**:
- `chat` - Primary event carrying all streaming data (sub-types: thinking, streaming, toolCall, toolResult, complete, error)
- `system-presence` - Instance availability tracking

**Session Commands** (sent as chat messages):
- `/new` - Create new session
- `/reset` - Reset session history
- `/compact` - Compact session history
- `/status` - Session status

### Manual Testing with Real Gateway

To test the app against a running OpenClaw Gateway:

1. **Start OpenClaw Gateway**:
   ```bash
   openclaw start
   ```
   The Gateway should be running at `ws://127.0.0.1:18789`.

2. **Launch the app**:
   ```bash
   cd OpenClawDesktop && swift run OpenClawDesktop
   ```

3. **Verify connection**: The sidebar should show a green status dot with "Connected". If it fails, check Settings to verify the Gateway URL and auth token.

4. **Test checklist**:
   - [ ] App auto-connects on launch (if auto-connect is enabled in Settings)
   - [ ] Send a chat message and see streaming response
   - [ ] Agent thinking appears in Agent Monitor > Thinking tab
   - [ ] Tool calls appear in Agent Monitor > Tools tab
   - [ ] Abort agent with the stop button during a running response
   - [ ] Switch sessions via the session picker in Chat header
   - [ ] Create a new session via Sessions > "+" button
   - [ ] Reset / Compact session via Sessions detail buttons
   - [ ] Switch models via Models view
   - [ ] View channel status in Channels view
   - [ ] Disconnect and reconnect via Settings
   - [ ] Error banner appears on failed operations and auto-dismisses after 5 seconds
