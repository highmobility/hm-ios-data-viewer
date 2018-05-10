//
//  DebugTree+Extensions.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMUtilities


extension DebugTree {

    var nodes: [DebugTree]? {
        guard case .node(label: _, nodes: let nodes) = self else {
            return nil
        }

        return nodes
    }
}
