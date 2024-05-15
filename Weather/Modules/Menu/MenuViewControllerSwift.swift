//
//  MenuViewController.swift
//  Weather
//
//  Created by Ерасыл Еркин on 09.01.2024.
//

import UIKit
import SnapKit

protocol ManageDelegate: AnyObject {
    func didTapped()
}

protocol MenuDelegate: AnyObject {
    func didSelectMenuItem(city: String)
}

final class MenuViewController: UIViewController{
    
    // MARK: - Deps
    private var defaults = UserDefaultsManager.shared
    private var heightConstraint: NSLayoutConstraint!
    let menuWidth = UIScreen.main.bounds.width - 80
    let manageVC = ManageViewController()
    var houryForecast: [DatumHourly] = []
    private var cities = [CityData]()
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    weak var menuDelegate: MenuDelegate?
    weak var delegate: ManageDelegate?
    
    // MARK: - UI
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        view.alwaysBounceVertical = true
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10
        view.alignment = .leading
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.register(MenuTableViewCell.self, forCellReuseIdentifier: "cell")
        view.backgroundColor = .green
        return view
    }()
    
    private lazy var manageButton: UIButton = {
        let button = UIButton()
        button.setTitle("Manage", for: .normal)
        button.backgroundColor = .red
        button.layer.cornerRadius = 15
        return button
    }()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "cloudColor")
        let vc = ManageViewController()
        vc.delegateData = self
        setupViews()
        updateTableViewHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let cityData = defaults.getCityData() {
            cities = cityData
            updateTableViewHeight()
            tableView.reloadData()
        }
    }
    
    func tableSetup() {
        
    }
    
    func setupViews() {
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalToConstant: screenWidth),
        ])
        setupContainers()    }
    
    func setupContainers() {
        stackView.addArrangedSubview(tableView)
        stackView.addArrangedSubview(manageButton)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 10
        
        
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5),
            tableView.widthAnchor.constraint(equalToConstant: menuWidth - 10),
            
        ])
        
        heightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        
        tableView.reloadData()
        
        NSLayoutConstraint.activate([
            manageButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: (menuWidth - 100) / 2 ),
            manageButton.heightAnchor.constraint(equalToConstant: 30),
            manageButton.widthAnchor.constraint(equalToConstant: 100),
        ])
        manageButton.addTarget(self, action: #selector(manageButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc func manageButtonTapped() {
        delegate?.didTapped()
    }
    
    // MARK: - Functions
    func updateTableViewHeight() {
        let newHeight = CGFloat(cities.count * 54)
        heightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func checkEnteredCity(for cityName: String) {
        ApiManager.shared.fetchHourlyForecast(cityName: cityName) { result in
            switch result {
            case .success(let hourlyForecast):
                DispatchQueue.main.async {
                    self.houryForecast = hourlyForecast.data
                    let name = hourlyForecast.cityName
                    if let data = self.houryForecast.first {
                        self.cities.append(.init(name: name, temperature: Int(data.temp), icon: data.weather.icon, currentCity: false))
                        self.updateTableViewHeight()
                        self.tableView.reloadData()
                    }
                }
            case .failure(let error):
                print("Error fetching hourly forecast: \(error)")
            }
        }
    }
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MenuTableViewCell
        let data = cities[indexPath.row]
        if indexPath.row == 0 {
            cities[indexPath.row].currentCity = true
        }
        cell.configure(model: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCity = cities[indexPath.row]
        cities.remove(at: indexPath.row)
        cities.insert(selectedCity, at: 0)
        let city = selectedCity.name
        menuDelegate?.didSelectMenuItem(city: city)
        defaults.saveCurrentCity(cityName: city)
        tableView.reloadData()
    }
}

extension MenuViewController: ManageViewControllerDelegate {
    func didUpdateCities() {
        updateTableViewHeight()
        tableView.reloadData()
    }
}
