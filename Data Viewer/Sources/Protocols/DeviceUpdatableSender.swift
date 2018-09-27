//
//  DeviceUpdatableSender.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 09/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMUtilities


protocol DeviceUpdatableSender {

    func sendToDeviceUpdatables(debugTree: DebugTree)
    func sendToDeviceUpdatables(deviceChanged: Result<ConnectionState>)
}
