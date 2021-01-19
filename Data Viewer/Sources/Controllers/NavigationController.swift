//
//  NavigationController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import UIKit
import HMUtilities


class NavigationController: UINavigationController {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        HighMobilityManager.shared.deviceUpdatesSender = self
    }
}

extension NavigationController: DeviceUpdatable {

    func deviceReceived(debugTree: HMDebugTree) {
        OperationQueue.main.addOperation {
            self.deviceUpdatables.forEach {
                $0.deviceReceived(debugTree: debugTree)
            }
        }
    }

    func deviceChanged(to result: Result<ConnectionState>) {
        OperationQueue.main.addOperation {
            self.deviceUpdatables.forEach {
                $0.deviceChanged(to: result)
            }
        }
    }
}

private extension NavigationController {

    var deviceUpdatables: [DeviceUpdatable] {
        return viewControllers.compactMap { $0 as? DeviceUpdatable }
    }
}
