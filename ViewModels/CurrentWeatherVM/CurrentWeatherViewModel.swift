//
//  CurrentWeatherViewModel.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/28.
//

import Foundation
import Combine

class CurrentWeatherViewModel: ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    private let service: CurrentWeatherServiceProtocol
    @Published var weather: CurrentWeatherResponse?
    @Published var isLoading = false
    @Published var error: Error?
    
    var systemImageName: String {
        guard let icon = weather?.weather.first?.icon else { return "questionmark" }
        switch icon {
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
    
    init(service: CurrentWeatherServiceProtocol = CurrentWeatherService()) {
        self.service = service
    }
    
    func fetchCurrentWeather(lat: Double, lon: Double) {
        isLoading = true
        error = nil
        service.fetchWeather(lat: lat, lon: lon)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                }
            }, receiveValue: { [weak self] weather in
                self?.weather = weather
            })
            .store(in: &cancellables)
    }
}
