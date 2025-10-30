//
//  StartViewController.swift
//  cie-sdk-ios
//
//  Created by Antonio Caparello on 26/03/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    
    var actionButton: UIButton!
    var nisActionButton: UIButton!
    var paceActionButton: UIButton!
    var paceAndNisActionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
    func setupUI() {
        
        actionButton = UIButton(type: .system)
        actionButton.setTitle("START", for: .normal)
        actionButton.backgroundColor = .systemBlue
        actionButton.tintColor = .white
        
        nisActionButton = UIButton(type: .system)
        nisActionButton.setTitle("NIS", for: .normal)
        nisActionButton.backgroundColor = .systemBlue
        nisActionButton.tintColor = .white
        
        paceActionButton = UIButton(type: .system)
        paceActionButton.setTitle("PACE", for: .normal)
        paceActionButton.backgroundColor = .systemBlue
        paceActionButton.tintColor = .white
        
        paceAndNisActionButton = UIButton(type: .system)
        paceAndNisActionButton.setTitle("PACE+NIS", for: .normal)
        paceAndNisActionButton.backgroundColor = .systemBlue
        paceAndNisActionButton.tintColor = .white
        
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(doBegin), for: .touchUpInside)
        view.addSubview(actionButton)
        
        
        
        nisActionButton.translatesAutoresizingMaskIntoConstraints = false
        nisActionButton.addTarget(self, action: #selector(doNIS), for: .touchUpInside)
        view.addSubview(nisActionButton)
        
        paceActionButton.translatesAutoresizingMaskIntoConstraints = false
        paceActionButton.addTarget(self, action: #selector(doPACE), for: .touchUpInside)
        view.addSubview(paceActionButton)
        
        paceAndNisActionButton.translatesAutoresizingMaskIntoConstraints = false
        paceAndNisActionButton.addTarget(self, action: #selector(doPACENIS), for: .touchUpInside)
        view.addSubview(paceAndNisActionButton)
        
        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            //actionButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            actionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 64),
            
            nisActionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            nisActionButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            nisActionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            nisActionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            nisActionButton.heightAnchor.constraint(equalToConstant: 64),
            
            paceActionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            paceActionButton.topAnchor.constraint(equalTo: nisActionButton.bottomAnchor, constant: 16),
            paceActionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            paceActionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            paceActionButton.heightAnchor.constraint(equalToConstant: 64),
            
            paceAndNisActionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            paceAndNisActionButton.topAnchor.constraint(equalTo: paceActionButton.bottomAnchor, constant: 16),
            paceAndNisActionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            paceAndNisActionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            paceAndNisActionButton.heightAnchor.constraint(equalToConstant: 64)
            
            ])
    }
    
    @objc func doBegin() {
        let main = UIStoryboard(name: "Main", bundle:nil)
        let vc : UIViewController = main.instantiateViewController(withIdentifier: "AppViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func doNIS() {
        let main = UIStoryboard(name: "Main", bundle:nil)
        let vc : UIViewController = main.instantiateViewController(withIdentifier: "NISViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func doPACE() {
        let main = UIStoryboard(name: "Main", bundle:nil)
        let vc : UIViewController = main.instantiateViewController(withIdentifier: "PACEViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func doPACENIS() {
        let main = UIStoryboard(name: "Main", bundle:nil)
        let vc : UIViewController = main.instantiateViewController(withIdentifier: "PACENISViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
        
        
}
