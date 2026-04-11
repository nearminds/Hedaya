import Foundation
import SwiftUI

/// A single Zikr (prayer/remembrance) with its Arabic text and recommended repetition count
struct Zikr: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let repetitions: Int
    let reference: String // Source/reference for the Zikr
}

/// A group of Azkar (e.g. Morning Azkar, Evening Azkar, Ad3ia). Id matches the group key in Data (e.g. "morning", "ad3ia_most_popular").
struct AzkarGroup: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let tags: [String]  // e.g. ["Ad3ia", "MostPopular"] for أدعية
    let azkar: [Zikr]
}

extension AzkarGroup {
    /// Gradient colors for this group's card and counter screen.
    var gradientColors: [Color] {
        switch color {
        case "morning":  return [Color(hex: "F39C12"), Color(hex: "F1C40F")]
        case "evening":  return [Color(hex: "2C3E50"), Color(hex: "3498DB")]
        case "prayer":   return [Color(hex: "1B7A4A"), Color(hex: "2ECC71")]
        case "sleep":    return [Color(hex: "8E44AD"), Color(hex: "9B59B6")]
        case "misc":     return [Color(hex: "E74C3C"), Color(hex: "E67E22")]
        case "ad3ia":    return [Color(hex: "0D7377"), Color(hex: "14A3B8")]
        default:         return [Color(hex: "1B7A4A"), Color(hex: "2ECC71")]
        }
    }
}
