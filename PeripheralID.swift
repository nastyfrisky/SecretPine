//
//  PeripheralID.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import Foundation

protocol PeripheralID: AnyObject {
    var name: String { get }
}

final class PeripheralData: PeripheralID {
    let name: String
    var lastActivity: Date
    
    init(name: String) {
        self.name = name
        lastActivity = Date()
    }
}

extension PeripheralData: Hashable {
    static func == (lhs: PeripheralData, rhs: PeripheralData) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
