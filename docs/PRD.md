# OpenClaw Desktop App - Product Requirements Document

## Overview

OpenClaw Desktop is a native macOS application that provides a user-friendly interface for [OpenClaw](https://github.com/openclaw/openclaw), a self-hosted AI assistant platform. It connects to the OpenClaw Gateway via WebSocket and eliminates the need for manual JSON configuration, exposing all key features through an intuitive GUI.

## Problem Statement

OpenClaw is powerful but has significant UX barriers for non-technical users:

1. **Model configuration** requires editing `~/.openclaw/openclaw.json` manually; switching models is confusing; no visibility into current model or usage
2. **Agent thinking/planning** is invisible; users cannot see the agent's reasoning or execution path, nor pause or modify plans
3. **Channel configuration** (WhatsApp, Telegram, Discord, etc.) is complex and error-prone
4. **Sub-agent management** is opaque and uncontrollable

## User Personas

### Beginner User
- Non-technical, uses OpenClaw as a personal assistant
- Wants simple setup and clear visibility into what the AI is doing
- Needs guided wizards for configuration
- May not understand model differences but wants to pick the "best" one

### Power User
- Technical, may run multiple channels and sessions
- Wants quick model switching and usage monitoring
- Needs fine-grained control over agent execution
- Values keyboard shortcuts and efficiency

## Features

### F1: Model Configuration UI (Pain Point #1)

**Goal**: Visual model selection and management without JSON editing.

| ID | Requirement | Priority |
|----|-------------|----------|
| F1.1 | Display current model prominently in toolbar | P0 |
| F1.2 | One-click model switching from visual picker | P0 |
| F1.3 | Group models by provider (Anthropic, OpenAI) | P0 |
| F1.4 | Show model capabilities (context window, vision, thinking) | P1 |
| F1.5 | Provider authentication status indicators | P1 |
| F1.6 | Token usage dashboard per session | P2 |
| F1.7 | Cost estimation for API key users | P3 |
| F1.8 | Model failover chain configuration | P2 |

### F2: Agent Thinking Visualization (Pain Point #2)

**Goal**: Make agent reasoning transparent and controllable.

| ID | Requirement | Priority |
|----|-------------|----------|
| F2.1 | Real-time display of agent thinking blocks | P0 |
| F2.2 | Collapsible thought sections with timestamps | P0 |
| F2.3 | Plan tree/timeline view with step status | P0 |
| F2.4 | Pause/resume agent execution | P0 |
| F2.5 | Cancel agent run | P0 |
| F2.6 | Inject context mid-execution via chat.inject | P1 |
| F2.7 | Tool call visualization with input/output | P1 |
| F2.8 | Sub-agent list with status and controls | P1 |
| F2.9 | Edit upcoming plan steps before execution | P2 |

### F3: Channel Setup Wizard (Pain Point #3)

**Goal**: Guided, step-by-step channel configuration.

| ID | Requirement | Priority |
|----|-------------|----------|
| F3.1 | Channel overview with status indicators | P0 |
| F3.2 | Step-by-step wizard per channel type | P0 |
| F3.3 | WhatsApp QR code pairing flow | P0 |
| F3.4 | Telegram bot token setup | P0 |
| F3.5 | Discord bot creation guide | P1 |
| F3.6 | Slack workspace app installation | P1 |
| F3.7 | Per-channel settings (allowlists, mentions, security) | P1 |
| F3.8 | Test connection at each setup stage | P1 |
| F3.9 | Visual routing rule editor | P2 |

### F4: Chat Interface

**Goal**: Rich conversation UI with streaming support.

| ID | Requirement | Priority |
|----|-------------|----------|
| F4.1 | Message display with markdown and code blocks | P0 |
| F4.2 | Real-time streaming of agent responses | P0 |
| F4.3 | Session switching | P0 |
| F4.4 | Current model indicator in chat header | P0 |
| F4.5 | Thinking/typing indicator | P1 |
| F4.6 | Tool call details in messages | P2 |

### F5: Gateway Connection

| ID | Requirement | Priority |
|----|-------------|----------|
| F5.1 | Connect to Gateway via WebSocket | P0 |
| F5.2 | Auto-reconnect with exponential backoff | P0 |
| F5.3 | Connection status indicator | P0 |
| F5.4 | Menu bar status item | P1 |
| F5.5 | Onboarding wizard for first connection | P2 |

## Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR1 | macOS 14+ (Sonoma) support |
| NFR2 | Native SwiftUI for platform-consistent UX |
| NFR3 | Light and dark mode support |
| NFR4 | Keyboard shortcuts for common actions |
| NFR5 | < 50MB app bundle size |
| NFR6 | No third-party dependencies for core features |

## Information Architecture

```
App Window
├── Sidebar Navigation
│   ├── Chat (default)
│   ├── Agent Monitor
│   ├── Models
│   ├── Channels
│   ├── Sessions
│   └── Settings
├── Toolbar
│   ├── Connection Status
│   └── Current Model Badge
└── Menu Bar Extra
    ├── Connection Status
    ├── Current Model
    ├── Quick Actions
    └── Quit
```

## Success Metrics

- User can switch models without editing JSON
- User can see agent thinking in real-time
- User can set up a new channel through the wizard
- User can pause/cancel agent execution
- App connects to Gateway within 2 seconds on local network
