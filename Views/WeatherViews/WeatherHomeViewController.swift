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
import Lottie

class WeatherHomeViewController: UIViewController {
    
    private var currentWeatherVM: CurrentWeatherViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    private let weatherImageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "questionmark")
        image.contentMode = .scaleAspectFit
        image.tintColor = .label
        image.clipsToBounds = true
        return image
    }()
    private let weatherLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = .label
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .center
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
        view.addSubview(weatherImageView)
        view.addSubview(weatherLabel)
        
        weatherImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(32)
            make.width.height.equalTo(80)
        }
        weatherLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(weatherImageView.snp.bottom).offset(16)
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
                _ = location.coordinate.latitude
                _ = location.coordinate.longitude
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
            }
            .store(in: &cancellables)
    }
    
    
}
