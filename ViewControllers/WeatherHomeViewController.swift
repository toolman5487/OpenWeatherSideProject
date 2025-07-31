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
import CombineCocoa
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
    
    // 搜尋相關屬性
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        
        // 基本設定
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // 背景顏色設定
        searchController.view.backgroundColor = .systemBackground
        searchController.searchBar.backgroundColor = .systemBackground
        searchController.searchBar.barTintColor = .systemBackground
        
        // 搜尋欄設定
        searchController.searchBar.placeholder = "搜尋城市..."
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .systemBlue
        
        // 搜尋欄外觀
        searchController.searchBar.layer.cornerRadius = 10
        searchController.searchBar.clipsToBounds = true
        
        // 按鈕文字
        searchController.searchBar.setShowsCancelButton(true, animated: false)
        searchController.searchBar.showsCancelButton = true
        
        // 鍵盤設定
        searchController.searchBar.keyboardType = .default
        searchController.searchBar.returnKeyType = .search
        searchController.searchBar.enablesReturnKeyAutomatically = true
        
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWeatherHomeView()
        setNavgationBar()
        setupDelegates()
        setupSearchBinding()
        bindingVM()
    }
    
    private func setupSearchBinding() {
        // 使用 CombineCocoa 處理搜尋文字變化
        searchController.searchBar.textDidChangePublisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.handleSearchText(searchText)
            }
            .store(in: &cancellables)
        
        // 處理搜尋取消
        searchController.searchBar.cancelButtonClickedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.handleSearchCancel()
            }
            .store(in: &cancellables)
        
        // 處理搜尋開始
        searchController.searchBar.searchButtonClickedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.handleSearchButtonClicked()
            }
            .store(in: &cancellables)
    }
    
    private func handleSearchText(_ searchText: String) {
        print("搜尋文字: \(searchText)")
        // 這裡可以實現搜尋邏輯
    }
    
    private func handleSearchCancel() {
        print("搜尋已取消")
        // 重置搜尋狀態
    }
    
    private func handleSearchButtonClicked() {
        print("搜尋按鈕被點擊")
        // 執行搜尋
    }
    
    private func setupWeatherHomeView() {
        view.addSubview(weatherHomeView)
        weatherHomeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setNavgationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // 創建位置按鈕
        let systemName = hasLocation ? "location.fill" : "location"
        let locationButton = UIBarButtonItem(
            image: UIImage(systemName: systemName),
            style: .plain,
            target: self,
            action: #selector(locationButtonTapped)
        )
        locationButton.tintColor = .label
        
        // 創建搜尋按鈕
        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
            style: .plain,
            target: self,
            action: #selector(searchButtonTapped)
        )
        searchButton.tintColor = .label
        
        // 設置右側按鈕（搜尋按鈕在左邊，位置按鈕在右邊）
        navigationItem.rightBarButtonItems = [locationButton, searchButton]
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
                        if let placemark = placemarks?.first {
                            let detailedLocation = self.formatDetailedLocation(from: placemark)
                            self.title = detailedLocation
                        } else {
                            self.hasLocation = false
                            self.setNavgationBar()
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
        
        Publishers.CombineLatest(currentWeatherVM.$weather, weatherForecastVM.$forecast)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (weather, forecast) in
                guard let self = self else { return }
                
                if let weather = weather {
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
                
                guard let forecast = forecast else {
                    weatherHomeView.forecastTableView.isHidden = true
                    return
                }
                weatherHomeView.forecastTableView.isHidden = false
                weatherHomeView.forecastTableView.reloadData()
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
    
    @objc private func searchButtonTapped() {
        // 顯示搜尋控制器
        present(searchController, animated: true)
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
    
    private func formatDetailedLocation(from placemark: CLPlacemark) -> String {
        // 只顯示城市（如：臺北市）
        if let administrativeArea = placemark.administrativeArea {
            return administrativeArea
        }
        
        // 如果沒有城市資訊，顯示當前位置
        return "當前位置"
    }
}

extension WeatherHomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weatherInfoItems.count
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
