//
//  NavigationController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import UIKit


class NavigationController: UINavigationController {

    private var deviceUpdatables: [DeviceUpdatable] {
        return viewControllers.compactMap { $0 as? DeviceUpdatable }
    }


    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        HighMobilityManager.shared.updatesSender = self
    }
}

extension NavigationController: DeviceUpdatableSender {

    func sendToDeviceUpdatables(debugTree: AutoAPI.DebugTree) {
        deviceUpdatables.forEach {
            $0.deviceReceived(debugTree: debugTree)
        }
    }

    func sendToDeviceUpdatables(deviceChanged: Result<ConnectionState>) {
        deviceUpdatables.forEach {
            $0.deviceChanged(to: deviceChanged)
        }
    }
}
