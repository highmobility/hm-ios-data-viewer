//
//  CommandsManager.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 08/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import Foundation


class CommandsManager {

    static let shared = CommandsManager()


    private(set) var commands: [CommandInfo] = []


    // MARK: Methods

    func addReceivedCommand(named: String, bytes: [UInt8]) {
        addCommand(CommandInfo(bytes: bytes, isSent: false, name: named))
    }

    func addSentCommand(named: String, bytes: [UInt8]) {
        addCommand(CommandInfo(bytes: bytes, isSent: true, name: named))
    }
}

private extension CommandsManager {

    func addCommand(_ commandInfo: CommandInfo) {
        commands.append(commandInfo)
        commands.sort { $0.date > $1.date }
    }
}
