# OpenClaw Desktop App - Design System

## Design Principles

1. **Native First**: Follow macOS Human Interface Guidelines (HIG)
2. **Clarity**: Information hierarchy should be immediately clear
3. **Efficiency**: Power users should be able to accomplish tasks quickly
4. **Accessibility**: Support VoiceOver, keyboard navigation, and Dynamic Type

## Color System

### Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | System Blue | System Blue | Actions, links, selection |
| `success` | System Green | System Green | Connected, completed, active |
| `warning` | System Orange | System Orange | Connecting, pending |
| `error` | System Red | System Red | Errors, disconnected |
| `secondary` | .secondary | .secondary | Supplementary text |
| `tertiary` | .tertiary | .tertiary | Timestamps, metadata |

### Provider Colors

| Provider | Color | Usage |
|----------|-------|-------|
| Anthropic | Blue | Model cards, badges |
| OpenAI | Green | Model cards, badges |

### Status Colors

| Status | Color | Context |
|--------|-------|---------|
| Connected | Green | Gateway, channels |
| Connecting | Orange | Gateway, channels |
| Disconnected | Gray | Gateway, channels |
| Error | Red | Gateway, channels |
| Active (agent) | Blue | Agent monitor |
| Paused | Orange | Agent monitor |
| Completed | Green | Plan steps, tool calls |
| Failed | Red | Plan steps, tool calls |

## Typography

Uses system fonts for consistency with macOS:

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| Title | System | .title | .bold | Page headers |
| Title 2 | System | .title2 | .semibold | Section headers, cards |
| Headline | System | .headline | .semibold | Section titles |
| Subheadline | System | .subheadline | .medium | Card titles, labels |
| Body | System | .body | .regular | Message content, descriptions |
| Caption | System | .caption | .regular | Metadata, timestamps |
| Caption 2 | System | .caption2 | .regular | Fine print, token counts |
| Monospaced | .monospaced | .caption | .regular | Tool names, code, IDs |

## Component Library

### ConnectionIndicator
Status display showing Gateway connection state with animated pulse for connecting states.
```
[●] Connected    (green dot)
[◉] Connecting   (orange pulsing)
[●] Disconnected (gray dot)
[●] Error        (red dot)
```

### ModelBadge
Compact chip showing current model name with CPU icon.
```
[⎈ claude-opus-4-6]  (blue background)
```

### StatusBadge
Small capsule label for inline status indication.
```
[Active]    (green)
[Paused]    (orange)
[Connected] (green)
```

### EmptyStateView
Centered placeholder with icon, title, description, and optional action button. Used when no data is available.

### MessageBubble
Chat message display with role-based styling:
- User messages: Blue background, right-aligned
- Assistant messages: Control background, left-aligned
- System messages: Yellow background
- Tool messages: Purple background

### TypingIndicator
Three-dot animation indicating agent is processing.

## Layout Patterns

### Main Window
```
┌──────────────────────────────────────────────┐
│ Toolbar: [Connection] [Model Badge]          │
├────────┬─────────────────────────────────────┤
│        │                                     │
│ Side-  │         Detail View                 │
│ bar    │                                     │
│        │                                     │
│ Chat   │                                     │
│ Agent  │                                     │
│ Models │                                     │
│ Chan.  │                                     │
│ Sess.  │                                     │
│ Set.   │                                     │
│        │                                     │
├────────┤                                     │
│[●]Stat │                                     │
└────────┴─────────────────────────────────────┘
```

- Sidebar width: 180-260pt (min-ideal-max)
- NavigationSplitView for native sidebar behavior
- Status indicator at sidebar bottom

### Chat Layout
```
┌─────────────────────────────────────┐
│ Header: [Session Name] [Model] [⚙] │
├─────────────────────────────────────┤
│                                     │
│    [User bubble - right]            │
│ [Assistant bubble - left]           │
│    [User bubble - right]            │
│ [Assistant bubble - left]           │
│ [...typing indicator]               │
│                                     │
├─────────────────────────────────────┤
│ [Input field              ] [Send]  │
└─────────────────────────────────────┘
```

### Agent Monitor Layout
```
┌─────────────────────────────────────┐
│ [●Active] [⏸Pause] [⏹Stop] [🗑Clear]│
├─────────────────────────────────────┤
│ [Thinking|Plan|Tools|Sub-Agents]    │
├─────────────────────────────────────┤
│                                     │
│    Tab content area                 │
│                                     │
├─────────────────────────────────────┤
│ [💉 Inject context...      ] [Send] │
└─────────────────────────────────────┘
```

### Card Pattern
Used for model cards, channel cards, and info displays:
```
┌────────────────────────────┐
│ [Icon] Title      [Badge]  │
│ Description text           │
│ [capability] [capability]  │
└────────────────────────────┘
```
- Padding: 10-16pt
- Corner radius: 8-12pt
- Background: `.controlBackgroundColor`

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Inline spacing, icon gaps |
| sm | 8pt | Between related elements |
| md | 12pt | Between components |
| lg | 16pt | Section padding |
| xl | 24pt | Between sections |

## Interaction Patterns

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘Return | Send message |
| ⌘O | Open app from menu bar |
| ⌘Q | Quit |
| ⌘, | Settings |

### Animations

- Connection pulse: `easeInOut(duration: 1).repeatForever`
- View transitions: Default SwiftUI transitions
- Typing indicator: 0.5s timer-based dot animation

## Accessibility

- All interactive elements have `.help()` tooltips
- Status colors paired with icons (never color-only)
- Text content supports `.textSelection(.enabled)`
- Proper VoiceOver labels on status indicators
- Keyboard navigation through all interactive elements
