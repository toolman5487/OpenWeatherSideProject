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
   
    private let geocoder = CLGeocoder()
    private var loadingView: LottieAnimationView?
    private var currentWeatherVM: CurrentWeatherViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var hasLocation: Bool = false

    private let weatherImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        iv.clipsToBounds = true
        return iv
    }()

    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 56, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.text = "--°"
        label.isHidden = true
        return label
    }()

    private let highLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "H: --°"
        label.isHidden = true
        return label
    }()

    private let lowLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "L: --°"
        label.isHidden = true
        return label
    }()

    private let weatherDescLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.text = "--"
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
        view.addSubview(weatherImageView)
        view.addSubview(tempLabel)
        view.addSubview(highLabel)
        view.addSubview(lowLabel)
        view.addSubview(weatherDescLabel)
        
        weatherImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(32)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120)
        }

        tempLabel.snp.makeConstraints { make in
            make.top.equalTo(weatherImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        highLabel.snp.makeConstraints { make in
            make.top.equalTo(tempLabel.snp.bottom).offset(12)
            make.right.equalTo(view.snp.centerX).offset(-8)
        }

        lowLabel.snp.makeConstraints { make in
            make.top.equalTo(tempLabel.snp.bottom).offset(12)
            make.left.equalTo(view.snp.centerX).offset(8)
        }
        
        weatherDescLabel.snp.makeConstraints { make in
            make.top.equalTo(highLabel.snp.bottom).offset(18)
            make.centerX.equalToSuperview()
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
    
}
