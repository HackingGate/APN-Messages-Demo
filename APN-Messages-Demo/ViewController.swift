//
//  ViewController.swift
//  APN-Messages-Demo
//
//  Created by ERU on 2018/08/18.
//  Copyright © 2018 HackingGate. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {

    @IBOutlet weak var fingerprintField: UITextField!
    @IBOutlet weak var textField: UITextField!
    
    let publicCloudDatabase = CKContainer.default().publicCloudDatabase

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
                let okAction = UIAlertAction(title: "OK", style: .default) {
                    UIAlertAction in
                    NSLog("OK Pressed")
                }
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func sendAction(_ sender: UIButton) {
        let newGlobalNotificationRecord = CKRecord(recordType: GlobalNotificationType)
        newGlobalNotificationRecord["fingerprintTo"] = fingerprintField.text
        newGlobalNotificationRecord["messageBlock"] = textField.text
        self.publicCloudDatabase.save(newGlobalNotificationRecord, completionHandler: { (record: CKRecord?, error: Error?) in
            if let error = error {
                print("CKRecord: \(String(describing: record)) save failed: \(error)")
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

