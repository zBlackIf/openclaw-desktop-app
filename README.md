# OpenClaw Desktop App

A native macOS desktop application for [OpenClaw](https://github.com/openclaw/openclaw) that makes the self-hosted AI assistant accessible to everyone.

## What This Solves

OpenClaw is powerful but requires editing JSON config files, offers no visibility into agent reasoning, and has complex channel setup. This app provides:

- **Visual Model Configuration** - Switch models with one click, see usage stats
- **Agent Thinking Visualization** - See the agent's reasoning in real-time, pause/resume/cancel execution
- **Channel Setup Wizard** - Step-by-step guided setup for WhatsApp, Telegram, Discord, and more
- **Sub-Agent Control** - Monitor and manage spawned sub-agents

## Requirements

- macOS 14+ (Sonoma)
- [OpenClaw](https://github.com/openclaw/openclaw) installed with Gateway running
- Swift 5.9+ / Xcode 15+

## Quick Start

```bash
# Build
cd OpenClawDesktop
swift build

# Run
swift run OpenClawDesktop
```

The app will connect to the OpenClaw Gateway at `ws://127.0.0.1:18789` by default.

## Architecture

Native Swift + SwiftUI app connecting to the OpenClaw Gateway via WebSocket. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

```
Desktop App ←→ WebSocket ←→ OpenClaw Gateway ←→ AI Agent + Channels + Tools
```

## Documentation

| Document | Description |
|----------|-------------|
| [PRD](docs/PRD.md) | Product requirements and feature specs |
| [Architecture](docs/ARCHITECTURE.md) | Technical architecture and data flow |
| [Design System](docs/DESIGN_SYSTEM.md) | UI components, colors, typography |
| [Changelog](docs/CHANGELOG.md) | Version history |
| [Contributing](docs/CONTRIBUTING.md) | Development guide |

## License

MIT
