import SwiftUI

enum ReadingTheme: String, CaseIterable, Identifiable {
    case white, sepia, dark, black, claudeWeb, claudeCode

    var id: String { rawValue }

    var background: Color {
        switch self {
        case .white:      return .white
        case .sepia:      return Color(red: 0.97,  green: 0.93,  blue: 0.82)
        case .dark:       return Color(red: 0.13,  green: 0.13,  blue: 0.15)
        case .black:      return .black
        case .claudeWeb:  return Color(red: 0.980, green: 0.973, blue: 0.961)
        case .claudeCode: return Color(red: 0.112, green: 0.112, blue: 0.130)
        }
    }

    var text: Color {
        switch self {
        case .white:      return Color(white: 0.10)
        case .sepia:      return Color(red: 0.22,  green: 0.15,  blue: 0.05)
        case .dark, .black: return Color(white: 0.88)
        case .claudeWeb:  return Color(red: 0.13,  green: 0.10,  blue: 0.08)
        case .claudeCode: return Color(red: 0.918, green: 0.902, blue: 0.878)
        }
    }

    var secondaryText: Color {
        switch self {
        case .white:      return Color(white: 0.45)
        case .sepia:      return Color(red: 0.50,  green: 0.38,  blue: 0.18)
        case .dark, .black: return Color(white: 0.48)
        case .claudeWeb:  return Color(red: 0.48,  green: 0.38,  blue: 0.28)
        case .claudeCode: return Color(red: 0.824, green: 0.467, blue: 0.325)
        }
    }

    var separator: Color {
        switch self {
        case .white:      return Color(white: 0.82)
        case .sepia:      return Color(red: 0.72,  green: 0.65,  blue: 0.48)
        case .dark, .black: return Color(white: 0.22)
        case .claudeWeb:  return Color(red: 0.85,  green: 0.82,  blue: 0.77)
        case .claudeCode: return Color(red: 0.824, green: 0.467, blue: 0.325).opacity(0.4)
        }
    }

    var displayName: String {
        switch self {
        case .white:      return "Blanco"
        case .sepia:      return "Sepia"
        case .dark:       return "Oscuro"
        case .black:      return "Negro"
        case .claudeWeb:  return "Claude"
        case .claudeCode: return "Code"
        }
    }
}

enum ReadingFont: String, CaseIterable, Identifiable {
    case sans, serif, rounded, mono

    var id: String { rawValue }

    var design: Font.Design {
        switch self {
        case .sans:    return .default
        case .serif:   return .serif
        case .rounded: return .rounded
        case .mono:    return .monospaced
        }
    }

    var displayName: String {
        switch self {
        case .sans:    return "Sans-Serif"
        case .serif:   return "Serif"
        case .rounded: return "Redondeada"
        case .mono:    return "Monoespaciada"
        }
    }
}
