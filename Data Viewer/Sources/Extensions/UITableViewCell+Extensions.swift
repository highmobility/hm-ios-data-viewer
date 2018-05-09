//
//  UITableViewCell+Extensions.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 08/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import UIKit


extension UITableViewCell {

    var labelTagged: (Int) -> UILabel? {
        return { self.viewWithTag($0) as? UILabel }
    }
}
