//
//  Item.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 03/04/2026.
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
