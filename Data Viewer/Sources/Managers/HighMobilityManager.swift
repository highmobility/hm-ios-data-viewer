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

    var deviceUpdatesSender: DeviceUpdatable?
    var isBluetoothConnection: Bool = false

    var hasAccessCertificates: Bool {
        return HMLocalDevice.shared.registeredCertificates.count > 0
    }

    var isBluetoothBroadcasting: Bool {
        return (HMLocalDevice.shared.state == .broadcasting) && (HMLocalDevice.shared.links.count == 0)
    }

    var vehicleSerial: Data? {
        return HMLocalDevice.shared.registeredCertificates.first?.gainingSerial.data
    }


    // MARK: Methods

    func clearDatabase() {
        HMLocalDevice.shared.resetStorage()
    }

    func disconnectBluetooth() {
        #if !targetEnvironment(simulator)
            HMLocalDevice.shared.disconnect()
            HMLocalDevice.shared.stopBroadcasting()
        #endif
    }

    func downloadAccessCertificates(token: String, completion: @escaping (Result<ConnectionState>) -> Void) {
        // Clean the DB from old certificates
        HMLocalDevice.shared.resetStorage()

        // Download new Access Certificates
        do {
            try HMTelematics.downloadAccessCertificate(accessToken: token) {
                switch $0 {
                case .failure(let error):
                    completion(.failure("\(error)"))

                case .success(let serial):
                    // Set the boradcastingFilter in advance
                    HMLocalDevice.shared.configuration.broadcastingFilter = serial.data

                    // Call the completion
                    completion(.success(.certificatesDownloaded))
                }
            }
        }
        catch {
            completion(.failure("Failed to start downloading Access Certificates: \(error)"))
        }
    }

    func refreshVehicleStatus() {
        let command = AAVehicleStatus.getVehicleStatus()

        sendCommand(command, name: "VehicleStatus")
    }

    func sendCommand(_ command: [UInt8], name: String) {
        CommandsManager.shared.addSentCommand(named: name, bytes: command)

        if isBluetoothConnection {
            sendBluetoothCommand(command)
        }
        else {
            sendTelematicsCommand(command)
        }
    }

    func sendRevoke() {
        do {
            try activeLink?.sendRevoke()
        }
        catch {
            deviceChanged(to: .failure("Revoke failed: \(error)"))
        }
    }

    func startBluetoothBroadcasting() throws {
        guard HMLocalDevice.shared.state == .idle else {
            return
        }

        guard HMLocalDevice.shared.certificate != nil else {
            return deviceChanged(to: .failure("HMLocalDevice is missing it's Device Certificate"))
        }

        guard HMLocalDevice.shared.registeredCertificates.count > 0 else {
            return deviceChanged(to: .failure("Missing Access Certificate(s)"))
        }

        guard let serial = vehicleSerial else {
            return deviceChanged(to: .failure("Missing Vehicle Serial"))
        }

        // Just in case set it again
        HMLocalDevice.shared.configuration.broadcastingFilter = serial

        // Finally start
        try HMLocalDevice.shared.startBroadcasting()
    }


    // MARK: Init

    private init() {
        HMLocalDevice.shared.delegate = self
        HMLocalDevice.shared.configuration.isAlivePingActive = true
        HMLocalDevice.shared.loggingOptions = [.command, .error, .general, .bluetooth, .urlRequests, .telematics, .oauth]
    }
}

extension HighMobilityManager: DeviceUpdatable {

    func deviceReceived(debugTree: HMDebugTree) {
        deviceUpdatesSender?.deviceReceived(debugTree: debugTree)
    }

    func deviceChanged(to result: Result<ConnectionState>) {
        deviceUpdatesSender?.deviceChanged(to: result)
    }
}

extension HighMobilityManager: HMLinkDelegate {

    func link(_ link: HMLink, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping HMLinkDelegate.Approve, timeout: TimeInterval) {
        do {
            try approve()
        }
        catch {
            deviceChanged(to: .failure("Failed to Authorise the link: \(error)"))
        }
    }

    func link(_ link: HMLink, commandReceived bytes: [UInt8], contentType: HMContainerContentType, requestID: [UInt8]) {
        commandReceived(bytes)
    }

    func link(_ link: HMLink, revokeCompleted bytes: [UInt8]) {
        print("REVOKE COMPLETED:", bytes.hex)

        deviceChanged(to: .success(.connected))
    }

    func link(_ link: HMLink, stateChanged newState: HMLinkState, previousState: HMLinkState) {
        switch newState {
        case .authenticated:
            deviceChanged(to: .success(.authenticated))

        default:
            break
        }
    }

    func link(_ link: HMLink, receivedError error: HMProtocolError) {
        print("Link:", link, "received an error:", error)
    }
}

extension HighMobilityManager: HMLocalDeviceDelegate {

    func localDevice(didLoseLink link: HMLink) {
        link.delegate = nil

        deviceChanged(to: .success(.disconnected))
    }

    func localDevice(didReceiveLink link: HMLink) {
        link.delegate = self

        HMLocalDevice.shared.stopBroadcasting()

        deviceChanged(to: .success(.connected))
    }

    func localDevice(stateChanged newState: HMLocalDeviceState, oldState: HMLocalDeviceState) {
        switch newState {
        case .broadcasting:
            deviceChanged(to: .success(.broadcasting(name: HMLocalDevice.shared.name)))

        default:
            break
        }
    }
}

private extension HighMobilityManager {

    var activeLink: HMLink? {
        let link = HMLocalDevice.shared.links.first

        guard link?.state == .authenticated else {
            return nil
        }

        return link
    }


    // MARK: Methods

    func commandReceived(_ bytes: [UInt8]) {
        guard let command = AAAutoAPI.parseBinary(bytes) else {
            return deviceChanged(to: .failure("Failed to parse AutoAPI command."))
        }

        CommandsManager.shared.addReceivedCommand(named: "\(type(of: command))", bytes: bytes)

        OperationQueue.main.addOperation {
            self.deviceReceived(debugTree: command.debugTree)
        }
    }

    func sendBluetoothCommand(_ command: [UInt8]) {
        guard let link = activeLink else {
            return deviceChanged(to: .failure("Missing authenticated link"))
        }

        do {
            try link.send(command: command) {
                switch $0 {
                case .failure(let error):
                    self.deviceChanged(to: .failure("Failed to send BT command: \(error)"))

                case .success:
                    // Bluetooth returns GOOD response through LinkDelegate
                    break
                }
            }
        }
        catch {
            deviceChanged(to: .failure("Failed to send BT command: \(error)"))
        }
    }

    func sendTelematicsCommand(_ command: [UInt8]) {
        guard let serial = vehicleSerial else {
            return deviceChanged(to: .failure("Missing vehicle serial"))
        }

        do {
            try HMTelematics.sendCommand(command, serial: serial.bytes) {
                switch $0 {
                case .failure(let error):
                    self.deviceChanged(to: .failure("\(error)"))

                case .success(let command, _, _):
                    self.commandReceived(command)
                }
            }
        }
        catch {
            deviceChanged(to: .failure("Failed to send Telematics command: \(error)"))
        }
    }
}
