import Foundation

enum ExportQuality: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case highest = "Highest"
    case ultra = "Ultra"
    
    var resolution: CGSize {
        switch self {
        case .low:
            return CGSize(width: 512, height: 512)
        case .medium:
            return CGSize(width: 1024, height: 1024)
        case .high:
            return CGSize(width: 2048, height: 2048)
        case .highest:
            return CGSize(width: 4096, height: 4096)
        case .ultra:
            return CGSize(width: 8192, height: 8192)
        }
    }
    
    var antiAliasing: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 4
        case .highest:
            return 8
        case .ultra:
            return 8
        }
    }
    
    var samplingQuality: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 4
        case .highest:
            return 8
        case .ultra:
            return 8
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}
