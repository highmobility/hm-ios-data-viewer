//
//  AppDelegate.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import HMKit
import UIKit


@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    enum AccessTokenMethod {
        case oauth(HMOAuth.RequiredValues)
        case token(String)
    }


    var accessTokenMethod: AccessTokenMethod!
    var window: UIWindow?


    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initialiseAccessTokenMethod()
        initialiseHMKit()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return HMOAuth.shared.handleCallback(with: url)
    }
}

private extension AppDelegate {

    func initialiseAccessTokenMethod() {
        /*
         The .accessTokenMethod has to be set before the app can get an Access Certificate.

         The "flow" is activated when tapping the "Link Vehicle" button:
            .token simply downloads the Access Certificate from the server
            .oauth opens SFSafariViewController to authenticate and when successful – download the Access Certificate
        */

        <#Set the .accessTokenMethod here#>

        guard accessTokenMethod != nil else {
            fatalError("Need to set the .accessTokenMethod to get an Access Certificate")
        }
    }

    func initialiseHMKit() {
        /*
         Initialise the HMKit with the snippet from Developer Center.
         It's found under an App -> Device Certificates.

         Example (with invalid values):
             do {
                 try HMKit.shared.initialise(deviceCertificate: "GzdMivmirTFExolfeyYDmJnwdsLCFgKrQKTdM91UHW/JTEdVcjHRFBxPp8kxhL1PXulMBF6dSOP",
                                             devicePrivateKey: "v6ZsHyqnqvH7XRYv34jHSg=",
                                             issuerPublicKey: "WtZ5CNQBmwHRtKn4iyMM6OafCsraBSoFfrgDNAmUh4DVYnxq=")
             }
             catch {
                 // Handle the error
                 print("Invalid initialisation parameters, please double-check the snippet: \(error)")
             }
         */

        <#Insert the HMKit's INITIALISATION SNIPPET here#>

        guard HMKit.shared.certificate != nil else {
            fatalError("Need to initialise the HMKit")
        }
    }
}
