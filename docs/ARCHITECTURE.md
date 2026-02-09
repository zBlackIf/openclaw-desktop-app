# OpenClaw Desktop App - Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────┐
│              OpenClaw Desktop App                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Views    │  │ ViewModels│  │ Services │      │
│  │ (SwiftUI)│──│(@Observable)│──│  Layer  │      │
│  └──────────┘  └──────────┘  └──────────┘      │
│                                    │             │
│                          ┌─────────┴──────────┐  │
│                          │   GatewayClient     │  │
│                          │   (Swift Actor)     │  │
│                          └─────────┬──────────┘  │
└────────────────────────────────────┼─────────────┘
                                     │ WebSocket
                           ┌─────────┴──────────┐
                           │  OpenClaw Gateway   │
                           │  ws://127.0.0.1:    │
                           │     18789           │
                           └─────────┬──────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
       ┌──────┴──────┐       ┌──────┴──────┐       ┌──────┴──────┐
       │  Pi Agent    │       │  Channels   │       │   Tools     │
       │  Runtime     │       │  (WA/TG/    │       │  (Browser,  │
       │              │       │   Discord)  │       │   Cron...)  │
       └─────────────┘       └─────────────┘       └─────────────┘
```

## Architecture Pattern

**MVVM + Service Layer** with Swift Actors for concurrency safety.

```
View (SwiftUI) → ViewModel (@Observable, @MainActor) → Service (@MainActor) → GatewayClient (Actor)
```

### Layer Responsibilities

| Layer | Responsibility | Isolation |
|-------|---------------|-----------|
| **View** | UI rendering, user interaction | MainActor (implicit) |
| **ViewModel** | UI state, business logic | @MainActor |
| **Service** | Domain operations, data transformation | @MainActor |
| **GatewayClient** | WebSocket I/O, message routing | Actor (isolated) |

## Core Components

### GatewayClient (`Core/Gateway/GatewayClient.swift`)

A Swift Actor managing the WebSocket connection to the OpenClaw Gateway.

**Responsibilities**:
- WebSocket lifecycle (connect, disconnect, reconnect)
- Request/response correlation via message IDs
- Event streaming via `AsyncStream<GatewayEvent>`
- Automatic reconnection with exponential backoff

**Protocol**:
```
Request:  { type: "req",   id, method, params }
Response: { type: "res",   id, ok, payload|error }
Event:    { type: "event", event, payload, seq?, stateVersion? }
```

**Key RPC Methods** (aligned with real OpenClaw Gateway API):
- `config.get` / `config.set` / `config.unset` / `config.patch` / `config.apply` / `config.schema` - Configuration
- `chat.send` / `chat.history` / `chat.inject` / `chat.abort` - Messaging & agent control
- `sessions.list` / `sessions.patch` - Sessions
- `channels.status` - Channels
- `models.status` / `models.list` - Models
- `status` / `health` - System status

### GatewayEventBus (`Core/Gateway/GatewayEventBus.swift`)

Observable event processor that transforms raw Gateway events into structured UI state.

**Event Processing**: The Gateway sends a single `chat` event for all streaming data. The EventBus parses the payload's `kind` field to determine the sub-type:
- `thinking` - Agent reasoning/thinking text
- `streaming` - Token-by-token text output
- `toolCall` - Tool invocation start
- `toolResult` - Tool invocation result
- `complete` - Agent finished
- `error` - Agent error

Also handles `system-presence` events for instance availability.

**Tracked State**:
- `currentThinking` - Live thinking text
- `thinkingHistory` - All thinking blocks with timestamps
- `currentPlan` - Execution plan steps with status
- `activeToolCalls` - In-progress and completed tool calls
- `subAgents` - Spawned sub-agents with status
- `streamingContent` - Current streaming text accumulator

### AppState (`App/AppState.swift`)

Global application state injected via SwiftUI Environment.

**Contains**:
- Navigation state
- Connection status
- Current model info
- Service instances (ConfigService, SessionService)
- GatewayClient instance

## Data Flow

### Message Sending
```
User types message
  → ChatView.onSend()
  → ChatViewModel.sendMessage()
  → SessionService.sendMessage()
  → GatewayClient.send("chat.send", params)
  → WebSocket frame to Gateway
```

### Event Receiving
```
Gateway emits event
  → WebSocket frame received
  → GatewayClient.handleMessage()
  → GatewayClient.eventContinuations.yield(event)
  → GatewayEventBus.processEvent() [MainActor]
  → @Observable properties update
  → SwiftUI views re-render
```

### Config Updates
```
User selects new model
  → ModelConfigView button tap
  → ModelConfigViewModel.switchModel()
  → ConfigService.setModel()
  → ConfigService.patchConfig() → serialize to JSON Data
  → GatewayClient.sendJSON() → deserialize on actor
  → Gateway applies config.patch
  → AppState.currentModel updated
```

## Concurrency Model

- **GatewayClient**: Swift Actor - ensures thread-safe WebSocket operations
- **Services**: @MainActor - safe to access from UI, call actor methods via await
- **ViewModels**: @MainActor @Observable - drive UI updates
- **Data crossing actor boundary**: Serialized to `Data` (Sendable) before crossing

## File Structure

```
OpenClawDesktop/
├── Sources/
│   ├── App/                    # App entry, global state, navigation
│   ├── Core/
│   │   ├── Gateway/            # WebSocket client, protocol, event bus
│   │   ├── Models/             # Data models (Agent, Session, Channel, Config)
│   │   └── Services/           # Business logic services
│   ├── Features/
│   │   ├── Chat/               # Chat UI and message handling
│   │   ├── ModelConfig/        # Model selection and usage
│   │   ├── AgentMonitor/       # Thinking viz, plan tree, sub-agents
│   │   ├── Channels/           # Channel list and setup wizard
│   │   ├── Sessions/           # Session list and detail
│   │   └── Settings/           # App settings and connection
│   └── Components/             # Reusable UI components
├── Tests/
├── docs/
└── Package.swift
```

## Dependencies

**Zero external dependencies**. Uses only:
- SwiftUI (UI framework)
- Foundation (networking, JSON, concurrency)
- URLSessionWebSocketTask (WebSocket)
- Observation framework (state management)

## Build System

Swift Package Manager (`Package.swift`) targeting macOS 14+.

```bash
swift build          # Debug build
swift build -c release  # Release build
swift test           # Run tests
```
