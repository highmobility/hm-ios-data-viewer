//
//  URLRequest+Extensions.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 15/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation


extension URLRequest {

    init(url: URL, httpMethod: String) {
        self.init(url: url)
        self.httpMethod = httpMethod
    }
}
