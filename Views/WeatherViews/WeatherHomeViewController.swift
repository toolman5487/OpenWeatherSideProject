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
    private var weatherInfoItems: [(title: String, value: String)] = []
    
    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 72, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.text = "--°"
        label.isHidden = false
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
    
    private lazy var infoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.itemSize = CGSize(width: 72, height: 72)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(WeatherInfoCell.self, forCellWithReuseIdentifier: "WeatherInfoCell")
        return collection
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavgationBar()
        setupUI()
        bindingVM()
        tempLabel.showAnimatedGradientSkeleton()
        weatherStackView.showAnimatedGradientSkeleton()
        infoCollectionView.isSkeletonable = true
        infoCollectionView.showAnimatedGradientSkeleton()
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
        
        tempLabel.isSkeletonable = true
        weatherStackView.isSkeletonable = true
        
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
        
        view.addSubview(infoCollectionView)
        infoCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weatherStackView.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(72)
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
                self.weatherDescLabel.text = weather.weather.first?.description ?? "--"
                self.weatherDescLabel.isHidden = false
                self.weatherImageView.image = UIImage(systemName: self.currentWeatherVM.systemImageName)
                
                self.tempLabel.hideSkeleton()
                self.weatherStackView.hideSkeleton()
                
                self.weatherInfoItems = [
                    (title: "最低", value: String(format: "%.0f°", weather.main.temp_min)),
                    (title: "最高", value: String(format: "%.0f°", weather.main.temp_max)),
                    (title: "體感", value: String(format: "%.0f°", weather.main.feels_like)),
                    (title: "濕度", value: "\(weather.main.humidity)%"),
                    (title: "氣壓", value: "\(weather.main.pressure) hPa"),
                    (title: "海平面", value: weather.main.sea_level != nil ? "\(weather.main.sea_level!) hPa" : "--"),
                    (title: "地面", value: weather.main.grnd_level != nil ? "\(weather.main.grnd_level!) hPa" : "--")
                ]
                self.infoCollectionView.reloadData()
                self.infoCollectionView.hideSkeleton()
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

extension WeatherHomeViewController: SkeletonCollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> SkeletonView.ReusableCellIdentifier {
        return "WeatherInfoCell"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weatherInfoItems.isEmpty ? 7 : weatherInfoItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherInfoCell", for: indexPath) as? WeatherInfoCell else {
            return UICollectionViewCell()
        }
        let item = weatherInfoItems[indexPath.item]
        cell.configure(title: item.title, value: item.value)
        return cell
    }
}
