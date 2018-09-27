////
////  TheDeviceManager.swift
////  Data Viewer
////
////  Created by Mikk Rätsep on 03/05/2018.
////  Copyright © 2018 High-Mobility OÜ. All rights reserved.
////
//
//import Foundation
//import HMKit
//import HMUtilities
//
//
//protocol TheDeviceManager {
//
//    func disconnectBluetooth()
//    func sendCommand(_ command: [UInt8], usingBluetooth: Bool)
//    func startBluetoothBroadcasting()
//}
//
//extension TheDeviceManager {
//
//    func disconnectBluetooth() {
//        LocalDevice.shared.disconnect()
//        LocalDevice.shared.stopBroadcasting()
//    }
//
//    func sendCommand(_ command: [UInt8], usingBluetooth: Bool) {
//        if usingBluetooth {
//            sendBluetoothCommand(command)
//        }
//        else {
//            sendTelematicsCommand(command)
//        }
//    }
//
//    func startBluetoothBroadcasting() {
//        guard LocalDevice.shared.state == .idle else {
//            return
//        }
//
//        let delegate = self as? TheDeviceDelegate
//
//        guard LocalDevice.shared.certificate != nil else {
//            return delegate?.theDevice(changed: .failure("LocalDevice is missing it's Device Certificate")) ?? Void()
//        }
//
//        do {
//            try LocalDevice.shared.startBroadcasting()
//        }
//        catch {
//            delegate?.theDevice(changed: .failure("Failed to start broadcasting: \(error)"))
//        }
//    }
//}
//
//private extension TheDeviceManager {
//
//    var activeLink: Link? {
//        let link = LocalDevice.shared.link
//
//        guard link?.state == .authenticated else {
//            return nil
//        }
//
//        return link
//    }
//
//
//    func sendBluetoothCommand(_ command: [UInt8]) {
//        let delegate = self as? TheDeviceDelegate
//
//        guard let link = activeLink else {
//            return delegate?.theDevice(changed: .failure("Missing authenticated link")) ?? Void()
//        }
//
//        do {
//            try link.sendCommand(command, sent: {
//                if let error = $0 {
//                    delegate?.theDevice(changed: .failure("Failed to send BT command: \(error)"))
//                }
//                else {
//                    // Bluetooth returns GOOD response through LinkDelegate
//                }
//            })
//        }
//        catch {
//            delegate?.theDevice(changed: .failure("Failed to send BT command: \(error)"))
//        }
//    }
//
//    func sendTelematicsCommand(_ command: [UInt8]) {
//        let delegate = self as? TheDeviceDelegate
//        let initialiser = self as? TheDeviceInitialiser
//
//        guard let serial = initialiser?.vehicleSerial else {
//            return delegate?.theDevice(changed: .failure("Missing vehicle serial")) ?? Void()
//        }
//
//        do {
//            try Telematics.sendCommand(command, serial: serial) {
//                switch $0 {
//                case .failure(let text):
//                    delegate?.theDevice(changed: .failure("Failed to send Telematics command: \(text)"))
//
//                case .success(let data):
//                    guard let command = data else {
//                        return
//                    }
//
//                    delegate?.theDevice(commandReceived: command.bytes)
//                }
//            }
//        }
//        catch {
//            delegate?.theDevice(changed: .failure("Failed to send Telematics command: \(error)"))
//        }
//    }
//}
