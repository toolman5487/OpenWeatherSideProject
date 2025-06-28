//
//  WeatherHomeViewController.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/27.
//

import Foundation
import UIKit
import SnapKit
import CoreLocation
import Combine

class WeatherHomeViewController: UIViewController {
    
    private let logolabel: UILabel = {
        let label = UILabel()
        label.text = "OpenWeather"
        label.textColor = .label
        label.font = .systemFont(ofSize: 36, weight: .bold)
        return label
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.shared.requestLocation()
        LocationManager.shared.$location
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                self?.logolabel.text = "(\(lat), \(lon))"
            }
            .store(in: &cancellables)
        
        self.title = "天氣"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        view.addSubview(logolabel)
        logolabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
