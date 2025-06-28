//
//  CurrentWeatherService.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/28.
//

import Foundation
import Combine

protocol CurrentWeatherServiceProtocol {
    func fetchWeather(lat: Double, lon: Double) -> AnyPublisher<CurrentWeatherResponse, Error>
}

class CurrentWeatherService: CurrentWeatherServiceProtocol {
    
    func fetchWeather(lat: Double, lon: Double) -> AnyPublisher<CurrentWeatherResponse, Error> {
        let urlString = "\(APIConfig.baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(APIConfig.apiKey)&units=metric&lang=\(APIConfig.lang)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CurrentWeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
