//
//  TheDeviceDelegate.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMKit


protocol TheDeviceDelegate: LinkDelegate, LocalDeviceDelegate {

    func theDevice(commandReceived bytes: [UInt8])
    func theDevice(changed to: Result<ConnectionState>)
}

extension TheDeviceDelegate {

    func link(_ link: Link, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping LinkDelegate.Approve, timeout: TimeInterval) {
        do {
            try approve()
        }
        catch {
            theDevice(changed: .failure("Failed to Authorise the link: \(error)"))
        }
    }

    func link(_ link: Link, commandReceived bytes: [UInt8]) {
        theDevice(commandReceived: bytes)
    }

    func link(_ link: Link, stateChanged previousState: LinkState) {
        switch link.state {
        case .authenticated:
            theDevice(changed: .success(.authenticated))

        default:
            break
        }
    }
}

extension TheDeviceDelegate {

    func localDevice(didLoseLink link: Link) {
        link.delegate = nil

        theDevice(changed: .success(.disconnected))
    }

    func localDevice(didReceiveLink link: Link) {
        link.delegate = self

        theDevice(changed: .success(.connected))
    }

    func localDevice(stateChanged state: LocalDeviceState, oldState: LocalDeviceState) {
        switch state {
        case .broadcasting:
            theDevice(changed: .success(.broadcasting(name: LocalDevice.shared.name)))

        default:
            break
        }
    }
}
