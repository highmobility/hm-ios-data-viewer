//
//  HighMobilityManager.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 09/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import Foundation
import HMKit
import HMUtilities


class HighMobilityManager {

    static let shared = HighMobilityManager()

    var updatesSender: DeviceUpdatableSender?


    // MARK: Methods

    func disconnectBluetooth() {
        #if !targetEnvironment(simulator)
            LocalDevice.shared.disconnect()
            LocalDevice.shared.stopBroadcasting()
        #endif
    }

    func refreshVehicleStatus(usingBluetooth: Bool) {
        let command = VehicleStatus.getVehicleStatus

        sendCommand(command, usingBluetooth: usingBluetooth, name: "VehicleStatus")
    }

    func sendCommand(_ command: [UInt8], usingBluetooth: Bool, name: String) {
        CommandsManager.shared.addSentCommand(named: name, bytes: command)

        if usingBluetooth {
            sendBluetoothCommand(command)
        }
        else {
            sendTelematicsCommand(command)
        }
    }

    func startBluetoothBroadcasting() throws {
        guard LocalDevice.shared.state == .idle else {
            return
        }

        guard LocalDevice.shared.certificate != nil else {
            return sendToDeviceUpdatables(deviceChanged: .failure("LocalDevice is missing it's Device Certificate"))
        }

        try LocalDevice.shared.startBroadcasting()
    }


    // MARK: Init

    private init() {
        do {
            try Configuration.shared.initialise(delegate: self) {
                switch $0 {
                case .failure(let failureReason):
                    self.sendToDeviceUpdatables(deviceChanged: .failure("Failed to download Access Certificate for Telematics: \(failureReason)"))

                case .success(let state):
                    self.sendToDeviceUpdatables(deviceChanged: .success(state))
                }
            }
        }
        catch {
            sendToDeviceUpdatables(deviceChanged: .failure("Failed to initialise Local Device: \(error)"))
        }
    }
}

extension HighMobilityManager: DeviceUpdatableSender {

    func sendToDeviceUpdatables(debugTree: AutoAPI.DebugTree) {
        guard let sender = updatesSender else {
            return print("Missing DeviceUpdatableSender")
        }

        sender.sendToDeviceUpdatables(debugTree: debugTree)
    }

    func sendToDeviceUpdatables(deviceChanged: Result<ConnectionState>) {
        guard let sender = updatesSender else {
            return print("Missing DeviceUpdatableSender")
        }

        sender.sendToDeviceUpdatables(deviceChanged: deviceChanged)
    }
}

extension HighMobilityManager: LinkDelegate {

    func link(_ link: Link, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping LinkDelegate.Approve, timeout: TimeInterval) {
        do {
            try approve()
        }
        catch {
            sendToDeviceUpdatables(deviceChanged: .failure("Failed to Authorise the link: \(error)"))
        }
    }

    func link(_ link: Link, commandReceived bytes: [UInt8]) {
        commandReceived(bytes)
    }

    func link(_ link: Link, stateChanged previousState: LinkState) {
        switch link.state {
        case .authenticated:
            sendToDeviceUpdatables(deviceChanged: .success(.authenticated))

        default:
            break
        }
    }
}

extension HighMobilityManager: LocalDeviceDelegate {

    func localDevice(didLoseLink link: Link) {
        link.delegate = nil

        sendToDeviceUpdatables(deviceChanged: .success(.disconnected))
    }

    func localDevice(didReceiveLink link: Link) {
        link.delegate = self

        sendToDeviceUpdatables(deviceChanged: .success(.connected))
    }

    func localDevice(stateChanged state: LocalDeviceState, oldState: LocalDeviceState) {
        switch state {
        case .broadcasting:
            sendToDeviceUpdatables(deviceChanged: .success(.broadcasting(name: LocalDevice.shared.name)))

        default:
            break
        }
    }
}

private extension HighMobilityManager {

    var activeLink: Link? {
        let link = LocalDevice.shared.link

        guard link?.state == .authenticated else {
            return nil
        }

        return link
    }


    // MARK: Methods

    func commandReceived(_ bytes: [UInt8]) {
        guard let command = AutoAPI.parseBinary(bytes) else {
            return sendToDeviceUpdatables(deviceChanged: .failure("Failed to parse AutoAPI command."))
        }

        CommandsManager.shared.addReceivedCommand(named: command.debugTree.label, bytes: bytes)

        OperationQueue.main.addOperation {
            self.sendToDeviceUpdatables(debugTree: command.debugTree)
        }
    }

    func sendBluetoothCommand(_ command: [UInt8]) {
        guard let link = activeLink else {
            return sendToDeviceUpdatables(deviceChanged: .failure("Missing authenticated link"))
        }

        do {
            try link.sendCommand(command, sent: {
                if let error = $0 {
                    self.sendToDeviceUpdatables(deviceChanged: .failure("Failed to send BT command: \(error)"))
                }
                else {
                    // Bluetooth returns GOOD response through LinkDelegate
                }
            })
        }
        catch {
            sendToDeviceUpdatables(deviceChanged: .failure("Failed to send BT command: \(error)"))
        }
    }

    func sendTelematicsCommand(_ command: [UInt8]) {
        guard let serial = Configuration.shared.vehicleSerial else {
            return sendToDeviceUpdatables(deviceChanged: .failure("Missing vehicle serial"))
        }

        do {
            try Telematics.sendCommand(command, serial: serial) {
                switch $0 {
                case .failure(let text):
                    self.sendToDeviceUpdatables(deviceChanged: .failure("Failed to send Telematics command: \(text)"))

                case .success(let data):
                    guard let command = data else {
                        return
                    }

                    self.commandReceived(command.bytes)
                }
            }
        }
        catch {
            sendToDeviceUpdatables(deviceChanged: .failure("Failed to send Telematics command: \(error)"))
        }
    }
}
