//
//  PACEViewController.swift
//  cie-sdk-ios
//
//  Created by antoniocaparello on 03/10/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import CieSDK


class PACEViewController: UIViewController {
    
    var titleLabel: UILabel!
    var infoLabel: UITextView!
    var canTextField: UITextField!
    var actionButton: UIButton!
    var showLogsButton: UIButton!
    var shareInfoButton: UIButton!
    
    
    var progress: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }
    
    func setupUI() {
        
        titleLabel = UILabel()
        titleLabel.text = "CieSDK PACE Example"
        titleLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = .blue
        view.addSubview(titleLabel)
        
        
        infoLabel = UITextView()
        infoLabel.text = "Idle"
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.textColor = .lightGray
        
        view.addSubview(infoLabel)
        
        canTextField = UITextField()
        canTextField.borderStyle = .roundedRect
        canTextField.translatesAutoresizingMaskIntoConstraints = false
        canTextField.text = ""
        canTextField.placeholder = "CAN"
        
        view.addSubview(canTextField)
        
        actionButton = UIButton(type: .system)
        actionButton.setTitle("PACE", for: .normal)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(doPACE), for: .touchUpInside)
        view.addSubview(actionButton)
        
        
        showLogsButton = UIButton(type: .system)
        showLogsButton.setTitle("SHOW LOGS", for: .normal)
        showLogsButton.translatesAutoresizingMaskIntoConstraints = false
        showLogsButton.addTarget(self, action: #selector(presentLogs), for: .touchUpInside)
        view.addSubview(showLogsButton)
        
        shareInfoButton = UIButton(type: .system)
        shareInfoButton.setTitle("SHARE INFO", for: .normal)
        shareInfoButton.translatesAutoresizingMaskIntoConstraints = false
        shareInfoButton.addTarget(self, action: #selector(shareOutputFile), for: .touchUpInside)
        view.addSubview(shareInfoButton)
        
        progress = UIProgressView()
        progress.backgroundColor = .red
        progress.tintColor = .blue
        progress.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(progress)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            
            canTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            canTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            canTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            //canTextField.heightAnchor.constraint(equalToConstant: 100),
            
            
//            challengeTextView.topAnchor.constraint(equalTo: canTextField.topAnchor),
//            challengeTextView.bottomAnchor.constraint(equalTo: canTextField.bottomAnchor),
//            challengeTextView.leftAnchor.constraint(equalTo: canTextField.leftAnchor),
//            challengeTextView.rightAnchor.constraint(equalTo: canTextField.rightAnchor),
            
            progress.topAnchor.constraint(equalTo: canTextField.bottomAnchor, constant: 4),
            progress.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            progress.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            progress.heightAnchor.constraint(equalToConstant: 5),
            
            
            
            actionButton.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 10),
            actionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            
            
            showLogsButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 10),
            showLogsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
         
            shareInfoButton.topAnchor.constraint(equalTo: showLogsButton.bottomAnchor, constant: 10),
            shareInfoButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            
            
            infoLabel.topAnchor.constraint(equalTo: shareInfoButton.bottomAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            infoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            
            
        ])
    }

    
    @objc func doPACE() {
        
        canTextField.endEditing(true)
        
        guard let can = canTextField.text,
              !can.isEmpty else {
            infoLabel.text = "Empty can"
            return
        }
        
        Task {
            do {
                let digitalId = CieDigitalId(.localFile)
                
                let response = try await digitalId.performMtrd(can: can) {
                    event, progress in
                    
                    print(event)
                    print(progress)
                    
                    digitalId.alertMessage = "\(event)"
                    
                    DispatchQueue.main.async {
                        self.progress.progress = progress
                    }
                }
                
                DispatchQueue.main.async {
                    self.infoLabel.text = """
                        DG1: \(response.dg1.hexEncodedString)
                        
                        DG11: \(response.dg11.hexEncodedString)
                        
                        SOD: \(response.sod.hexEncodedString)
                        """
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.handleError(error)
                }
            }
        }
    }
    
    private func handleError(_ error: any Error) {
        self.progress.progress = 0.0
        
        if let nfcDigitalIdError = error as? NfcDigitalIdError {
            if case .nfcError(let nfcReaderError) = nfcDigitalIdError {
                switch nfcReaderError.code {
                    case .readerTransceiveErrorTagConnectionLost,
                            .readerTransceiveErrorTagResponseError:
                        self.infoLabel.text = "Hai rimosso la carta troppo presto"
                    case .readerSessionInvalidationErrorUserCanceled:
                        self.infoLabel.text = "Annullato dall'utente"
                    default:
                        self.infoLabel.text = "Lettura carta non riuscita"
                }
            }
            else {
                self.infoLabel.text = nfcDigitalIdError.description
            }
        }
        else {
            self.infoLabel.text = error.localizedDescription
        }
        
        self.presentLogs()
    }
    
    @objc func shareOutputFile() {
        do {
            try shareOutput(self.infoLabel.text)
        }
        catch {
            
        }
        
    }
    
    func shareOutput(_ output: String) throws {
        
        let fileName = "\(Date().timeIntervalSince1970.description).txt"
        
        let fileUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        
        let data = output.data(using: String.Encoding.utf8)!
      
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileUrl.path) {
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
        } else {
            try data.write(to: fileUrl, options: .atomic)
        }
        
        
            
            var filesToShare = [Any]()
            
            // Add the path of the file to the Array
            filesToShare.append(fileUrl)
            
            // Make the activityViewContoller which shows the share-view
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            
            // Show the share-view
            self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func presentLogs() {
        if let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.temporaryDirectory.path),
           let fileName = files.filter({
               item in
               return item.contains("CieSDK")
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
    
}
