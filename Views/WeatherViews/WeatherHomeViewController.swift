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
    
    private var cancellables = Set<AnyCancellable>()
    
    private let logolabel: UILabel = {
        let label = UILabel()
        label.text = "OpenWeather"
        label.textColor = .label
        label.font = .systemFont(ofSize: 36, weight: .bold)
        return label
    }()
    
    private let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavg()
        setupUI()
        bindingVM()
    }
    
    private func setNavg() {
        self.title = "天氣"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    private func setupUI() {
        view.addSubview(logolabel)
        logolabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func bindingVM() {
        LocationManager.shared.requestLocation()
        LocationManager.shared.$location
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let name = placemarks?.first?.locality {
                        DispatchQueue.main.async {
                            self.navigationItem.title = name
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.navigationItem.title = "未知地區"
                        }
                    }
                }
                self.logolabel.text = "(\(lat), \(lon))"
            }
            .store(in: &cancellables)
    }
}
