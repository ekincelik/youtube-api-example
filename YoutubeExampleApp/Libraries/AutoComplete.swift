//
//  AutoComplete.swift
//  AutoComplete
//
//  Created by trungnd on 10/3/16.
//  Copyright © 2016 redvn. All rights reserved.
//

import Foundation

public enum AutoCompleteError: Error {
    case invalidURL(String)
    case invalidData(String)
    case failedToRetrieveData(String)
    case failToDecodeData(String)
    case serializationError(String)
}

public enum AutoComplete {
    static let baseURL = "http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&alt=json&q="

    /// Fetch google's autocomplete suggestions for a given seed term
    ///
    /// - Parameters:
    ///   - term: a seed term
    ///   - completionHandler: A completion handler after finishing task
    public static func getQuerySuggestions(_ term: String, completionHandler: @escaping ([String]?, Error?) -> Void) {
        DispatchQueue.global().async {
            let URLString = baseURL + term

            guard let url = URL(string: URLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "") else {
                completionHandler(nil, AutoCompleteError.invalidURL(URLString))
                return
            }

            guard let data = try? Data(contentsOf: url) else {
                completionHandler(nil, AutoCompleteError.invalidData(URLString))
                return
            }

            guard let response = String(data: data, encoding: String.Encoding.ascii) else {
                completionHandler(nil, AutoCompleteError.failToDecodeData(URLString))
                return
            }

            var JSON: NSString?
            let scanner = Scanner(string: response)

            scanner.scanUpTo("[[", into: nil) // Scan to where the JSON begins
            scanner.scanUpTo(",{", into: &JSON)

            guard JSON != nil else {
                completionHandler(nil, AutoCompleteError.failedToRetrieveData(URLString))
                return
            }

            // The idea is to identify where the "real" JSON begins and ends.
            JSON = NSString(format: "%@", JSON!)

            do {
                let array = try JSONSerialization.jsonObject(with: JSON!.data(using: String.Encoding.utf8.rawValue) ?? Data(), options: .allowFragments)
                var result = [String]()

                for i in 0 ..< (array as AnyObject).count {
                    for j in 0 ..< 1 {
                        let suggestion = ((array as AnyObject).object(at: i) as AnyObject).object(at: j)
                        if let str = suggestion as? String {
                            result.append(str)
                        }
                    }
                }

                DispatchQueue.main.async {
                    completionHandler(result, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, AutoCompleteError.serializationError(URLString))
                }
            }
        }
    }
}
