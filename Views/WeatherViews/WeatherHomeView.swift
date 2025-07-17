//
//  WeatherHomeView.swift
//  OpenWeather
//
//  Created by [Your Name] on [Date].
//

import UIKit
import SnapKit
import Lottie

class WeatherHomeView: UIView {
    
    let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .bold(size: 72)
        label.textColor = .label
        label.textAlignment = .center
        label.isHidden = false
        label.layer.cornerRadius = 36
        label.layer.masksToBounds = true
        return label
    }()
    
    let weatherImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.tintColor = .label
        image.clipsToBounds = true
        image.layer.cornerRadius = 28
        image.layer.masksToBounds = true
        return image
    }()
    
    let weatherDescLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()
    
    lazy var weatherStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [weatherImageView, weatherDescLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    lazy var infoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.itemSize = CGSize(width: 72, height: 72)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = true
        return collection
    }()
    
    lazy var forecastTableView: WeatherTableView = {
        let tableView = WeatherTableView(frame: .zero, style: .plain)
        tableView.isHidden = false
        tableView.layer.cornerRadius = 12
        tableView.layer.masksToBounds = true
        return tableView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(tempLabel)
        addSubview(weatherStackView)
        addSubview(infoCollectionView)
        addSubview(forecastTableView)
        
        tempLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(0)
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
            make.top.equalTo(weatherStackView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
        }
        
        forecastTableView.snp.makeConstraints { make in
            make.top.equalTo(infoCollectionView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
        }
    }
} 
