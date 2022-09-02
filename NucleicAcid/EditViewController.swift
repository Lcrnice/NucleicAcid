//
//  EditViewController.swift
//  NucleicAcid
//
//  Created by Lcrnice on 2022/9/1.
//

import UIKit

class EditViewController: UIViewController {
    
    @IBOutlet weak var laterSwitch: UISwitch!
    @IBOutlet weak var timePickerView: UIPickerView!
    @IBOutlet weak var dayStepper: UIStepper!
    @IBOutlet weak var dayLabel: UILabel!
    
    var day = 3 {
        didSet {
            dayLabel.text = "\(day)天后提醒"
            dayStepper.value = Double(day)
        }
    }
    
    var needRepeat = true {
        didSet {
            laterSwitch.isOn = needRepeat
        }
    }
    
    var timeInfo: (hour: Int, minute: Int)?
    var savedCallBack: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(white: 0.96, alpha: 1)
        title = "编辑"
        
        day = Utils.localNumber(key: U.defaultDayKey)
        needRepeat = !Utils.bool(key: U.withoutRepeatNoticeKey)
        
        
        timePickerView.delegate = self
        timePickerView.dataSource = self
        
        let hour = Utils.localNumber(key: U.noticeHourKey)
        let minute = Utils.localNumber(key: U.noticeMinuteKey)
        timeInfo = (hour, minute)
        timePickerView.selectRow(hour, inComponent: 0, animated: true)
        timePickerView.selectRow(minute, inComponent: 1, animated: true)
    }
    
    
    @IBAction func switchAction(_ sender: UISwitch) {
        
    }
    
    @IBAction func stepperAction(_ sender: UIStepper) {
        day = Int(sender.value)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        Utils.configBool(!laterSwitch.isOn, forKey: U.withoutRepeatNoticeKey)
        Utils.configNumber(day, forKey: U.defaultDayKey)
        if let hour = timeInfo?.hour, let minute = timeInfo?.minute {
            Utils.configNumber(hour, forKey: U.noticeHourKey)
            Utils.configNumber(minute, forKey: U.noticeMinuteKey)
        }
        if let callBack = savedCallBack {
            callBack()
        }

        self.navigationController?.popViewController(animated: true)
    }
}

extension EditViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        } else {
            return 60
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(format: "%.2d", row)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("component:\(component) row:\(row)")
        if component == 0 {
            timeInfo?.hour = Int(row)
        } else {
            timeInfo?.minute = Int(row)
        }
    }
    
}
