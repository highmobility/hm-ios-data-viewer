//
//  OAuthUpdatable.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 15/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation


protocol OAuthUpdatable {

    func oauthReceivedRedirect(_ result: OAuthManager.RedirectResult)
}
