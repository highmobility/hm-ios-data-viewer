//
//  ConnectionState.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 03/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation


enum ConnectionState {
    case certificatesDownloaded
    case disconnected
    case broadcasting(name: String)
    case connected
    case authenticated
}
