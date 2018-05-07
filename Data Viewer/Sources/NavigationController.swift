//
//  NavigationController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import HMKit
import HMUtilities
import UIKit


class NavigationController: UINavigationController {

    private var vehicleSerial: Data?


    // MARK: Methods

    func disconnectBluetooth() {
        LocalDevice.shared.disconnect()
        LocalDevice.shared.stopBroadcasting()
    }

    func refreshVehicleStatus(usingBluetooth: Bool) {
        let command = VehicleStatus.getVehicleStatus

        sendCommand(command, usingBluetooth: usingBluetooth)
    }

    func sendCommand(_ command: [UInt8], usingBluetooth: Bool) {
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


    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        do {
            try initialiseLocalDevice()
        }
        catch {
            sendToDeviceUpdatables(deviceChanged: .failure("Failed to initialise Local Device: \(error)"))
        }
    }
}

extension NavigationController: LinkDelegate {

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

extension NavigationController: LocalDeviceDelegate {

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

private extension NavigationController {

    var activeLink: Link? {
        let link = LocalDevice.shared.link

        guard link?.state == .authenticated else {
            return nil
        }

        return link
    }

    var deviceUpdatables: [DeviceUpdatable] {
        return viewControllers.compactMap { $0 as? DeviceUpdatable }
    }


    // MARK: Methods

    func commandReceived(_ bytes: [UInt8]) {
        guard let command = AutoAPI.parseBinary(bytes) else {
            return sendToDeviceUpdatables(deviceChanged: .failure("Failed to parse AutoAPI command."))
        }

        OperationQueue.main.addOperation {
            self.sendToDeviceUpdatables(debugTree: command.debugTree)
        }
    }

    func downloadAccessCertificates() throws {
        // Clean the DB from old certificates
        LocalDevice.shared.resetStorage()

        // Download new Access Certificates
        try Telematics.downloadAccessCertificate(accessToken: "ACCCESS CERTIFICATE") {
            switch $0 {
            case .failure(let failureReason):
                self.sendToDeviceUpdatables(deviceChanged: .failure("Failed to download Access Certificate for Telematics: \(failureReason)"))

            case .success(let vehicleSerial):
                self.vehicleSerial = vehicleSerial
                self.sendToDeviceUpdatables(deviceChanged: .success(.initialised))
            }
        }
    }

    func initialiseLocalDevice() throws {
        LocalDevice.shared.delegate = self
        LocalDevice.loggingOptions = [.command, .error, .general]

        // Initialise the LocalDevice
        try LocalDevice.shared.initialise(
            deviceCertificate: "...",
            devicePrivateKey: "...",
            issuerPublicKey: "..."
        )

        guard LocalDevice.shared.certificate != nil else {
            throw LocalDeviceError.internalError
        }

        try downloadAccessCertificates()
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
        guard let serial = vehicleSerial else {
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

    func sendToDeviceUpdatables(debugTree: AutoAPI.DebugTree) {
        deviceUpdatables.forEach {
            $0.deviceReceived(debugTree: debugTree)
        }
    }

    func sendToDeviceUpdatables(deviceChanged: Result<ConnectionState>) {
        deviceUpdatables.forEach {
            $0.deviceChanged(to: deviceChanged)
        }
    }
}
