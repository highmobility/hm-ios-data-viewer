//
//  UITableViewCell+Extensions.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 08/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import UIKit


extension UITableViewCell {

    func label(tagged tag: Int) -> UILabel? {
        return viewWithTag(tag) as? UILabel
    }
}
