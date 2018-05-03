//
//  TheDeviceInitialiser.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMKit


protocol TheDeviceInitialiser: AnyObject {

    var vehicleSerial: Data? { get set }


    func initaliseTheDevice()
}

extension TheDeviceInitialiser where Self: TheDeviceDelegate {

    func initaliseTheDevice() {
        LocalDevice.shared.delegate = self
        LocalDevice.loggingOptions = [.command, .error, .general, .bluetooth, .telematics, .urlRequests]

        do {
            // Initialise the LocalDevice
            fatalError("Insert the 'try LocalDevice.shared.initialise...' snippet here")

            // Clean the DB from old certificates
            LocalDevice.shared.resetStorage()

            // Download new Access Certificates
            try Telematics.downloadAccessCertificate(accessToken: "INSERT ACCESS TOKEN") {
                switch $0 {
                case .failure(let failureReason):
                    self.theDevice(changed: .failure("Failed to download Access Certificate for Telematics: \(failureReason)"))


                case .success(let vehicleSerial):
                    self.vehicleSerial = vehicleSerial
                    self.theDevice(changed: .success(.initialised))
                }
            }
        }
        catch {
            theDevice(changed: .failure("Initialisation failed: \(error)"))
        }
    }
}
