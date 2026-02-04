//
//  StartViewController.swift
//  cie-sdk-ios
//
//  Created by Antonio Caparello on 26/03/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import CieSDK

class CieDigitalIdSingleton {
    static var shared: CieDigitalId = CieDigitalId(.disabled)
}

class StartViewController: UIViewController {
    
    var actionButton: UIButton!
    var nisActionButton: UIButton!
    var paceActionButton: UIButton!
    var paceAndNisActionButton: UIButton!
    
    var lastLogButton: UIButton!
    
    var logMode: UIPickerView!
    
    private var logModes: [CieDigitalId.LogMode] = [.disabled , .enabled, .console, .localFile]
    
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
        
        lastLogButton = UIButton(type: .system)
        lastLogButton.setTitle("Last log", for: .normal)
        lastLogButton.backgroundColor = .systemBlue
        lastLogButton.tintColor = .white
        
        
        logMode = UIPickerView()
        logMode.delegate = self
        logMode.dataSource = self
        logMode.backgroundColor = .systemBlue
        
        logMode.selectRow(logModes.index(of: CieDigitalIdSingleton.shared.getLogMode()) ?? 0, inComponent: 0, animated: false)
        
        
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
        
        lastLogButton.translatesAutoresizingMaskIntoConstraints = false
        lastLogButton.addTarget(self, action: #selector(doLastLog), for: .touchUpInside)
        view.addSubview(lastLogButton)
        
        logMode.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logMode)
        
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
            paceAndNisActionButton.heightAnchor.constraint(equalToConstant: 64),
            
            lastLogButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            lastLogButton.topAnchor.constraint(equalTo: paceAndNisActionButton.bottomAnchor, constant: 16),
            lastLogButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            lastLogButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            lastLogButton.heightAnchor.constraint(equalToConstant: 64),
            
            logMode.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logMode.topAnchor.constraint(equalTo: lastLogButton.bottomAnchor, constant: 16),
            logMode.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            logMode.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            logMode.heightAnchor.constraint(equalToConstant: 64)
            
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
    
    @objc func doLastLog() {
        if let fileUrl = CieDigitalId.retriveLastLogFilePath() {
            
            if let fileHandle = FileHandle(forReadingAtPath: fileUrl) {
                defer {
                    fileHandle.closeFile()
                }
                
                let data = fileHandle.readDataToEndOfFile()
                
                let s = String(data: data, encoding: .utf8)
                
                let logsController = UIAlertController(title: "Last Log", message: s, preferredStyle: .alert)
                
                logsController.addAction(UIAlertAction(title: "CLOSE", style: .destructive, handler: {
                    _ in
                    logsController.dismiss(animated: true)
                }))
                
                logsController.addAction(UIAlertAction(title: "SHARE", style: .default, handler: {
                    _ in
                    var filesToShare = [Any]()
                    
                    // Add the path of the file to the Array
                    filesToShare.append(fileUrl)
                    
                    // Make the activityViewContoller which shows the share-view
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    
                    // Show the share-view
                    self.present(activityViewController, animated: true, completion: nil)
                }))
                
                self.present(logsController, animated: true)
            }
        }
    }
        
        
}

extension StartViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(logModes[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        CieDigitalIdSingleton.shared.setLogMode(logModes[row])
    }
}

extension StartViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return logModes.count
    }
}
