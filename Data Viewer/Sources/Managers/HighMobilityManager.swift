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
    var oauthUpdatesSender: OAuthUpdatable?

    private(set) var vehicleSerial: Data?
    private var appID: String!
    private var authURI: String!
    private var clientID: String!
    private var redirectScheme: String!
    private var scope: String!
    private var tokenURI: String!

    var hasAccessCertificates: Bool {
        return LocalDevice.shared.registeredCertificates.count > 0
    }

    var isBluetoothConnection: Bool = false

    var isBluetoothBroadcasting: Bool {
        return (LocalDevice.shared.state == .broadcasting) && (LocalDevice.shared.link == nil)
    }

    var isRunningDebug: Bool {
        guard let value = Bundle.main.infoDictionary?["Active Configuration"] as? String else {
            return false
        }

        return value == "DEBUG"
    }

    var oauthURL: URL? {
        return OAuthManager.oauthURL(authURI: authURI, clientID: clientID, redirectScheme: redirectScheme, scope: scope, appID: appID)
    }


    // MARK: Methods

    func clearDatabase() {
        LocalDevice.shared.resetStorage()
    }

    func disconnectBluetooth() {
        #if !targetEnvironment(simulator)
            LocalDevice.shared.disconnect()
            LocalDevice.shared.stopBroadcasting()
        #endif
    }

    func downloadAccessCertificates(accessTokenCode code: String, completion: @escaping (Result<ConnectionState>) -> Void) {
        guard LocalDevice.shared.certificate != nil else {
            return completion(.failure("LocalDevice uninitialised!"))
        }

        // First download the TOKEN for Access Certificates
        OAuthManager.requestAccessToken(tokenURI: tokenURI, redirectScheme: redirectScheme, clientID: clientID, code: code) {
            switch $0 {
            case .failure(let reason):
                completion(.failure("Failed to download Access Token: \(reason)"))

            case .success(let accessToken):
                // Then download the CERTIFICATES
                self.downloadAccessCertificates(token: accessToken, completion: completion)
            }
        }
    }

    func downloadDebugCertificates() {
        /*
         Linked against STAGING: mikk's tester - Maidu test 2
         */
        downloadAccessCertificates(token: "fdb0741e-64f0-4a38-b74d-47e6da2eee0d", completion: deviceChanged)
    }

    func refreshVehicleStatus() {
        let command = VehicleStatus.getVehicleStatus

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
            try LocalDevice.shared.link?.sendRevoke {
                self.deviceChanged(to: .failure("Revoke failed: \($0)"))
            }
        }
        catch {
            deviceChanged(to: .failure("Revoke failed: \(error)"))
        }
    }

    func startBluetoothBroadcasting() throws {
        guard LocalDevice.shared.state == .idle else {
            return
        }

        guard LocalDevice.shared.certificate != nil else {
            return deviceChanged(to: .failure("LocalDevice is missing it's Device Certificate"))
        }

        guard LocalDevice.shared.registeredCertificates.count > 0 else {
            return deviceChanged(to: .failure("Missing Access Certificate(s)"))
        }

        guard let serial = vehicleSerial else {
            return deviceChanged(to: .failure("Missing Vehicle Serial"))
        }

        // Just in case set it again
        LocalDevice.shared.configuration.broadcastingFilter = serial

        // Finally start
        try LocalDevice.shared.startBroadcasting()
    }


    // MARK: Init

    private init() {
        LocalDevice.shared.delegate = self
        LocalDevice.shared.configuration.isAlivePingActive = true
        LocalDevice.loggingOptions = [.command, .error, .general, .bluetooth, .urlRequests, .telematics]

        // OAuth configuration
        appID = "A0F90F9AB61ED3649ADE165F"
        authURI = "https://developers.high-mobility.com/hm_cloud/o/159395ba-f738-4c7a-a826-49205737d7cf/oauth"
        clientID = "e3a34856-48c4-4e18-83b7-9d8249496d75"
        redirectScheme = "com.hm.dev.1525347432-8qrtgjeqjfxq://in-app-callback"
        scope = "car.full_control"
        tokenURI = "https://developers.high-mobility.com/hm_cloud/api/v1/159395ba-f738-4c7a-a826-49205737d7cf/oauth/access_tokens"

        // LocalDevice configuration
        isRunningDebug ? loadDebugSetup() : loadVolkswagenSetup()

        // Other configuration
        vehicleSerial = LocalDevice.shared.registeredCertificates.first?.gainingSerial.data
    }
}

extension HighMobilityManager: DeviceUpdatable {

    func deviceReceived(debugTree: DebugTree) {
        deviceUpdatesSender?.deviceReceived(debugTree: debugTree)
    }

    func deviceChanged(to result: Result<ConnectionState>) {
        deviceUpdatesSender?.deviceChanged(to: result)
    }
}

