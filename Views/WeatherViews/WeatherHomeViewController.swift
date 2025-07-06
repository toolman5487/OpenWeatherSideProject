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
    private var cancellables = Set<AnyCancellable>()
    private var hasLocation: Bool = false
    private var currentWeatherVM = CurrentWeatherViewModel()
    private var weatherForecastVM = WeatherForecastViewModel()
    private var weatherInfoItems: [(title: String, value: String)] = []
    
    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .bold(size: 72)
        label.textColor = .label
        label.textAlignment = .center
        label.isHidden = false
        label.layer.cornerRadius = 36
        label.layer.masksToBounds = true
        return label
    }()
    
    private let weatherImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.tintColor = .label
        image.clipsToBounds = true
        image.layer.cornerRadius = 28
        image.layer.masksToBounds = true
        return image
    }()
    
    private let weatherDescLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.isHidden = true
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()
    
    private lazy var weatherStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [weatherImageView, weatherDescLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.layer.cornerRadius = 16
        stack.layer.masksToBounds = true
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
        collection.layer.cornerRadius = 16
        collection.layer.masksToBounds = true
        return collection
    }()
    
    private lazy var forecastTableView: WeatherTableView = {
        let tableView = WeatherTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WeatherForecastTableViewCell.self, forCellReuseIdentifier: "WeatherForecastTableViewCell")
        tableView.isHidden = false
        tableView.layer.cornerRadius = 12
        tableView.layer.masksToBounds = true
        return tableView
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
        view.addSubview(infoCollectionView)
        view.addSubview(forecastTableView)
        
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
        
        infoCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weatherStackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
        }
        
        forecastTableView.snp.makeConstraints { make in
            make.top.equalTo(infoCollectionView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
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
                self.weatherForecastVM.fetchForecast(
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
            }
            .store(in: &cancellables)
        
        weatherForecastVM.$forecast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] forecast in
                guard let self = self else { return }
                if let forecast = forecast {
                    print("VM: \(forecast)")
                    self.forecastTableView.isHidden = false
                    self.forecastTableView.reloadData()
                } else {
                    self.forecastTableView.isHidden = true
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
        forecastTableView.isHidden = true
        LocationManager.shared.requestLocation()
    }
    
    
    // MARK: - Data Models
    
    private struct ForecastGroup {
        let date: String
        let items: [ForecastItem]
    }
    
    // MARK: - Date Formatting
    
    private enum DateFormat {
        static let input = "yyyy-MM-dd HH:mm:ss"
        static let display = "MM月dd日 EEEE"
        static let time = "HH:mm"
    }
    
    private lazy var inputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.input
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.display
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.time
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
    // MARK: - Data Processing
    
    private func getGroupedForecastData() -> [ForecastGroup] {
        guard let forecast = weatherForecastVM.forecast else { return [] }
        let groupedData = groupForecastByDate(forecast.list)
        let sortedGroups = sortGroupsByDate(groupedData)
        
        return sortedGroups
    }
    
    private func groupForecastByDate(_ items: [ForecastItem]) -> [String: [ForecastItem]] {
        var groupedData: [String: [ForecastItem]] = [:]
        
        for item in items {
            guard let date = inputDateFormatter.date(from: item.dt_txt) else { continue }
            let dateKey = displayDateFormatter.string(from: date)
            
            if groupedData[dateKey] == nil {
                groupedData[dateKey] = []
            }
            groupedData[dateKey]?.append(item)
        }
        
        return groupedData
    }
    
    private func sortGroupsByDate(_ groupedData: [String: [ForecastItem]]) -> [ForecastGroup] {
        let sortedKeys = groupedData.keys.sorted { key1, key2 in
            guard let date1 = displayDateFormatter.date(from: key1),
                  let date2 = displayDateFormatter.date(from: key2) else { return false }
            return date1 < date2
        }
        
        return sortedKeys.map { key in
            ForecastGroup(date: key, items: groupedData[key] ?? [])
        }
    }
    
    private func formatTime(from dateString: String) -> String {
        guard let date = inputDateFormatter.date(from: dateString) else { return dateString }
        return timeFormatter.string(from: date)
    }
}

extension WeatherHomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherInfoCell", for: indexPath) as? WeatherInfoCell else {
            return UICollectionViewCell()
        }
        if weatherInfoItems.count > indexPath.item {
            let item = weatherInfoItems[indexPath.item]
            cell.configure(title: item.title, value: item.value)
        } else {
            cell.configure(title: "--", value: "--")
        }
        return cell
    }
}

extension WeatherHomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return getGroupedForecastData().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let groupedData = getGroupedForecastData()
        guard section < groupedData.count else { return 0 }
        return groupedData[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "WeatherForecastTableViewCell",
            for: indexPath
        ) as? WeatherForecastTableViewCell else {
            return UITableViewCell()
        }
        
        let groupedData = getGroupedForecastData()
        guard indexPath.section < groupedData.count,
              indexPath.row < groupedData[indexPath.section].items.count else {
            return UITableViewCell()
        }
        
        let item = groupedData[indexPath.section].items[indexPath.row]
        let timeString = formatTime(from: item.dt_txt)
        let tempString = String(format: "%.0f°", item.main.temp)
        let desc = item.weather.first?.description ?? "--"
        let iconName = item.weather.first?.icon ?? ""
        let icon = UIImage(systemName: weatherForecastVM.getSystemImageName(for: iconName))
        
        cell.configure(time: timeString, icon: icon, temp: tempString, desc: desc)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let groupedData = getGroupedForecastData()
        guard section < groupedData.count else { return nil }
        
        let header = UIView()
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = header.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.addSubview(blurView)
        
        let label = UILabel()
        label.text = groupedData[section].date
        label.font = .bold(size: 16)
        label.textColor = .label
        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
