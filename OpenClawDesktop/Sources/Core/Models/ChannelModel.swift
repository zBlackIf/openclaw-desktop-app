import Foundation

struct Channel: Identifiable {
    let id: String
    let type: ChannelType
    var status: ChannelStatus
    var config: ChannelConfig?
    var connectedAccounts: [String]
    var lastActivity: Date?

    enum ChannelType: String, CaseIterable, Identifiable {
        case whatsapp = "WhatsApp"
        case telegram = "Telegram"
        case discord = "Discord"
        case slack = "Slack"
        case signal = "Signal"
        case imessage = "iMessage"
        case teams = "Microsoft Teams"
        case matrix = "Matrix"
        case webchat = "WebChat"
        case googleChat = "Google Chat"
        case zalo = "Zalo"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .whatsapp: return "message.fill"
            case .telegram: return "paperplane.fill"
            case .discord: return "gamecontroller.fill"
            case .slack: return "number"
            case .signal: return "lock.shield.fill"
            case .imessage: return "message.badge.fill"
            case .teams: return "person.3.fill"
            case .matrix: return "square.grid.3x3.fill"
            case .webchat: return "globe"
            case .googleChat: return "bubble.left.and.text.bubble.right.fill"
            case .zalo: return "ellipsis.message.fill"
            }
        }

        var color: String {
            switch self {
            case .whatsapp: return "green"
            case .telegram: return "blue"
            case .discord: return "indigo"
            case .slack: return "purple"
            case .signal: return "blue"
            case .imessage: return "green"
            case .teams: return "purple"
            case .matrix: return "teal"
            case .webchat: return "orange"
            case .googleChat: return "green"
            case .zalo: return "blue"
            }
        }

        var setupSteps: [SetupStep] {
            switch self {
            case .whatsapp:
                return [
                    SetupStep(title: "Install WhatsApp Bridge", description: "OpenClaw uses a WhatsApp bridge to connect. The gateway handles this automatically."),
                    SetupStep(title: "Scan QR Code", description: "A QR code will appear. Scan it with WhatsApp on your phone (Settings > Linked Devices > Link a Device)."),
                    SetupStep(title: "Configure Access", description: "Set which phone numbers are allowed to interact with your assistant."),
                    SetupStep(title: "Test Connection", description: "Send a test message to verify the connection works.")
                ]
            case .telegram:
                return [
                    SetupStep(title: "Create Bot", description: "Talk to @BotFather on Telegram and create a new bot. Copy the bot token."),
                    SetupStep(title: "Enter Bot Token", description: "Paste your bot token here to connect."),
                    SetupStep(title: "Configure Permissions", description: "Set who can interact with your bot."),
                    SetupStep(title: "Test Connection", description: "Send /start to your bot on Telegram.")
                ]
            case .discord:
                return [
                    SetupStep(title: "Create Discord App", description: "Go to the Discord Developer Portal and create a new application."),
                    SetupStep(title: "Create Bot", description: "In your app settings, create a bot and copy the token."),
                    SetupStep(title: "Set Permissions", description: "Configure bot permissions and intents (Message Content, Guild Members)."),
                    SetupStep(title: "Invite Bot", description: "Generate an invite link and add the bot to your server."),
                    SetupStep(title: "Enter Token", description: "Paste the bot token here."),
                    SetupStep(title: "Test Connection", description: "Send a message in your Discord server to test.")
                ]
            case .slack:
                return [
                    SetupStep(title: "Create Slack App", description: "Go to api.slack.com/apps and create a new app."),
                    SetupStep(title: "Configure OAuth", description: "Set up OAuth scopes and install the app to your workspace."),
                    SetupStep(title: "Enter Credentials", description: "Paste your bot token and signing secret."),
                    SetupStep(title: "Test Connection", description: "Mention your bot in a Slack channel to test.")
                ]
            default:
                return [
                    SetupStep(title: "Configure Channel", description: "Follow the OpenClaw documentation to set up this channel."),
                    SetupStep(title: "Test Connection", description: "Send a test message to verify.")
                ]
            }
        }
    }

    enum ChannelStatus: String {
        case connected
        case disconnected
        case connecting
        case error
        case pairing
    }
}

struct SetupStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    var isCompleted: Bool = false
    var inputFields: [SetupField]?
}

struct SetupField: Identifiable {
    let id = UUID()
    let label: String
    let placeholder: String
    let isSecure: Bool
    var value: String = ""
}
