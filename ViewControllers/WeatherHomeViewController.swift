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
    private lazy var weatherHomeView = WeatherHomeView()
    
    override func loadView() {
        view = weatherHomeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavgationBar()
        setupDelegates()
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
    
    private func setupDelegates() {
        weatherHomeView.infoCollectionView.dataSource = self
        weatherHomeView.infoCollectionView.delegate = self
        weatherHomeView.infoCollectionView.register(WeatherInfoCell.self, forCellWithReuseIdentifier: "WeatherInfoCell")
        
        weatherHomeView.forecastTableView.dataSource = self
        weatherHomeView.forecastTableView.delegate = self
        weatherHomeView.forecastTableView.register(WeatherForecastTableViewCell.self, forCellReuseIdentifier: "WeatherForecastTableViewCell")
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
                self.weatherHomeView.tempLabel.text = String(format: "%.0f°", weather.main.temp)
                self.weatherHomeView.tempLabel.isHidden = false
                self.weatherHomeView.weatherDescLabel.text = weather.weather.first?.description ?? "--"
                self.weatherHomeView.weatherDescLabel.isHidden = false
                self.weatherHomeView.weatherImageView.image = UIImage(systemName: self.currentWeatherVM.systemImageName)
                
                self.weatherInfoItems = [
                    (title: "最低", value: String(format: "%.0f°", weather.main.temp_min)),
                    (title: "最高", value: String(format: "%.0f°", weather.main.temp_max)),
                    (title: "體感", value: String(format: "%.0f°", weather.main.feels_like)),
                    (title: "濕度", value: "\(weather.main.humidity)%"),
                    (title: "氣壓", value: "\(weather.main.pressure) hPa"),
                    (title: "海平面", value: weather.main.sea_level != nil ? "\(weather.main.sea_level!) hPa" : "--"),
                    (title: "地面", value: weather.main.grnd_level != nil ? "\(weather.main.grnd_level!) hPa" : "--")
                ]
                self.weatherHomeView.infoCollectionView.reloadData()
            }
            .store(in: &cancellables)
        
        weatherForecastVM.$forecast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] forecast in
                guard let self = self else { return }
                if let forecast = forecast {
                    print("VM: \(forecast)")
                    self.weatherHomeView.forecastTableView.isHidden = false
                    self.weatherHomeView.forecastTableView.reloadData()
                } else {
                    self.weatherHomeView.forecastTableView.isHidden = true
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
        weatherHomeView.forecastTableView.isHidden = true
        LocationManager.shared.requestLocation()
    }
    
    private struct ForecastGroup {
        let date: String
        let items: [ForecastItem]
    }
    
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
        header.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        header.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
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
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let groupedData = getGroupedForecastData()
        if section == groupedData.count - 1 {
            let footerView = UIView()
            footerView.backgroundColor = .clear
            return footerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let groupedData = getGroupedForecastData()
        if section == groupedData.count - 1 {
            return max(40, tableView.frame.height * 0.1)
        }
        return 0
    }
}
