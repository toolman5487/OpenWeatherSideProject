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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isSkeletonable = true
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        label.isSkeletonable = true
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()
    
    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.isSkeletonable = true
        stack.layer.cornerRadius = 16
        stack.layer.masksToBounds = true
        return stack
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 16
        blurView.layer.masksToBounds = true
        blurView.alpha = 0.5
        return blurView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBlurEffect()
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }
    
    private func setupBlurEffect() {
        contentView.backgroundColor = .clear
        contentView.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}
