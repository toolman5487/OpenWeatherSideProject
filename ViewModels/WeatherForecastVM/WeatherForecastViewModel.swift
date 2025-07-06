//
//  WeatherForcastViewModel.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/5.
//

import Foundation
import Combine

class WeatherForecastViewModel: ObservableObject {
    
    @Published var forecast: WeatherForecastResponse?
    @Published var isLoading = false
    @Published var error: Error?
    private let service: WeatherServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    init(service: WeatherServiceProtocol = WeatherForcastService()) {
        self.service = service
    }
    
    func getSystemImageName(for iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark"
        }
    }

    func fetchForecast(lat: Double, lon: Double) {
        isLoading = true
        error = nil
        service.fetchWeatherForecast(lat: lat, lon: lon)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                self?.forecast = response
            })
            .store(in: &cancellables)
    }
}
