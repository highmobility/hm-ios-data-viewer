//
//  OAuthManager.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 25/08/2017.
//  Copyright © 2017 High-Mobility GmbH. All rights reserved.
//

import Foundation


struct OAuthManager {

    enum RedirectResult {
        case successful(accessTokenCode: String, state: String?)
        case error(reason: String, state: String?)
        case unknown
    }


    // MARK: Type Methods

    static func oauthURL(authURI: String, clientID: String, redirectScheme: String, scope: String, appID: String) -> URL? {
        var completeURI: String = authURI

        completeURI += "?client_id=" + clientID
        completeURI += "&redirect_uri=" + redirectScheme
        completeURI += "&scope=" + scope
        completeURI += "&app_id=" + appID

        guard let url = URL(string: completeURI) else {
            return nil
        }

        return url
    }

    static func parseRedirectURL(_ redirectURL: URL) -> RedirectResult {
        guard let queryItems = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)?.queryItems else {
            return .unknown
        }

        let stateValue = queryItems.first(where: { $0.name == "state" })?.value

        if let errorValue = queryItems.first(where: { $0.name == "error" })?.value {
            return .error(reason: errorValue, state: stateValue)
        }
        else if let codeValue = queryItems.first(where: { $0.name == "code" })?.value {
            return .successful(accessTokenCode: codeValue, state: stateValue)
        }
        else {
            return .unknown
        }
    }

    static func requestAccessToken(tokenURI: String, redirectScheme: String, clientID: String, code: String, completion: @escaping (Result<String>) -> Void) {
        var completeURI: String = tokenURI

        completeURI += "?client_id=" + clientID
        completeURI += "&code=" + code
        completeURI += "&redirect_uri=" + redirectScheme

        guard let url = URL(string: completeURI) else {
            return completion(.failure("Failed to combine URL from: \(completeURI)"))
        }

        let request = URLRequest(url: url, httpMethod: "POST")

        URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard error == nil else {
                return completion(.failure("Request returned an error: \(error!)"))
            }

            guard let data = data else {
                return completion(.failure("Missing data, error: \(String(describing: error)), response: \(String(describing: response))"))
            }

            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                let hex = data.map { String(format: "%02X", $0) }.joined()

                return completion(.failure("Failed to create JSON object from: \(hex)"))
            }

            guard let accessToken = json?["access_token"] as? String else {
                return completion(.failure("Failed to extract Access Token from json: \(String(describing: json))"))
            }

            completion(.success(accessToken))
        }.resume()
    }
}
