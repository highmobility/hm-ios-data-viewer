//
//  UIViewController+Extensions.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import UIKit


extension UIViewController {

    var connectionViewController: ConnectViewController? {
        return navigationController?.viewControllers.compactMap { $0 as? ConnectViewController }.first
    }

    var masterController: NavigationController? {
        return navigationController as? NavigationController
    }
}
