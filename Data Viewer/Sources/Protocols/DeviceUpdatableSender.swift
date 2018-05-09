//
//  DeviceUpdatableSender.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 09/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import Foundation


protocol DeviceUpdatableSender {

    func sendToDeviceUpdatables(debugTree: AutoAPI.DebugTree)
    func sendToDeviceUpdatables(deviceChanged: Result<ConnectionState>)
}
