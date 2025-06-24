//
//  Item.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
