import Foundation

extension DateFormatter {
    static var postFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
     return formatter
    }()
}

