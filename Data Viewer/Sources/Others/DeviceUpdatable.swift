//
//  DeviceUpdatable.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import Foundation


protocol DeviceUpdatable {

    func deviceChanged(to result: Result<ConnectionState>)
    func deviceReceived(debugTree: AutoAPI.DebugTree)
}
