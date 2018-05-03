//
//  Result.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation


enum Result<Value> {
    case failure(String)
    case success(Value)
}
