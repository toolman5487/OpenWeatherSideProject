//
//  WeatherForcastViewModel.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/5.
//

import Foundation
import Combine

class WeatherForcastViewModel: ObservableObject {
    
    @Published var forecast: WeatherForecastResponse?
    @Published var isLoading = false
    @Published var error: Error?
    private let service: WeatherServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    init(service: WeatherServiceProtocol = WeatherForcastService()) {
        self.service = service
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
