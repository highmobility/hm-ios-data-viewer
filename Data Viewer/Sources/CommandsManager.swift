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

//    var receivedCommands: [CommandInfo] {
//        return commands.filter { !$0.isSent }
//    }
//
//    var sentCommands: [CommandInfo] {
//        return commands.filter { $0.isSent }
//    }


    // MARK: Methods

    func addReceivedCommand(named: String, bytes: [UInt8]) {
        addCommand(CommandInfo(bytes: bytes, isSent: false, name: named))
    }

    func addSentCommand(named: String, bytes: [UInt8]) {
        addCommand(CommandInfo(bytes: bytes, isSent: true, name: named))
    }


    // TODO: Delete
//    init() {
//        var commands: [CommandInfo] = []
//
//        commands.append(CommandInfo(bytes: DoorLocks.getLockState, isSent: false, name: "DoorLocks"))
//        commands.append(CommandInfo(bytes: ParkingTicket.getParkingTicket, isSent: false, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x47, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: VehicleStatus.getVehicleStatus, isSent: false, name: "VehicleStatus"))
//        commands.append(CommandInfo(bytes: DoorLocks.getLockState, isSent: false, name: "DoorLocks"))
//        commands.append(CommandInfo(bytes: ParkingTicket.getParkingTicket, isSent: false, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x47, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00, 0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00, 0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: VehicleStatus.getVehicleStatus, isSent: false, name: "VehicleStatus"))
//        commands.append(CommandInfo(bytes: DoorLocks.getLockState, isSent: false, name: "DoorLocks"))
//        commands.append(CommandInfo(bytes: ParkingTicket.getParkingTicket, isSent: false, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x47, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: VehicleStatus.getVehicleStatus, isSent: false, name: "VehicleStatus"))
//        commands.append(CommandInfo(bytes: DoorLocks.getLockState, isSent: false, name: "DoorLocks"))
//        commands.append(CommandInfo(bytes: ParkingTicket.getParkingTicket, isSent: false, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x47, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: [0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00, 0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00, 0x00, 0x63, 0x02, 0x01, 0x00, 0x01, 0x00], isSent: true, name: "ParkingTicket"))
//        commands.append(CommandInfo(bytes: VehicleStatus.getVehicleStatus, isSent: false, name: "VehicleStatus"))
//
//        commands.enumerated().forEach { asd in
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (Double(asd.offset) * 0.1), execute: {
//                self.addCommand(asd.element)
//                print("Done", asd.offset)
//            })
//        }
//    }
}

private extension CommandsManager {

    func addCommand(_ commandInfo: CommandInfo) {
        commands.append(commandInfo)
        commands.sort { $0.date > $1.date }
    }
}
