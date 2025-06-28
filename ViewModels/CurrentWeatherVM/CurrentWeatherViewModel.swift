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
    
    init(service: CurrentWeatherServiceProtocol = CurrentWeatherService()) {
        self.service = service
    }
    
    func fetchWeather(lat: Double, lon: Double) {
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
