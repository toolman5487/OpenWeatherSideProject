//
//  WeatherInfoCell.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/30.
//

import UIKit
import SnapKit
import SkeletonView


class WeatherInfoCell: UICollectionViewCell {
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.isSkeletonable = true
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        titleLabel.isSkeletonable = true
        titleLabel.layer.cornerRadius = 8
        titleLabel.layer.masksToBounds = true
        valueLabel.isSkeletonable = true
        valueLabel.layer.cornerRadius = 12
        valueLabel.layer.masksToBounds = true
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.5
        valueLabel.numberOfLines = 1
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.isSkeletonable = true
        stack.layer.cornerRadius = 16
        stack.layer.masksToBounds = true
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}
