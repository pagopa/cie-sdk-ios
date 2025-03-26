//
//  ViewController.swift
//  cie-sdk-ios
//
//  Created by acapadev on 01/28/2025.
//  Copyright (c) 2025 PagoPA. All rights reserved.
//

import UIKit

import IOWalletCIE

@preconcurrency import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    
    var level3Url = "https://app-backend.io.italia.it/login?entityID=xx_servizicie&authLevel=SpidL3"
    var foundUrl: String? = nil
    
    var titleLabel: UILabel!
    var infoLabel: UILabel!
    var pinTextField: UITextField!
    var actionButton: UIButton!
    var cieTypeButton: UIButton!
    var showLogsButton: UIButton!
    
    var webView: WKWebView!
    
    let togglePinSecureEntry: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "eye.fill"), for: .normal) // Initial icon for hidden password
        button.addTarget(self, action: #selector(togglePinVisibility), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupWebView()
        
        loadURL()
    }
    
    func setupUI() {
        
        titleLabel = UILabel()
        titleLabel.text = "IOWalletCIE NfcDigitalIdAuthentication Example"
        titleLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = .blue
        view.addSubview(titleLabel)
        
        infoLabel = UILabel()
        infoLabel.text = "Waiting for '' in URL..."
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .lightGray
        view.addSubview(infoLabel)
        
        
        
        pinTextField = UITextField()
        pinTextField.placeholder = "PIN"
        pinTextField.borderStyle = .roundedRect
        pinTextField.translatesAutoresizingMaskIntoConstraints = false
        pinTextField.isSecureTextEntry = true
        pinTextField.text = ""
        
        view.addSubview(pinTextField)
        view.addSubview(togglePinSecureEntry)
        
        actionButton = UIButton(type: .system)
        actionButton.setTitle("AUTHENTICATE", for: .normal)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(doAuthentication), for: .touchUpInside)
        view.addSubview(actionButton)
        
        cieTypeButton = UIButton(type: .system)
        cieTypeButton.setTitle("GET CIE TYPE", for: .normal)
        cieTypeButton.translatesAutoresizingMaskIntoConstraints = false
        cieTypeButton.addTarget(self, action: #selector(getCIEType), for: .touchUpInside)
        view.addSubview(cieTypeButton)
        
        showLogsButton = UIButton(type: .system)
        showLogsButton.setTitle("SHOW LOGS", for: .normal)
        showLogsButton.translatesAutoresizingMaskIntoConstraints = false
        showLogsButton.addTarget(self, action: #selector(presentLogs), for: .touchUpInside)
        view.addSubview(showLogsButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            pinTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            pinTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            pinTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            actionButton.topAnchor.constraint(equalTo: pinTextField.bottomAnchor, constant: 10),
            actionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            cieTypeButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 10),
            cieTypeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            showLogsButton.topAnchor.constraint(equalTo: cieTypeButton.bottomAnchor, constant: 10),
            showLogsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: showLogsButton.bottomAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            togglePinSecureEntry.centerYAnchor.constraint(equalTo: pinTextField.centerYAnchor),
            togglePinSecureEntry.trailingAnchor.constraint(equalTo: pinTextField.trailingAnchor, constant: -8),
            togglePinSecureEntry.widthAnchor.constraint(equalToConstant: 24),
            togglePinSecureEntry.heightAnchor.constraint(equalToConstant: 24)
            
        ])
    }
    
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.isHidden = true // Keep the web view hidden
        webView.navigationDelegate = self
        view.addSubview(webView)
    }
    
    @objc func loadURL() {
        guard let url = URL(string: level3Url) else {
            infoLabel.text = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        infoLabel.text = "Loading..."
    }
    
    @objc func togglePinVisibility() {
        pinTextField.isSecureTextEntry.toggle()
        
        togglePinSecureEntry.setImage(UIImage(systemName: pinTextField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"), for: .normal)
    }
    
    @objc func getCIEType() {
        Task {
            do {
                let atr = try await IOWalletDigitalId(.localFile).performReadAtr()
                
                let cieType = CIEType.fromATR(atr)
                
                DispatchQueue.main.async {
                    self.infoLabel.text = "\(cieType)\n\(atr.hexEncodedString)"
                }
            } catch {
                DispatchQueue.main.async {
                    if let nfcDigitalIdError = error as? NfcDigitalIdError {
                        self.infoLabel.text = nfcDigitalIdError.description
                    }
                    else {
                        self.infoLabel.text = error.localizedDescription
                    }
                    
                    self.presentLogs()
                }
            }
        }
    }
    
    @objc func doAuthentication() {
        guard let pin = pinTextField.text else {
            infoLabel.text = "Invalid PIN"
            return
        }
        
        guard let foundUrl = foundUrl,
              !foundUrl.isEmpty else {
            infoLabel.text = "URL not found"
            return
        }
        
        Task {
            do {
                let authenticatedUrl = try await IOWalletDigitalId(.localFile).performAuthentication(forUrl: foundUrl, withPin: pin)
                
                DispatchQueue.main.async {
                    self.infoLabel.text = authenticatedUrl
                    
                    let navigateView = WebViewViewController()
                    navigateView.urlToOpen = authenticatedUrl
                    
                    self.present(navigateView, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    if let nfcDigitalIdError = error as? NfcDigitalIdError {
                        self.infoLabel.text = nfcDigitalIdError.description
                    }
                    else {
                        self.infoLabel.text = error.localizedDescription
                    }
                    
                    self.presentLogs()
                }
            }
        }
    }
    
    @objc func presentLogs() {
        if let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.temporaryDirectory.path),
           let fileName = files.filter({
               item in
               return item.contains("IOWalletCIE")
           })
            .sorted().last
        {
            let fileUrl = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            if let fileHandle = FileHandle(forReadingAtPath: fileUrl.path) {
                defer {
                    fileHandle.closeFile()
                }
                
                let data = fileHandle.readDataToEndOfFile()
                
                let s = String(data: data, encoding: .utf8)
                
                let logsController = UIAlertController(title: fileName, message: s, preferredStyle: .alert)
                
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
    
    func webView(_ webView: WKWebView, decidePolicyFor
                 navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if foundUrl != nil {
            decisionHandler(.cancel)
            return
        }
        
        if let url = webView.url?.absoluteString, url.contains("authnRequestString") {
            infoLabel.text = "Found 'authnRequestString'!\n\(url)"
            self.foundUrl = url
        }
        
        decisionHandler(.allow)
    }
}



