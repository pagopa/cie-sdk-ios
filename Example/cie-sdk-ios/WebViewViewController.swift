//
//  WebViewViewController.swift
//  cie-sdk-ios
//
//  Created by Antonio Caparello on 04/03/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//



import UIKit
@preconcurrency import WebKit

class WebViewViewController : UIViewController, WKNavigationDelegate {
    var urlToOpen: String = ""
    
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        
        loadURL()
    }
    
    
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: view.safeAreaLayoutGuide.layoutFrame, configuration: webConfiguration)
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
            ])
    }
    @objc func loadURL() {
        guard let url = URL(string: urlToOpen) else {
           
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor
                 navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        print(navigationAction.request.url)
        
        decisionHandler(.allow)
    }
    
}
