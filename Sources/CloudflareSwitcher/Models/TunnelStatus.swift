import SwiftUI

public enum TunnelStatus: Equatable, Sendable {
    case stopped
    case starting
    case running
    case stopping
    case missingBinary
    case error(String)

    public var title: String {
        switch self {
        case .stopped:
            return "Disconnected"
        case .starting:
            return "Connecting..."
        case .running:
            return "Active (Connected)"
        case .stopping:
            return "Disconnecting..."
        case .missingBinary:
            return "cloudflared not found"
        case .error(let msg):
            return "Error: \(msg)"
        }
    }

    public var iconName: String {
        switch self {
        case .stopped:
            return "bolt.slash.fill"
        case .starting, .stopping:
            return "arrow.triangle.2.circlepath"
        case .running:
            return "bolt.fill"
        case .missingBinary:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    public var color: Color {
        switch self {
        case .stopped:
            return .secondary
        case .starting, .stopping:
            return .orange
        case .running:
            return .green
        case .missingBinary:
            return .yellow
        case .error:
            return .red
        }
    }

    public var isBusy: Bool {
        switch self {
        case .starting, .stopping:
            return true
        default:
            return false
        }
    }

    public var isConnected: Bool {
        if case .running = self { return true }
        return false
    }
}
