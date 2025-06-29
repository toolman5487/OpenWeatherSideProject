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
import SkeletonView

class WeatherHomeViewController: UIViewController {
    
    private let geocoder = CLGeocoder()
    private var loadingView: LottieAnimationView?
    private var cancellables = Set<AnyCancellable>()
    private var hasLocation: Bool = false
    private var currentWeatherVM = CurrentWeatherViewModel()
    
    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 72, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.text = "--°"
        label.isHidden = true
        return label
    }()
    
    private let weatherImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.tintColor = .label
        image.clipsToBounds = true
        return image
    }()
    
    private let weatherDescLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.text = "--"
        label.isHidden = true
        return label
    }()
    
    private lazy var weatherStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [weatherImageView, weatherDescLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let highLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "H: --°"
        label.isHidden = true
        return label
    }()
    
    private let lowLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "L: --°"
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavgationBar()
        setupUI()
        bindingVM()
    }
    
    private func setNavgationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let systemName = hasLocation ? "location.fill" : "location"
        let button = UIBarButtonItem(
            image: UIImage(systemName: systemName),
            style: .plain,
            target: self,
            action: #selector(locationButtonTapped)
        )
        button.tintColor = .label
        navigationItem.rightBarButtonItem = button
    }
    
    private func setupUI() {
        view.addSubview(tempLabel)
        view.addSubview(weatherStackView)
        view.addSubview(highLabel)
        view.addSubview(lowLabel)
        
        tempLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.centerX.equalToSuperview()
        }
        
        weatherStackView.snp.makeConstraints { make in
            make.top.equalTo(tempLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        weatherImageView.snp.makeConstraints { make in
            make.width.height.equalTo(56)
        }
        
        highLabel.snp.makeConstraints { make in
            make.top.equalTo(weatherStackView.snp.bottom).offset(12)
            make.trailing.equalTo(view.snp.centerX).offset(-32)
        }
        
        lowLabel.snp.makeConstraints { make in
            make.top.equalTo(weatherStackView.snp.bottom).offset(12)
            make.leading.equalTo(view.snp.centerX).offset(32)
        }
    }
    
    private func bindingVM() {
        showNavigationLoading(true)
        LocationManager.shared.requestLocation()
        LocationManager.shared.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                self.hasLocation = true
                self.setNavgationBar()
                self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    DispatchQueue.main.async {
                        self.showNavigationLoading(false)
                        if let name = placemarks?.first?.locality {
                            self.title = name
                        } else {
                            self.hasLocation = false
                            self.setNavgationBar()
                            self.title = "定位中..."
                        }
                    }
                }
                self.currentWeatherVM.fetchCurrentWeather(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
            }
            .store(in: &cancellables)
        
        currentWeatherVM.$weather
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in
                guard let self = self, let weather = weather else { return }
                self.tempLabel.text = String(format: "%.0f°", weather.main.temp)
                self.tempLabel.isHidden = false
                self.setHighLabel(temp: Int(weather.main.temp_max))
                
                self.setLowLabel(temp: Int(weather.main.temp_min))
                self.weatherDescLabel.text = weather.weather.first?.description ?? "--"
                self.weatherDescLabel.isHidden = false
                self.weatherImageView.image = UIImage(systemName: self.currentWeatherVM.systemImageName)
            }
            .store(in: &cancellables)
    }
    
    private func showNavigationLoading(_ show: Bool) {
        if show {
            self.title = nil
            let animationView = LottieManager.makeLoadingView(named: "loadingPoint")
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
            animationView.frame = container.bounds
            container.addSubview(animationView)
            animationView.play()
            self.navigationItem.titleView = container
        } else {
            self.navigationItem.titleView = nil
        }
    }
    
    @objc private func locationButtonTapped() {
        showNavigationLoading(true)
        hasLocation = false
        setNavgationBar()
        LocationManager.shared.requestLocation()
    }
    
    private func setHighLabel(temp: Int) {
        let highText = NSMutableAttributedString(
            string: "最高溫度\n",
            attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.secondaryLabel]
        )
        highText.append(NSAttributedString(
            string: "\(temp)°",
            attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .bold), .foregroundColor: UIColor.secondaryLabel]
        ))
        highLabel.attributedText = highText
        highLabel.numberOfLines = 2
        highLabel.textAlignment = .center
        highLabel.isHidden = false
    }
    
    private func setLowLabel(temp: Int) {
        let lowText = NSMutableAttributedString(
            string: "最低溫度\n",
            attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.secondaryLabel]
        )
        lowText.append(NSAttributedString(
            string: "\(temp)°",
            attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .bold), .foregroundColor: UIColor.secondaryLabel]
        ))
        lowLabel.attributedText = lowText
        lowLabel.numberOfLines = 2
        lowLabel.textAlignment = .center
        lowLabel.isHidden = false
    }
}
