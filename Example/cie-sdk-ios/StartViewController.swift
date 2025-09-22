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
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(doBegin), for: .touchUpInside)
        view.addSubview(actionButton)
        
        
        
        nisActionButton.translatesAutoresizingMaskIntoConstraints = false
        nisActionButton.addTarget(self, action: #selector(doNIS), for: .touchUpInside)
        view.addSubview(nisActionButton)
        
        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            actionButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            actionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 64),
            nisActionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            nisActionButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            nisActionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            nisActionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            nisActionButton.heightAnchor.constraint(equalToConstant: 64)
            
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
        
        
}
