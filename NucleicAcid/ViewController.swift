//
//  ViewController.swift
//  NucleicAcid
//
//  Created by Lcrnice on 2022/9/1.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "核酸提醒"
        view.backgroundColor = UIColor.init(white: 0.95, alpha: 1)
        
        // 默认：3天后 15:30 提醒
        if Utils.localNumber(key: U.lastTestTimestampKey) == 0 {
            Utils.configNumber(3, forKey: U.defaultDayKey )
            Utils.configNumber(15, forKey: U.noticeHourKey)
            Utils.configNumber(30, forKey: U.noticeMinuteKey)
        }
        
        UNUserNotificationCenter.current().delegate = self
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let `self` = self else { return }
            self.checkTestStatus()
        }
        
        checkTestStatus()
    }
    
    func checkTestStatus() {
        let lastTestTS = Utils.localNumber(key: U.lastTestTimestampKey)
        let noticeHour = Utils.localNumber(key: U.noticeHourKey)
        let noticeMinute = Utils.localNumber(key: U.noticeMinuteKey)
        let hourString = String(format: "%.2d", noticeHour)
        let minuteString = String(format: "%.2d", noticeMinute)
        let noticeTS = Utils.localNumber(key: U.targetTimestampKey)
        let currentTS = currentTS()
        let noticeDaySeconds = self.second(hour: noticeHour, minute: noticeMinute)
        let leftTS = noticeTS - currentTS
        
        if lastTestTS == 0 {
            updateComponent(false, dayText: "还没有做过核酸哦", timeText: "")
            return
        }
        
        var dayText = ""
        var timeText = ""
        if leftTS < 0 {
            // 已到提醒时间
            dayText = "已超时"
            timeText = "现在去做！"
        } else if leftTS < noticeDaySeconds {
            // 今天
            dayText = "今天"
            timeText = "\(hourString):\(minuteString)"
        } else if leftTS > noticeDaySeconds {
            // 更早
            let leftDayTS = noticeTS - self.todayRemindTimestamp()
            // 模拟【北京健康宝】的天数显示方式
            // 算出 [今晚凌晨] 到 [提醒时间] 之间的秒数，用其除 [一整天] 的秒数，余数结果 +1 就是对应几天后提醒
            let day = leftDayTS / U.oneDaySeconds + 1
            dayText = "\(day)天后"
            timeText = "\(hourString):\(minuteString)"
        }
        updateComponent(true, dayText: dayText, timeText: timeText)
        
        func updateComponent(_ tested: Bool, dayText: String, timeText: String) {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                self.dayLabel.text = dayText
                self.timeLabel.text = timeText
                self.editButton.isEnabled = tested
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let editId = segue.identifier, editId == "showEditVC", let editVC = segue.destination as? EditViewController {
            editVC.savedCallBack = { [weak self] in
                guard let `self` = self else { return }
                
                self.configTestNotification()
            }
        }
    }
}

// MARK: - Actions
extension ViewController {
    @IBAction func didTestAction(_ sender: Any) {
        let alert = UIAlertController(title: "提醒", message: "确认已经做过核酸了对吗？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: "当然", style: .destructive) { [weak self] _ in
            guard let `self` = self else { return }
            
            let currentTS = self.currentTS()
            Utils.configNumber(currentTS, forKey: U.lastTestTimestampKey)
            
            self.configTestNotification()
        }
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Notifications   
extension ViewController {
    func requestNotificationAuth(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
            guard error != nil || granted else {
                self.showOpenNotificationAlert()
                return
            }
            
            completion(granted)
        }
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                completion(true)
            } else if settings.authorizationStatus == .notDetermined {
                self.requestNotificationAuth { TorF in
                    if TorF {
                        completion(true)
                    } else {
                        self.showOpenNotificationAlert()
                    }
                }
            } else {
                self.showOpenNotificationAlert()
            }
        }
    }
    
    func createNotification(second: Int) {
        let second = TimeInterval(second)
        
        let content = UNMutableNotificationContent()
        content.title = "【核酸提醒】"
        content.subtitle = "铁子，你的核酸就要过期了，赶紧去捅一下子"
        content.body = "🦠🦠🦠😷🦠🦠🦠"
        content.badge = 1
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: second, repeats: false)
        let request = UNNotificationRequest(identifier: "com.nucleicAcid.notification.\(second)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if let _ = error {
                let failAlert = UIAlertController(title: "提醒", message: "添加通知失败...", preferredStyle: .alert)
                let action = UIAlertAction(title: "行吧", style: .cancel) { _ in
                }
                failAlert.addAction(action)
                DispatchQueue.main.async {
                    self.present(failAlert, animated: true, completion: nil)
                }
            }
            print("成功建立 \(second)s 后的通知...")
        })
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("在前景收到通知...")
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        completionHandler()
    }
}

// MARK: - Helpers
extension ViewController {
    func configTestNotification() {
        self.checkNotificationStatus { [weak self] ok in
            guard let `self` = self, (ok) else { return }
            
            let targetSeconds = self.secondsBeforeNotice()
            Utils.configNumber(targetSeconds, forKey: U.targetTimestampKey)
            self.createNotification(second: targetSeconds)
            if !Utils.bool(key: U.withoutRepeatNoticeKey) {
                self.createNotification(second: targetSeconds + 15 * 60)    // 15min 后再次提醒
                self.createNotification(second: targetSeconds + 30 * 60)    // 30min 后再次提醒
            }
            self.checkTestStatus()
        }
    }
    
    func currentTS() -> Int {
        Int(NSDate().timeIntervalSince1970)
    }
    
    func second(hour: Int = 15, minute: Int = 30) -> Int {
        (hour * (60 * 60)) + (minute * 60)
    }
    
    func todayRemindTimestamp() -> Int {
        let components = NSCalendar.current.dateComponents(Set<Calendar.Component>.init(arrayLiteral: .year, .month, .day), from: Date())
        let todayStart = NSCalendar.current.date(from: components)!
        let todayEnd = NSCalendar.current.date(byAdding: .hour, value: 24, to: todayStart)!
        return Int(todayEnd.timeIntervalSince1970)
    }
    
    func secondsBeforeNotice() -> Int {
        let days = Utils.localNumber(key: U.defaultDayKey)
        let noticeHour = Utils.localNumber(key: U.noticeHourKey)
        let noticeMinute = Utils.localNumber(key: U.noticeMinuteKey)
        let noticeDaySeconds = self.second(hour: noticeHour, minute: noticeMinute)
        let todayWeeHourTimestamp = self.todayRemindTimestamp()
        var midSeonds = 0
        if days > 1 {
            midSeonds = (days - 1) * U.oneDaySeconds
        } else if days <= 0 {
            self.showAlert(message: "\(days)天后是不合法的")
        }
        
        // 今晚凌晨时的时间戳 + 后续完整天的总秒数 + 提醒当天的剩余秒数
        let target = todayWeeHourTimestamp + midSeonds + noticeDaySeconds
        return target
    }
    
    func showOpenNotificationAlert() {
        let settingAlert = UIAlertController(title: "提醒", message: "请开启通知！", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        settingAlert.addAction(action)
        DispatchQueue.main.async {
            self.present(settingAlert, animated: true, completion: nil)
        }
    }
    
    func showAlert(message: String) {
        let noticeAlert = UIAlertController(title: "提醒", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "确定", style: .cancel) { _ in
        }
        noticeAlert.addAction(action)
        DispatchQueue.main.async {
            self.present(noticeAlert, animated: true, completion: nil)
        }
    }
}
