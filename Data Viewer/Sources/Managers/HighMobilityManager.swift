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

    private(set) var oauthValues: HMOAuth.RequiredValues?
    private(set) var vehicleSerial: Data?

    var hasAccessCertificates: Bool {
        return HMLocalDevice.shared.registeredCertificates.count > 0
    }

    var isBluetoothConnection: Bool = false

    var isBluetoothBroadcasting: Bool {
        return (HMLocalDevice.shared.state == .broadcasting) && (HMLocalDevice.shared.link == nil)
    }

    var skipOAuth: Bool {
        guard let value = Bundle.main.infoDictionary?["Active Configuration"] as? String else {
            return false
        }

        return value == "DEBUG"
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
                case .failure(let reason):
                    completion(.failure(reason))

                case .success(let serial):
                    self.vehicleSerial = serial

                    // Set the boradcastingFilter in advance
                    HMLocalDevice.shared.configuration.broadcastingFilter = serial

                    // Call the completion
                    completion(.success(.certificatesDownloaded))
                }
            }
        }
        catch {
            completion(.failure("Failed to start downloading Access Certificates: \(error)"))
        }
    }

    func getAccessCertificates() {
        #warning("Insert an Access Token, or change .skipOAuth to 'true' to use OAuth instead.")
        downloadAccessCertificates(token: "<#access token#>", completion: deviceChanged)
    }

    func refreshVehicleStatus() {
        let command = AAVehicleStatus.getVehicleStatus

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
            try HMLocalDevice.shared.link?.sendRevoke {
                self.deviceChanged(to: .failure("Revoke failed: \(String(describing: $0))"))
            }
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
        HMLocalDevice.loggingOptions = [.command, .error, .general, .bluetooth, .urlRequests, .telematics, .oauth]

        // OAuth configuration
        #warning("Insert OAuth values and change .skipOAuth to 'false' to use OAuth.")
        oauthValues = (appID: "<#string#>",
                       authURI: "<#string#>",
                       clientID: "<#string#>",
                       redirectScheme: "<#string#>",
                       scope: "<#string#>",
                       tokenURI: "<#string#>")

        // HMLocalDevice configuration
        loadSetup()

        // Other configuration
        vehicleSerial = HMLocalDevice.shared.registeredCertificates.first?.gainingSerial.data
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

    func link(_ link: HMLink, stateChanged previousState: HMLinkState) {
        switch link.state {
        case .authenticated:
            deviceChanged(to: .success(.authenticated))

        default:
            break
        }
    }
}

extension HighMobilityManager: HMLocalDeviceDelegate {

    func localDevice(didLoseLink link: HMLink) {
        link.delegate = nil

        deviceChanged(to: .success(.disconnected))
    }

    func localDevice(didReceiveLink link: HMLink) {
        link.delegate = self
        link.device.stopBroadcasting()

        deviceChanged(to: .success(.connected))
    }

    func localDevice(stateChanged state: HMLocalDeviceState, oldState: HMLocalDeviceState) {
        switch state {
        case .broadcasting:
            deviceChanged(to: .success(.broadcasting(name: HMLocalDevice.shared.name)))

        default:
            break
        }
    }
}

private extension HighMobilityManager {

    var activeLink: HMLink? {
        let link = HMLocalDevice.shared.link

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

    func loadSetup() {
        #error("Insert HMLocalDevice initialiser snippet.")

        /*

        Similar to:

        do {
            try HMLocalDevice.shared.initialise(
                deviceCertificate: "jFkYjCAWexiDV2kaXntcf4D7IPU0TsoRYAnQ9z6ux+/l8UqyvGcXAmI06Enc1luS/EhrwvHBfhM8WiVB3qcBKHoSX...,
                devicePrivateKey: "3smaVGuoGa5qx+h6Tv40PNJ0...",
                issuerPublicKey: "6g6Mn5Kd1+X0c07QwOtcELYP9b03H9SIfdad+KlGoWUjCgq4=..."
            )
        }
        catch {
            // Handle the error
            print("Invalid initialisation parameters, please double check the snippet – error:", error)
        }

         */
    }

    func sendBluetoothCommand(_ command: [UInt8]) {
        guard let link = activeLink else {
            return deviceChanged(to: .failure("Missing authenticated link"))
        }

        do {
            try link.sendCommand(command, sent: {
                if let error = $0 {
                    self.deviceChanged(to: .failure("Failed to send BT command: \(error)"))
                }
                else {
                    // Bluetooth returns GOOD response through LinkDelegate
                }
            })
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
            try HMTelematics.sendCommand(command, serial: serial) {
                switch $0 {
                case .failure(let text):
                    self.deviceChanged(to: .failure(text))

                case .success(let data):
                    guard let command = data else {
                        return
                    }

                    self.commandReceived(command.bytes)
                }
            }
        }
        catch {
            deviceChanged(to: .failure("Failed to send Telematics command: \(error)"))
        }
    }
}
