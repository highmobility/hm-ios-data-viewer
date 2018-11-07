//
//  HMDebugTree+Extensions.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 04/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMUtilities


extension HMDebugTree {

    var nodes: [HMDebugTree]? {
        guard case .node(label: _, nodes: let nodes) = self else {
            return nil
        }

        return nodes
    }


    func subPropertyValue(named: String, filterFunction: ((HMDebugTree) -> Bool)?) -> String? {
        let function = filterFunction ?? { _ in true }

        return nodes?.filter(function).first { $0.label.starts(with: named) }?.label.components(separatedBy: "=").last
    }
}
