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
        return HMKit.shared.registeredCertificates.count > 0
    }

    var isBluetoothBroadcasting: Bool {
        return (HMKit.shared.state == .broadcasting) && (HMKit.shared.links.count == 0)
    }

    var vehicleSerial: Data? {
        return HMKit.shared.registeredCertificates.first?.gainingSerial.data
    }


    // MARK: Methods

    func clearDatabase() {
        HMKit.shared.resetStorage()
    }

    func disconnectBluetooth() {
        #if !targetEnvironment(simulator)
            HMKit.shared.disconnect()
            HMKit.shared.stopBroadcasting()
        #endif
    }

    func downloadAccessCertificates(token: String, completion: @escaping (Result<ConnectionState>) -> Void) {
        // Clean the DB from old certificates
        HMKit.shared.resetStorage()

        // Download new Access Certificates
        do {
            try HMTelematics.downloadAccessCertificate(accessToken: token) {
                switch $0 {
                case .failure(let error):
                    completion(.failure("\(error)"))

                case .success(let serial):
                    // Set the boradcastingFilter in advance
                    HMKit.shared.configuration.broadcastingFilter = serial.data

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
        let command = AAVehicleStatus.getVehicleStatus.bytes

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
        guard HMKit.shared.state == .idle else {
            return
        }

        guard HMKit.shared.certificate != nil else {
            return deviceChanged(to: .failure("HMLocalDevice is missing it's Device Certificate"))
        }

        guard HMKit.shared.registeredCertificates.count > 0 else {
            return deviceChanged(to: .failure("Missing Access Certificate(s)"))
        }

        guard let serial = vehicleSerial else {
            return deviceChanged(to: .failure("Missing Vehicle Serial"))
        }

        // Just in case set it again
        HMKit.shared.configuration.broadcastingFilter = serial

        // Finally start
        try HMKit.shared.startBroadcasting()
    }


    // MARK: Init

    private init() {
        HMKit.shared.delegate = self
        HMKit.shared.configuration.isAlivePingActive = true
        HMKit.shared.loggingOptions = [.command, .error, .general, .bluetooth, .urlRequests, .telematics, .oauth]
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

    func link(_ link: HMLink, commandReceived bytes: [UInt8]) {
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

extension HighMobilityManager: HMKitDelegate {

    func hmKit(didLoseLink link: HMLink) {
        link.delegate = nil

        deviceChanged(to: .success(.disconnected))
    }

    func hmKit(didReceiveLink link: HMLink) {
        link.delegate = self

        HMKit.shared.stopBroadcasting()

        deviceChanged(to: .success(.connected))
    }

    func hmKit(stateChanged newState: HMKitState, oldState: HMKitState) {
        switch newState {
        case .broadcasting:
            deviceChanged(to: .success(.broadcasting(name: HMKit.shared.name)))

        default:
            break
        }
    }
}

private extension HighMobilityManager {

    var activeLink: HMLink? {
        let link = HMKit.shared.links.first

        guard link?.state == .authenticated else {
            return nil
        }

        return link
    }


    // MARK: Methods

    func commandReceived(_ bytes: [UInt8]) {
        guard let command = AutoAPI.parseBinary(bytes) else {
            return deviceChanged(to: .failure("Failed to parse AutoAPI command."))
        }

        CommandsManager.shared.addReceivedCommand(named: command.debugTree.label, bytes: bytes)

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

                case .success(let bytes):
                    print(bytes.hex)
                    self.commandReceived(bytes)
                }
            }
        }
        catch {
            deviceChanged(to: .failure("Failed to send Telematics command: \(error)"))
        }
    }
}
