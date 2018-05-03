//
//  TheDeviceManager.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 03/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMKit
import HMUtilities


protocol TheDeviceManager {

    func sendCommand(_ command: [UInt8], usingBluetooth: Bool)

    func disconnectBluetooth()
    func startBluetoothBroadcasting()
}

extension TheDeviceManager where Self: TheDeviceDelegate, Self: TheDeviceInitialiser {

    func sendCommand(_ command: [UInt8], usingBluetooth: Bool) {
        if usingBluetooth {
            sendBluetoothCommand(command)
        }
        else {
            sendTelematicsCommand(command)
        }
    }


    func disconnectBluetooth() {
        LocalDevice.shared.disconnect()
        LocalDevice.shared.stopBroadcasting()
    }

    func startBluetoothBroadcasting() {
        guard LocalDevice.shared.state == .idle else {
            return
        }

        guard LocalDevice.shared.certificate != nil else {
            return theDevice(changed: .failure("LocalDevice is missing it's Device Certificate"))
        }

        do {
            try LocalDevice.shared.startBroadcasting()
        }
        catch {
            theDevice(changed: .failure("Failed to start broadcasting: \(error)"))
        }
    }
}

private extension TheDeviceManager where Self: TheDeviceDelegate, Self: TheDeviceInitialiser {

    var activeLink: Link? {
        let link = LocalDevice.shared.link

        guard link?.state == .authenticated else {
            return nil
        }

        return link
    }


    func sendBluetoothCommand(_ command: [UInt8]) {
        guard let link = activeLink else {
            return theDevice(changed: .failure("Missing authenticated link"))
        }

        do {
            try link.sendCommand(command, sent: {
                if let error = $0 {
                    self.theDevice(changed: .failure("Failed to send BT command: \(error)"))
                }
                else {
                    // Bluetooth returns GOOD response through LinkDelegate
                }
            })
        }
        catch {
            theDevice(changed: .failure("Failed to send BT command: \(error)"))
        }
    }

    func sendTelematicsCommand(_ command: [UInt8]) {
        guard let serial = vehicleSerial else {
            return theDevice(changed: .failure("Missing vehicle serial"))
        }

        do {
            try Telematics.sendCommand(command, serial: serial) {
                switch $0 {
                case .failure(let text):
                    self.theDevice(changed: .failure("Failed to send Telematics command: \(text)"))

                case .success(let data):
                    guard let command = data else {
                        return
                    }

                    self.theDevice(commandReceived: command.bytes)
                }
            }
        }
        catch {
            theDevice(changed: .failure("Failed to send Telematics command: \(error)"))
        }
    }
}