extension HighMobilityManager: LinkDelegate {

    func link(_ link: Link, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping LinkDelegate.Approve, timeout: TimeInterval) {
        do {
            try approve()
        }
        catch {
            deviceChanged(to: .failure("Failed to Authorise the link: \(error)"))
        }
    }

    func link(_ link: Link, commandReceived bytes: [UInt8]) {
        commandReceived(bytes)
    }

    func link(_ link: Link, revokeCompleted bytes: [UInt8]) {
        print("REVOKE COMPLETED:", bytes.hex)

        deviceChanged(to: .success(.connected))
    }

    func link(_ link: Link, stateChanged previousState: LinkState) {
        switch link.state {
        case .authenticated:
            deviceChanged(to: .success(.authenticated))

        default:
            break
        }
    }
}

extension HighMobilityManager: LocalDeviceDelegate {

    func localDevice(didLoseLink link: Link) {
        link.delegate = nil

        deviceChanged(to: .success(.disconnected))
    }

    func localDevice(didReceiveLink link: Link) {
        link.delegate = self
        link.device.stopBroadcasting()

        deviceChanged(to: .success(.connected))
    }

    func localDevice(stateChanged state: LocalDeviceState, oldState: LocalDeviceState) {
        switch state {
        case .broadcasting:
            deviceChanged(to: .success(.broadcasting(name: LocalDevice.shared.name)))

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
            return deviceChanged(to: .failure("Failed to parse AutoAPI command."))
        }

        CommandsManager.shared.addReceivedCommand(named: command.debugTree.label, bytes: bytes)

        OperationQueue.main.addOperation {
            self.deviceReceived(debugTree: command.debugTree)
        }
    }

    func downloadAccessCertificates(token: String, completion: @escaping (Result<ConnectionState>) -> Void) {
        // Clean the DB from old certificates
        LocalDevice.shared.resetStorage()

        // Download new Access Certificates
        do {
            try Telematics.downloadAccessCertificate(accessToken: token) {
                switch $0 {
                case .failure(let reason):
                    completion(.failure(reason))

                case .success(let serial):
                    self.vehicleSerial = serial

                    // Set the boradcastingFilter in advance
                    LocalDevice.shared.configuration.broadcastingFilter = serial

                    // Call the completion
                    completion(.success(.certificatesDownloaded))
                }
            }
        }
        catch {
            completion(.failure("Failed to start downloading Access Certificates: \(error)"))
        }
    }

    func loadDebugSetup() {
        /*
         Linked against STAGING: mikk's tester - Maidu test 2
         */
        Telematics.urlBasePath = "https://beta.high-mobility.com/"

        do {
            try LocalDevice.shared.initialise(
                deviceCertificate: "dGVzdCDK7WkAukU3oE3a/vjUgdE6viAMr+w36PWumj8aopMKD6T4lYRry7rdY3Iq5LXNrnU5HSrZ6f6jy5NmZan7t57bw3gE0CzAv6voGYednwKG+fN6d1wj8T4dLPP4mzFXYefVFBJckQRKG9moGHQPd4JF9QjceHskOwEm7dOEv8PHyKa6T1OF0ozBh61ZNfLKIBNqZF8K",
                devicePrivateKey: "s+RKDASnrqfqz9/6rJ3Znagu55BZn3yFqdd5zDDO8Y4=",
                issuerPublicKey: "AawGZMytNPgOoWWcoM2mLccU7tg0kdyFk+jOPDXqyEZVVeU6g9iDLRy6bSAsbqOZPXaSabCTrdn9fqHbTKY7jQ=="
            )
        }
        catch {
            // Handle the error
            print("Invalid initialisation parameters, please double check the snippet – error:", error)
        }
    }

    func loadVolkswagenSetup() {
        do {
            try LocalDevice.shared.initialise(
                deviceCertificate: "dGVzdKD5D5q2HtNkmt4WX+V7QiD7FtBFLrmnbuUFzJxCpRnfoMP4VkGOqpAYyoAZirRJIH7CR01TpPIM6Vps7r4pVH54tDGZiPi4ekCjRY1Ex+IjJdyKyrzt4rqjx7ziVJFGGZgEHYIDaPxcpojSNltCdKD36WX7w//0GHTtBXLkLdsU0947di9RHetOD+J0L7GeQGveJWDj",
                devicePrivateKey: "r2RZcb1TNZrVPP6YaJoL+qiAID1mjwEE83FOEng938M=",
                issuerPublicKey: "mqFX9i6iNMs2KjNfv+R9YqREtJaDAYhgeWZsVSEmI95GRfIzTTXWJQI/VfX3XDs4NRO0lWMSQwNgl1lER0h+wA==")
        }
        catch {
            deviceChanged(to: .failure("Failed to initialise Local Device: \(error)"))
        }
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
            try Telematics.sendCommand(command, serial: serial) {
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
