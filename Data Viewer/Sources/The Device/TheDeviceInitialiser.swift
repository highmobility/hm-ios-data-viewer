////
////  TheDeviceInitialiser.swift
////  Data Viewer
////
////  Created by Mikk Rätsep on 02/05/2018.
////  Copyright © 2018 High-Mobility OÜ. All rights reserved.
////
//
//import Foundation
//import HMKit
//
//
//protocol TheDeviceInitialiser: AnyObject {
//
//    var vehicleSerial: Data? { get set }
//
//
//    func initaliseTheDevice()
//}
//
//extension TheDeviceInitialiser {
//
//    func initaliseTheDevice() {
//        let delegate = self as? TheDeviceDelegate
//
//        LocalDevice.shared.delegate = delegate
//        LocalDevice.loggingOptions = [.command, .error, .general]
//
//        do {
//            // Initialise the LocalDevice
//            try LocalDevice.shared.initialise(
//                deviceCertificate: "dGVzdDUSLl/IvBsqbLx/RoAiLS2m4LIbZaSBumQjUaC6KbdPHPap+nvxgWWRQ7Iic0QEdmnYPz4/iCGInIFpVxfILs+nPM7TzTFdDb7TRfNnWBjoGsrAdixSznlKFT9gTrXqWo1UqLTJoJX8fCMVuzF5zOV56ilzBU2HCuH/A99QXYakK5Ig VCxm4S4l2nEAyrvQuC09Bnmq",
//                devicePrivateKey: "6MhJYvFfFZCYLiXuFR+/8Q7CEos2rGiLYYt5hMEJYIM=",
//                issuerPublicKey: "HuAHdOCCSP3ajv2BI1pTC78YiTe4PEtqUc5/Bk6iRUrgB4cgqgGKXos1ONGZhbRZ0huO2V1pcgk4MwAFB4vffw=="
//            )
//
//            guard LocalDevice.shared.certificate != nil else {
//                throw TheDeviceError.missingDeviceCertificate
//            }
//
//            // Clean the DB from old certificates
//            LocalDevice.shared.resetStorage()
//
//            // TODO: Remove
//            Telematics.urlBasePath = "https://limitless-gorge-44605.herokuapp.com/"
//
//            // Download new Access Certificates
//            try Telematics.downloadAccessCertificate(accessToken: "Op7u6_4kRtE6mkOCfNcxWCahbQCiM82KO-oUravn0FIbKmUhJWutd36pd7V6s41eNy-IuBSk8BD_C8PhOG4kj88PE1JzQQnZLRpVZBzLDJYTI1I9zx87VStv9Ly4XonfNg") {
//                switch $0 {
//                case .failure(let failureReason):
//                    delegate?.theDevice(changed: .failure("Failed to download Access Certificate for Telematics: \(failureReason)"))
//
//                case .success(let vehicleSerial):
//                    self.vehicleSerial = vehicleSerial
//
//                    delegate?.theDevice(changed: .success(.initialised))
//                }
//            }
//        }
//        catch {
//            delegate?.theDevice(changed: .failure("Initialisation failed: \(error)"))
//        }
//    }
//}
//
//
