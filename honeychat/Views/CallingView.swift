//
//  CallingView.swift
//  TodayIsYou
//
//  Created by 김학철 on 2021/04/25.
//

import UIKit
import SwiftyJSON
import AVFoundation

class CallingView: UIView {
    @IBOutlet weak var svContent: UIStackView!
    @IBOutlet weak var btnBell: PulseButton!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSubTitle: UILabel!
    @IBOutlet weak var btnReject: CButton!
    @IBOutlet weak var btnAccept: CButton!
    @IBOutlet weak var svBtn: UIStackView!
    
    var player = AVAudioPlayer.init()
    
    var completion:((_ data: JSON, _ actionIndex:Int)->Void)?
    var data: JSON!
    var shakTimer:Timer!
    var count = 0
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    func configurationData(_ type:PushType, _ data:JSON, _ completion:((_ data: JSON, _ actionIndex:Int)->Void)?) {
        self.data = data
        self.completion = completion
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapGestureHandler))
        self.addGestureRecognizer(tap)
        
        let user_name:String
        let user_name1 = data["user_name"].stringValue
        let user_name2 = data["from_user_name"].stringValue
        if(user_name1.isEmpty){
             user_name = user_name2
        }else{
             user_name = user_name1
        }
        let user_sex:String
        let user_sex1 = data["user_sex"].stringValue
        let user_sex2 = data["from_user_gender"].stringValue
        if(user_sex1.isEmpty){
             user_sex = user_sex2
        }else{
             user_sex = user_sex1
        }
        let user_age:String
        let user_age1 = data["user_age"].stringValue
        let user_age2 = data["from_user_age"].stringValue
        if(user_age1.isEmpty){
             user_age = user_age2
        }else{
             user_age = user_age1
        }
       
        btnBell.isAnimated = true
        if type == .rdCam {
            svBtn.isHidden = true
        }
        
        if let notiYn = ShareData.ins.dfsGet(DfsKey.notiYn) as? String {
            if notiYn == "A" || notiYn == "S" {
                appDelegate.audioPlayer.play()
            }
        }
        
        if let notiYn = ShareData.ins.dfsGet(DfsKey.notiYn) as? String {
            if notiYn == "A" || notiYn == "V" {
                self.stopShakTimer()
                self.shakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (time) in
                    self.count += 1
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    if self.count >= 30 {
                        time.invalidate()
                        time.fire()
                    }
                }
            }
        }
        /// mjkim
        if type == .rdCam {
            self.btnReject.isHidden = true
            self.btnAccept.isHidden = true
        }
            
            
        let msg_cmd = data["msg_cmd"].stringValue
        if msg_cmd == "CAM" {
            lbTitle.text = "\(user_name)(\(user_sex), \(user_age)\(NSLocalizedString("activity_txt317", comment: ")이 영상채팅을 신청했습니다.!!"))"
            if "남" == ShareData.ins.mySex.rawValue {
                let p = ShareData.ins.dfsGet(DfsKey.phoneOutUserPoint) as! NSNumber
                lbSubTitle.text = "\(NSLocalizedString("activity_txt205", comment: "수락 시 10초당")) \(p.stringValue) \(NSLocalizedString("activity_txt213", comment: "포인트가 차감됩니다."))"
            }
            else {
                lbSubTitle.text = NSLocalizedString("activity_txt321", comment: "수락(음성채팅) 시 여성은 별이 적립됩니다.")
            }
        }
        else {
            lbTitle.text = "\(user_name)(\(user_sex), \(user_age)\(NSLocalizedString("activity_txt323", comment: ")이 음성채팅을 신청 했습니다!!"))"
            if "남" == ShareData.ins.mySex.rawValue {
                let p = ShareData.ins.dfsGet(DfsKey.phoneOutUserPoint) as! NSNumber
                lbSubTitle.text = "\(NSLocalizedString("activity_txt205", comment: "수락 시 10초당")) \(p.stringValue) \(NSLocalizedString("activity_txt213", comment: "포인트가 차감됩니다."))"
            }
            else {
                lbSubTitle.text = NSLocalizedString("activity_txt321", comment: "수락(음성채팅) 시 여성은 별이 적립됩니다.")
            }
        }
    }

    @objc func tapGestureHandler() {
        completion?(data, 200)
    }
    
    @IBAction func onClickedBtnactions(_ sender: UIButton) {
        if sender == btnReject {
            completion?(data, 100)
        }
        else if sender == btnAccept {
            completion?(data, 101)
        }
    }
    class func show(_ type:PushType, _ data: JSON, _ completion:((_ data: JSON, _ actionIndex:Int)->Void)?) {
        let window = appDelegate.window
        if let view = window?.viewWithTag(TagCallingView) {
            view.removeFromSuperview()
        }
        
        let callingview = Bundle.main.loadNibNamed("CallingView", owner: nil, options: nil)?.first as! CallingView
        
        window?.addSubview(callingview)
        callingview.tag = TagCallingView
        callingview.translatesAutoresizingMaskIntoConstraints = false
        callingview.topAnchor.constraint(equalTo: window!.topAnchor, constant: 0).isActive = true
        callingview.leadingAnchor.constraint(equalTo: window!.leadingAnchor, constant: 0).isActive = true
        callingview.trailingAnchor.constraint(equalTo: window!.trailingAnchor, constant: 0).isActive = true
        callingview.addShadow(offset: CGSize(width: 3, height: 3), color: UIColor.appColor(.blackAlpa30), raduius: 3, opacity: 0.3)
        let top = window!.safeAreaInsets.top + 16
        callingview.svContent.layoutMargins = UIEdgeInsets(top: top, left: 16, bottom: 16, right: 16)
        
        callingview.configurationData(type, data, completion)
    }
    func stopShakTimer() {
        if let timer = shakTimer {
            timer.invalidate()
            timer.fire()
        }
    }
    deinit {
        print("callingview deinit")
        self.stopShakTimer()
    }
}