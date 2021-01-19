//
//  CommandInfo.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 08/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation


struct CommandInfo: Equatable {
    let bytes: [UInt8]
    let date: Date
    let isSent: Bool
    let name: String

    init(bytes: [UInt8], isSent: Bool, name: String) {
        self.bytes = bytes
        self.date = Date()
        self.isSent = isSent
        self.name = name
    }
}
