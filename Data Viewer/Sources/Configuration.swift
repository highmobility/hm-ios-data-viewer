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
        Telematics.urlBasePath = "https://limitless-gorge-44605.herokuapp.com/"
    }
}

private extension Configuration {

    func downloadAccessCertificates(completion: @escaping (Result<ConnectionState>) -> Void) throws {
        // Clean the DB from old certificates
        LocalDevice.shared.resetStorage()

        // Download new Access Certificates
        try Telematics.downloadAccessCertificate(accessToken: "Op7u6_4kRtE6mkOCfNcxWCahbQCiM82KO-oUravn0FIbKmUhJWutd36pd7V6s41eNy-IuBSk8BD_C8PhOG4kj88PE1JzQQnZLRpVZBzLDJYTI1I9zx87VStv9Ly4XonfNg") {
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
            deviceCertificate: "dGVzdDUSLl/IvBsqbLx/RoAiLS2m4LIbZaSBumQjUaC6KbdPHPap+nvxgWWRQ7Iic0QEdmnYPz4/iCGInIFpVxfILs+nPM7TzTFdDb7TRfNnWBjoGsrAdixSznlKFT9gTrXqWo1UqLTJoJX8fCMVuzF5zOV56ilzBU2HCuH/A99QXYakK5IgVCxm4S4l2nEAyrvQuC09Bnmq",
            devicePrivateKey: "6MhJYvFfFZCYLiXuFR+/8Q7CEos2rGiLYYt5hMEJYIM=",
            issuerPublicKey: "HuAHdOCCSP3ajv2BI1pTC78YiTe4PEtqUc5/Bk6iRUrgB4cgqgGKXos1ONGZhbRZ0huO2V1pcgk4MwAFB4vffw=="
        )

        try downloadAccessCertificates(completion: completion)
    }
}
