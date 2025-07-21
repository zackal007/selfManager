//
//  Asset.swift
//  selfManager
//
//  Created by AI Assistant on 2024
//

import Foundation
import SwiftData

@Model
final class Asset {
    var id: UUID
    var cashAmount: Double
    var debtAmount: Double
    var otherAmount: Double
    var lastUpdateDate: Date
    
    var totalAssets: Double {
        cashAmount + otherAmount - debtAmount
    }
    
    init(cashAmount: Double = 10.0, debtAmount: Double = 5.0, otherAmount: Double = 8.0) {
        self.id = UUID()
        self.cashAmount = cashAmount
        self.debtAmount = debtAmount
        self.otherAmount = otherAmount
        self.lastUpdateDate = Date()
    }
}