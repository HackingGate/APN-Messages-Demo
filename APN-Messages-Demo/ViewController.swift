//
//  ViewController.swift
//  APN-Messages-Demo
//
//  Created by ERU on 2018/08/18.
//  Copyright © 2018 HackingGate. All rights reserved.
//

import UIKit
import CloudKit
import SwiftyRSA

class ViewController: UIViewController {

    @IBOutlet weak var fingerprintField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var publicKeyStringField: UITextField!

    let publicCloudDatabase = CKContainer.default().publicCloudDatabase

    var myPrivateKey: PrivateKey?
    var myPublicKey: PublicKey?
    var recipientPublicKey: PublicKey?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        if let privateKeyString = UserDefaults.standard.value(forKey: "privateKey") as? String {
            myPrivateKey = try! PrivateKey(base64Encoded: privateKeyString)
        }
        if let publicKeyString = UserDefaults.standard.value(forKey: "publicKey") as? String {
            myPublicKey = try! PublicKey(base64Encoded: publicKeyString)
        }
        if myPrivateKey == nil, myPublicKey == nil {
            let keyPair = try! SwiftyRSA.generateRSAKeyPair(sizeInBits: 4096)
            myPrivateKey = keyPair.privateKey
            myPublicKey = keyPair.publicKey
            
            let privateKeyString = try! myPrivateKey?.base64String()
            let publicKeyString = try! myPublicKey?.base64String()
            
            UserDefaults.standard.setValue(privateKeyString, forKey: "privateKey")
            UserDefaults.standard.setValue(publicKeyString, forKey: "publicKey")
        }
        
    }
    
    func fetchRecord(_ recordID: CKRecord.ID) {
        self.publicCloudDatabase.fetch(withRecordID: recordID) { (record: CKRecord?, error: Error?) in
            if let error = error {
                print("CKRecord: \(String(describing: record)) fetch failed: \(error)")
            }
            if let record = record {
                print(record)
                
                guard let messageBlock = record.object(forKey: "messageBlock") as? String else { return }
                let alert = UIAlertController(title: "Message", message: messageBlock, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
                    UIAlertAction in
                    NSLog("Cancel Pressed")
                }
                alert.addAction(cancelAction)
                let decryptAction = UIAlertAction(title: "Decrypt", style: .default) {
                    UIAlertAction in
                    NSLog("Decrypt Pressed")
                    
                    let encrypted = try! EncryptedMessage(base64Encoded: messageBlock)
                    if let myPrivateKey = self.myPrivateKey {
                        do {
                            let clear = try encrypted.decrypted(with: myPrivateKey, padding: .PKCS1)
                            let string = try clear.string(encoding: .utf8)
                            
                            self.showMessage(string)
                        } catch {
                            print(error)
                        }
                    }
                    
                }
                alert.addAction(decryptAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Message", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) {
            UIAlertAction in
            NSLog("OK Pressed")
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func sendAction(_ sender: UIButton) {
        guard let keyString = publicKeyStringField.text else { return }
        guard let text = textField.text else { return }
        let clear = try! ClearMessage(string: text, using: .utf8)
        do {
            let publicKey = try PublicKey(base64Encoded: keyString)
            let encrypted = try clear.encrypted(with: publicKey, padding: .PKCS1)
            let base64String = encrypted.base64String
            
            let alert = UIAlertController(title: "Encrypted Message", message: base64String, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
                UIAlertAction in
                NSLog("Cancel Pressed")
                
                let encrypted = try! EncryptedMessage(base64Encoded: base64String)
                if let myPrivateKey = self.myPrivateKey {
                    do {
                        let clear = try encrypted.decrypted(with: myPrivateKey, padding: .PKCS1)
                        let string = try clear.string(encoding: .utf8)
                        
                        self.showMessage(string)
                    } catch {
                        print(error)
                    }
                }
            }
            alert.addAction(cancelAction)
            let sendAction = UIAlertAction(title: "Send", style: .default) {
                UIAlertAction in
                NSLog("Send Pressed")
                self.sendEncryptedMessage(base64String)
            }
            alert.addAction(sendAction)
            self.present(alert, animated: true, completion: nil)
        } catch {
            print(error)
        }
        
    }
    
    func sendEncryptedMessage(_ base64String: String){
        let newGlobalNotificationRecord = CKRecord(recordType: GlobalNotificationType)
        newGlobalNotificationRecord["fingerprintTo"] = fingerprintField.text
        newGlobalNotificationRecord["messageBlock"] = base64String
        self.publicCloudDatabase.save(newGlobalNotificationRecord, completionHandler: { (record: CKRecord?, error: Error?) in
            if let error = error {
                print("CKRecord: \(String(describing: record)) save failed: \(error)")
            }
        })
    }
    
    @IBAction func showAction(_ sender: UIButton) {
        let alert = UIAlertController(title: "My Public Key", message: try! myPublicKey?.base64String(), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            UIAlertAction in
            NSLog("Cancel Pressed")
        }
        alert.addAction(cancelAction)
        do {
            if let base64String = try myPublicKey?.base64String() {
                let copyAction = UIAlertAction(title: "Share", style: .default) {
                    UIAlertAction in
                    NSLog("Share Pressed")
                    
                    let activityViewController = UIActivityViewController(activityItems: [base64String], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                    
                    // present the view controller
                    self.present(activityViewController, animated: true, completion: nil)
                }
                alert.addAction(copyAction)
            }
            
        } catch {
            print(error)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

