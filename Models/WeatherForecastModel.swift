//
//  WeatherForecastModel.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/30.
//

import Foundation

struct WeatherForecastResponse: Codable {
    let cod: String
    let message: Int
    let cnt: Int
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Codable {
    let dt: Int
    let main: ForecastMain
    let weather: [ForecastWeather]
    let clouds: ForecastClouds
    let wind: ForecastWind
    let visibility: Int
    let pop: Double
    let sys: ForecastSys
    let dt_txt: String
    let rain: ForecastRain?
}

struct ForecastMain: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
    let sea_level: Int
    let grnd_level: Int
    let humidity: Int
    let temp_kf: Double
}

struct ForecastWeather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct ForecastClouds: Codable {
    let all: Int
}

struct ForecastWind: Codable {
    let speed: Double
    let deg: Int
    let gust: Double
}

struct ForecastSys: Codable {
    let pod: String
}

struct ForecastRain: Codable {
    let threeH: Double?
    
    private enum CodingKeys: String, CodingKey {
        case threeH = "3h"
    }
}

struct ForecastCity: Codable {
    let id: Int
    let name: String
    let coord: ForecastCoord
    let country: String
    let population: Int
    let timezone: Int
    let sunrise: Int
    let sunset: Int
}

struct ForecastCoord: Codable {
    let lat: Double
    let lon: Double
}
