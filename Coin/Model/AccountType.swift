import Foundation

enum AccountType: String, Codable, CaseIterable {
    case expense, earnings, debt, regular, balancing
}
