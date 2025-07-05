//
//  WeatherForcastService.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/5.
//

import Foundation
import Combine

protocol WeatherServiceProtocol {
    func fetchWeatherForecast (lat: Double, lon: Double) -> AnyPublisher<WeatherForecastResponse, Error>
}

class WeatherForcastService:WeatherServiceProtocol {
    
    func fetchWeatherForecast (lat: Double, lon: Double) -> AnyPublisher<WeatherForecastResponse, Error> {
        let urlString = "\(APIConfig.baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(APIConfig.apiKey)&units=metric&lang=\(APIConfig.lang)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherForecastResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
