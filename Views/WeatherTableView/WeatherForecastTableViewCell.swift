//
//  WeatherForecastTableViewCell.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/6.
//

import Foundation
import UIKit
import SnapKit

class WeatherForecastTableViewCell:UITableViewCell{
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .medium(size: 16)
        label.textColor = .label
        return label
    }()
    
    let iconImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.tintColor = .label
        return image
    }()
    
    let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .semibold(size: 20)
        label.textColor = .label
        return label
    }()
    
    let descLabel: UILabel = {
        let label = UILabel()
        label.font = .regular(size: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(timeLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(tempLabel)
        contentView.addSubview(descLabel)
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }
        
        tempLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(tempLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(time: String, icon: UIImage?, temp: String, desc: String) {
        timeLabel.text = time
        iconImageView.image = icon
        tempLabel.text = temp
        descLabel.text = desc
    }
}
