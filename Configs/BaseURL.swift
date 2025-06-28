//
//  BaseURL.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/28.
//

import Foundation

struct APIConfig {
    static let baseURL = "https://api.openweathermap.org/data/2.5"
    static let lang = "zh_tw"
    static var apiKey: String {
        guard let key = Bundle.main.infoDictionary?["OpenWeatherAPIKey"] as? String else {
            fatalError("APIKey Error!")
        }
        return key
    }
}
