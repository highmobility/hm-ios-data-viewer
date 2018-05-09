//
//  Configuration.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 09/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMKit


class Configuration {

    static let shared = Configuration()


    // MARK: iVars

    private(set) var vehicleSerial: Data?


    // MARK: Methods

    func initialise(delegate: LocalDeviceDelegate, completion: @escaping (Result<ConnectionState>) -> Void) throws {
        LocalDevice.shared.delegate = delegate
        
        try initialiseLocalDevice(completion: completion)
    }

    private init() {
        LocalDevice.loggingOptions = [.command, .error, .general]
    }
}

private extension Configuration {

    func downloadAccessCertificates(completion: @escaping (Result<ConnectionState>) -> Void) throws {
        // Clean the DB from old certificates
        LocalDevice.shared.resetStorage()

        // Download new Access Certificates
        try Telematics.downloadAccessCertificate(accessToken: ".....") {
            switch $0 {
            case .failure(let failureReason):
                completion(.failure("Failed to download Access Certificate for Telematics: \(failureReason)"))

            case .success(let serial):
                self.vehicleSerial = serial

                completion(.success(.initialised))
            }
        }
    }

    func initialiseLocalDevice(completion: @escaping (Result<ConnectionState>) -> Void) throws {
        try LocalDevice.shared.initialise(
            deviceCertificate: ".....",
            devicePrivateKey: ".....",
            issuerPublicKey: "....."
        )

        try downloadAccessCertificates(completion: completion)
    }
}
