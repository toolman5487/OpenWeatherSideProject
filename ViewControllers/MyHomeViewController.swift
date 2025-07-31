//
//  MyHomeViewController.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/14.
//

import Foundation
import UIKit
import Combine
import SnapKit
import CoreLocation
import MapKit

class MyHomeViewController: UIViewController {
    
    // MARK: - Properties
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    private var userAnnotation: MKPointAnnotation?
    
    // MARK: - UI Components
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = .standard
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        return mapView
    }()
    
    private lazy var locationContainer: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 4
        return container
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = "正在獲取位置..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setHomeNavigationBar()
        setupUI()
        setupLocationBinding()
    }
    
    func setHomeNavigationBar() {
        self.title = "首頁"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 設置地圖
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(200)
        }
        
        // 設置位置容器
        locationContainer.addSubview(locationLabel)
        locationContainer.addSubview(loadingIndicator)
        
        view.addSubview(locationContainer)
        locationContainer.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        locationLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }
    }
    
    private func setupLocationBinding() {
        loadingIndicator.startAnimating()
        LocationManager.shared.requestLocation()
        
        LocationManager.shared.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                self.updateLocationDisplay(location: location)
                self.updateMapLocation(location: location)
            }
            .store(in: &cancellables)
        
        LocationManager.shared.$locationError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                self.handleLocationError(error)
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationDisplay(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loadingIndicator.stopAnimating()
                
                if let error = error {
                    self.locationLabel.text = "無法獲取位置資訊"
                    self.locationLabel.textColor = .systemRed
                    return
                }
                
                if let placemark = placemarks?.first {
                    let address = self.formatAddress(from: placemark)
                    self.locationLabel.text = address
                    self.locationLabel.textColor = .label
                } else {
                    self.locationLabel.text = "位置資訊不可用"
                    self.locationLabel.textColor = .secondaryLabel
                }
            }
        }
    }
    
    private func updateMapLocation(location: CLLocation) {
        // 移除舊的標註
        if let oldAnnotation = userAnnotation {
            mapView.removeAnnotation(oldAnnotation)
        }
        
        // 創建新的標註
        userAnnotation = MKPointAnnotation()
        userAnnotation?.coordinate = location.coordinate
        userAnnotation?.title = "您的位置"
        
        // 添加標註到地圖
        if let annotation = userAnnotation {
            mapView.addAnnotation(annotation)
        }
        
        // 設置地圖區域
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let subLocality = placemark.subLocality {
            addressComponents.append(subLocality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        
        if addressComponents.isEmpty {
            return "當前位置"
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    private func handleLocationError(_ error: Error) {
        loadingIndicator.stopAnimating()
        locationLabel.text = "位置服務不可用"
        locationLabel.textColor = .systemRed
    }
}
