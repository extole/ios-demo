//
//  Token.swift
//  firstapp
//
//  Created by rtibin on 1/24/19.
//  Copyright © 2019 rtibin. All rights reserved.
//

import Foundation
import os.log

enum ExtoleApiError {
    case serverError(error: Error)
    case decodingError(data: Data)
    case noContent
    case genericError(errorData: ErrorData)
}

enum GetTokenError : Error {
    case invalidProtocol(error: ExtoleApiError)
    case invalidAccessToken
}

public struct ConsumerToken : Codable {
    let access_token: String
    let expires_in: Int
    let scopes: [String]
    let capabilities: [String]
}

extension Program {

    func tokenUrl() -> URL {
        return URL.init(string: "/api/v4/token/", relativeTo: baseUrl)!
    }

    private func procesTokenRequest(with request: URLRequest, responseHandler: @escaping (_: ConsumerToken?, _: GetTokenError?) ->Void) {
        processRequest(with: request) { data, error in
            if let apiError = error {
                switch(apiError) {
                case .genericError(let errorData) : do {
                    switch(errorData.code) {
                    case "invalid_access_token": responseHandler(nil, .invalidAccessToken)
                    default:  responseHandler(nil, .invalidProtocol(error: .genericError(errorData: errorData)))
                    }
                    }
                default : responseHandler(nil, .invalidProtocol(error: apiError))
                }
                return
            }
            if let data = data {
                let decodedToken : ConsumerToken? = tryDecode(data: data)
                if let token = decodedToken {
                    responseHandler(token, nil)
                } else {
                    responseHandler(nil, .invalidProtocol(error: .decodingError(data: data)))
                }
            }
        }
    }
    
    public func getToken(callback : @escaping (_: ConsumerToken?, _: GetTokenError?) -> Void) {
        let request = getRequest(url: tokenUrl())
        procesTokenRequest(with: request, responseHandler: callback)
    }
    
    public func getToken(token: String, callback : @escaping (_: ConsumerToken?, _: GetTokenError?) -> Void) {
        let url = URL.init(string: token, relativeTo: tokenUrl())!
        let request = getRequest(url: url)
        procesTokenRequest(with: request, responseHandler: callback)
    }
    
    public func deleteToken(token: String, callback : @escaping (_: GetTokenError?) -> Void) {
        let url = URL.init(string: token, relativeTo: tokenUrl())!
        let request = newRequest(url: url, method: "DELETE")
        os_log("deleteToken : %{public}@", log: NetworkLog, type: OSLogType.debug, url.absoluteString)
        processRequest(with: request) { data, error in
            if let apiError = error {
                switch(apiError) {
                case .genericError(let errorData) : do {
                    switch(errorData.code) {
                    case "invalid_access_token": callback(.invalidAccessToken)
                    default:  callback(.invalidProtocol(error: .genericError(errorData: errorData)))
                    }
                    }
                default : callback(.invalidProtocol(error: apiError))
                }
                return
            }
            callback(nil)
        }
    }
}

