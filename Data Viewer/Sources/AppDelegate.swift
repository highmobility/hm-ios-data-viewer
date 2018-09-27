//
//  AppDelegate.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import UIKit


@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let parsedResult = OAuthManager.parseRedirectURL(url)

        switch parsedResult {
        case .unknown:
            print("Can't open this app with URL:", url.absoluteString)

            return false

        default:
            HighMobilityManager.shared.oauthUpdatesSender?.oauthReceivedRedirect(parsedResult)

            return true
        }
    }
}
