//
//  SheetViewController.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 11/14/23.
//

import UIKit

protocol SheetViewControllerDelegate: AnyObject {
    func startTrack()
    func hideDetails()
    func startRegionTrack()
    func calculateRoute()
}

enum SheetType {
    case supportGeo
    case unsupportGeo
}

final class SheetViewController: UIViewController {
    
    weak var sheetDelegate: SheetViewControllerDelegate?
    
    private let defaultSpacing: CGFloat = 15
    
    lazy var destinationTitle: UILabel = {
        configureTitleView(title: "Destination: ")
    }()
    
    lazy var destinationAddress: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "..."
        return label
    }()
    
    lazy var averageTimeTitle: UILabel = {
        configureTitleView(title: "Average time: ")
    }()
    
    lazy var averageTime: UILabel = {
        let label = UILabel()
         label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "..."
         return label
    }()
    
    lazy var calculateButton: UIButton = {
        let action = UIAction { [weak self] _ in
            self?.sheetDelegate?.calculateRoute()
        }
        let button = UIButton(type: .roundedRect, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Show route details", for: .normal)
        return button
    }()
    
    lazy var hideDetailsButton: UIButton = {
        let action = UIAction { [weak self] _ in
            self?.sheetDelegate?.hideDetails()
        }
        let button = UIButton(type: .roundedRect, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.isHidden = true
        return button
    }()
    
    lazy var detailsStackView: UIStackView = {
       let stackView = UIStackView(arrangedSubviews: [calculateButton, hideDetailsButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
//        stackView.spacing = 10
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    lazy var startTrackButton: UIButton = {
        let action = UIAction { [weak self] _ in
            self?.sheetDelegate?.startTrack()
        }
        return configureStartTrackButton(title: "Start track", action: action)
    }()
    
    lazy var startRegionTrackButton: UIButton = {
        let action = UIAction { [weak self] _ in
            self?.sheetDelegate?.startRegionTrack()
        }
        return configureStartTrackButton(title: "Start region track", action: action)
    }()
    
    lazy var startTrackStackView: UIStackView = {
       let stackView = UIStackView(arrangedSubviews: [startTrackButton, startRegionTrackButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.isHidden = true
        return stackView
    }()
    
    lazy var notSupportedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.text = "Unknown country"
        return label
    }()
    
    var geoStatus: SheetType = .supportGeo

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        configureSheetDetails(isSupportedCountry: true)
    }
    
    private func configureView() {
        view.addSubview(destinationTitle)
        view.addSubview(destinationAddress)
        view.addSubview(averageTimeTitle)
        view.addSubview(averageTime)
        view.addSubview(detailsStackView)
        view.addSubview(startTrackStackView)
    }
    
    func configureSheetDetails(isSupportedCountry: Bool) {
        view.subviews.forEach { view in
            view.removeFromSuperview()
        }
        if isSupportedCountry {
            configureView()
            setupConstaints()
        } else {
            view.addSubview(notSupportedLabel)
            NSLayoutConstraint.activate([
                notSupportedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: defaultSpacing),
                notSupportedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -defaultSpacing),
                notSupportedLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 30)
            ])
        }
    }
    
    private func setupConstaints() {
        NSLayoutConstraint.activate([
            destinationTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: defaultSpacing),
            destinationTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            destinationAddress.leadingAnchor.constraint(equalTo: destinationTitle.trailingAnchor, constant: defaultSpacing),
            destinationAddress.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            
            averageTimeTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: defaultSpacing),
            averageTimeTitle.topAnchor.constraint(equalTo: destinationTitle.bottomAnchor, constant: defaultSpacing),
            averageTime.leadingAnchor.constraint(equalTo: averageTimeTitle.trailingAnchor, constant: defaultSpacing),
            averageTime.topAnchor.constraint(equalTo: destinationAddress.bottomAnchor, constant: defaultSpacing),
            
            detailsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detailsStackView.topAnchor.constraint(equalTo: averageTime.bottomAnchor, constant: defaultSpacing * 2),
            
            startTrackStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            startTrackStackView.topAnchor.constraint(equalTo: calculateButton.bottomAnchor, constant: defaultSpacing),
            startTrackStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            startTrackStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func configureTitleView(title: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }
    
    private func configureStartTrackButton(title: String, action: UIAction) -> UIButton {
        let button = UIButton(type: .roundedRect, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemYellow
        button.layer.cornerRadius = 10
        button.setTitleColor(.black, for: .normal)
        return button
    }
    
    deinit {
        print("Sheet deinited")
    }
}
