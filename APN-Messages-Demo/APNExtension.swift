//
//  APNExtension.swift
//  APN-Messages-Demo
//
//  Created by ERU on 2018/08/18.
//  Copyright © 2018 HackingGate. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

let GlobalNotificationType = "GlobalNotification"

extension UIApplication {
    func registerAPN(_ appDelegate: AppDelegate, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        UNUserNotificationCenter.current().delegate = appDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
            if authorized {
                DispatchQueue.main.async {
                    self.registerForRemoteNotifications()
                }
            }
        })
        
        if let options: NSDictionary = launchOptions as NSDictionary? {
            let remoteNotification =
                options[UIApplication.LaunchOptionsKey.remoteNotification]
            
            if let notification = remoteNotification {
                appDelegate.application(self, didReceiveRemoteNotification:
                    notification as! [AnyHashable : Any],
                                 fetchCompletionHandler:  { (result) in
                })
                
            }
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
        
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("deviceToken: \(token)")
        
        let fingerprint = "hackinggate"
        let predicate = NSPredicate(format: "%K == %@", argumentArray: ["fingerprintTo", fingerprint])
        let subscription = CKQuerySubscription(recordType: GlobalNotificationType, predicate: predicate, options: .firesOnRecordCreation)
        
        
        let info = CKSubscription.NotificationInfo()
//        info.alertBody = "alert body"
//        info.shouldBadge = true
        info.soundName = "default"
        
        // How to show data from a CKRecord in alertBody of a Remote Notification?
        // https://stackoverflow.com/q/46991967/4063462
        info.alertLocalizationKey = "%1$@"
        info.alertLocalizationArgs = ["messageBlock"]

        subscription.notificationInfo = info

        CKContainer.default().publicCloudDatabase.save(subscription, completionHandler: { subscription, error in
            if error == nil {
                // Subscription saved successfully
            } else {
                // An error occurred
            }
        })
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let viewController: ViewController =
            self.window?.rootViewController as! ViewController
        
        let notification: CKNotification =
            CKNotification(fromRemoteNotificationDictionary:
                userInfo as! [String : NSObject])
        
        if (notification.notificationType ==
            CKNotification.NotificationType.query) {
            
            let queryNotification =
                notification as! CKQueryNotification
            
            let recordID = queryNotification.recordID
            
            viewController.fetchRecord(recordID!)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) {
            UIAlertAction in
            NSLog("OK Pressed")
        }
        alert.addAction(okAction)
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
