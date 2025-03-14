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
    
    var webView: WKWebView!
    
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
        
        pinTextField.text = ""
        
        view.addSubview(pinTextField)
        
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
            
            infoLabel.topAnchor.constraint(equalTo: cieTypeButton.bottomAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            
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
    
    @objc func getCIEType() {
        Task {
            do {
                let authenticatedUrl = try await IOWalletDigitalId(.enabled).performReadCieType()
                
                DispatchQueue.main.async {
                    self.infoLabel.text = "\(authenticatedUrl)"
                }
            } catch {
                DispatchQueue.main.async {
                    if let nfcDigitalIdError = error as? NfcDigitalIdError {
                        self.infoLabel.text = nfcDigitalIdError.description
                    }
                    else {
                        self.infoLabel.text = error.localizedDescription
                    }
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
                let authenticatedUrl = try await IOWalletDigitalId(.enabled).performAuthentication(forUrl: foundUrl, withPin: pin)
                
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
                }
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



