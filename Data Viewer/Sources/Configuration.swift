//
//  Configuration.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 09/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import Foundation
import HMKit


// TODO: Refactor this to HMManager
class Configuration {

    static let shared = Configuration()


    // MARK: iVars

    private(set) var vehicleSerial: Data?
    private var appID: String!
    private var authURI: String!
    private var clientID: String!
    private var redirectScheme: String!
    private var scope: String!
    private var tokenURI: String!

    var oauthURL: URL? {
        return OAuthManager.oauthURL(authURI: authURI, clientID: clientID, redirectScheme: redirectScheme, scope: scope, appID: appID)
    }


    // MARK: Methods

    func downloadAccessCertificates(accessTokenCode code: String, completion: @escaping (Result<ConnectionState>) -> Void) {
        guard LocalDevice.shared.certificate != nil else {
            return completion(.failure("LocalDevice uninitialised!"))
        }

        // First download the TOKEN for Access Certificates
        OAuthManager.requestAccessToken(tokenURI: tokenURI, redirectScheme: redirectScheme, clientID: clientID, code: code) {
            switch $0 {
            case .failure(let reason):
                completion(.failure("Failed to download Access Token: \(reason)"))

            case .success(let accessToken):
                // Then download the CERTIFICATES
                self.downloadAccessCertificates(token: accessToken, completion: completion)
            }
        }
    }

    func initialise(delegate: LocalDeviceDelegate) throws {
        LocalDevice.shared.delegate = delegate

        // OAuth configuration
        appID = "A0F90F9AB61ED3649ADE165F"
        authURI = "https://developers.high-mobility.com/hm_cloud/o/159395ba-f738-4c7a-a826-49205737d7cf/oauth"
        clientID = "e3a34856-48c4-4e18-83b7-9d8249496d75"
        redirectScheme = "com.hm.dev.1525347432-8qrtgjeqjfxq"
        scope = "<#String#>"
        tokenURI = "https://developers.high-mobility.com/hm_cloud/api/v1/159395ba-f738-4c7a-a826-49205737d7cf/oauth/access_tokens"

        // LocalDevice configuration
        try LocalDevice.shared.initialise(deviceCertificate: "dGVzdKD5D5q2HtNkmt4WX+V7QiD7FtBFLrmnbuUFzJxCpRnfoMP4VkGOqpAYyoAZirRJIH7CR01TpPIM6Vps7r4pVH54tDGZiPi4ekCjRY1Ex+IjJdyKyrzt4rqjx7ziVJFGGZgEHYIDaPxcpojSNltCdKD36WX7w//0GHTtBXLkLdsU0947di9RHetOD+J0L7GeQGveJWDj",
                                          devicePrivateKey: "r2RZcb1TNZrVPP6YaJoL+qiAID1mjwEE83FOEng938M=",
                                          issuerPublicKey: "mqFX9i6iNMs2KjNfv+R9YqREtJaDAYhgeWZsVSEmI95GRfIzTTXWJQI/VfX3XDs4NRO0lWMSQwNgl1lER0h+wA==")
    }


    // MARK: Init

    private init() {
        LocalDevice.loggingOptions = [.command, .error, .general]
    }
}

private extension Configuration {

    func downloadAccessCertificates(token: String, completion: @escaping (Result<ConnectionState>) -> Void) {
        // Clean the DB from old certificates
        LocalDevice.shared.resetStorage()

        // Download new Access Certificates
        do {
            try Telematics.downloadAccessCertificate(accessToken: token) {
                switch $0 {
                case .failure(let reason):
                    completion(.failure("Failed to download Access Certificate: \(reason)"))

                case .success(let serial):
                    self.vehicleSerial = serial

                    LocalDevice.shared.configuration.broadcastingFilter = serial

                    completion(.success(.certificatesDownloaded))
                }
            }
        }
        catch {
            completion(.failure("Failed to start downloading Access Certificates: \(error)"))
        }
    }
}
