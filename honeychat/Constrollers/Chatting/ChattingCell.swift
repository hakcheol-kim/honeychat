//
//  MessageTblCell.swift
//  TodayIsYou
//
//  Created by 김학철 on 2021/03/11.
//

import UIKit
import UIImageViewAlignedSwift
import SwiftyJSON

class ChattingCell: UITableViewCell {
    static let identifier = "ChattingCell"
    @IBOutlet weak var ivProfile: UIImageViewAligned!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSubTitle: UILabel!
    @IBOutlet weak var lbMsg: UILabel!
    @IBOutlet weak var ivThumb: UIImageViewAligned!
    @IBOutlet weak var btnType: CButton!
    @IBOutlet weak var lbCount: Clabel!
    
    var data:JSON!
    var completion:((_ selItem:Any?, _ action:Int) ->Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapGuestureHandler(_ :)))
        ivProfile.addGestureRecognizer(tap)
        
        let tap2 = UITapGestureRecognizer.init(target: self, action: #selector(tapGuestureHandler(_ :)))
        ivThumb.addGestureRecognizer(tap2)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configurationData(_ data: JSON?, completion:@escaping(_ selItem:Any?, _ action:Int) ->Void) {
        guard let data = data else {
            lbTitle.text = ""
            lbSubTitle.text = ""
            ivThumb.isHidden = true
            return
        }
        self.data = data
        
        self.completion = completion
        let chat_point = data["chat_point"].intValue //0;
        let confirm = data["confirm"].stringValue //Y;
        let days = data["days"].intValue //2;
        let locale = data["locale"].stringValue //"";
        var memo = data["memo"].stringValue //Hi;
        let mode = data["mode"].stringValue //;
        let msg_cnt = data["msg_cnt"].intValue //0;
        let msg_reg_date = data["msg_reg_date"].stringValue//"04:09:45.626 PM 03/11/2021";
        let page = data["page"].intValue //;
        let point_user_id = data["point_user_id"].stringValue //6ccfffe4e4b462557e674b0eb64e0eb7;
        let rownum = data["rownum"].intValue //;
        let seq = data["seq"].intValue //220;
        let talk_img = data["talk_img"].stringValue //"20210311135150182.jpg";
        let times = data["times"].stringValue //21:35:35";
        let user_age = data["user_age"].stringValue //"20\Ub300";
        let user_area = data["user_area"].stringValue //"\Uc11c\Uc6b8";
        let user_bbs_point = data["user_bbs_point"].intValue //0;
        let user_id = data["user_id"].stringValue //6ccfffe4e4b462557e674b0eb64e0eb7;
        let user_img = data["user_img"].stringValue //"20210311135150182.jpg";
        let user_name = data["user_name"].stringValue //"\Uc720\Ubbf8";
        let user_sex = data["user_sex"].stringValue //"\Uc5ec";
        let user_type = data["user_type"].stringValue //1;

        
        if Gender.mail.rawValue == (user_sex as? String) {
            ivProfile.image = Gender.mail.avatar()
        }
        else {
            ivProfile.image = Gender.femail.avatar()
        }
        if let imgUrl = Utility.thumbnailUrl(user_id, talk_img) {
            ivProfile.setImageCache(imgUrl)
        }
        ivProfile.layer.cornerRadius = ivProfile.bounds.height/2
        
        var message = ChatMsg.localizedString(memo)
        message = message.replacingOccurrences(of: "[CAM_TALK]", with: "")
        message = message.replacingOccurrences(of: "[PHONE_TALK]", with: "")
        
        lbTitle.text = message
        let sex = Gender.localizedString(user_sex)
        let tmpAttr = NSAttributedString.init(string: " \(sex)", attributes: [.foregroundColor : UIColor.label])
        
        let result = "\(user_name), \(Age.localizedString(user_age))"
        
        let attr = NSMutableAttributedString.init(string: result)
        attr.addAttribute(.foregroundColor, value: UIColor.appColor(.gray125), range: NSMakeRange(0, result.length))
        attr.addAttribute(.foregroundColor, value: UIColor.appColor(.appColor), range: NSMakeRange(0, user_name.length))
        attr.append(tmpAttr)
        
        lbSubTitle.attributedText = attr
        
        let df = CDateFormatter.init()
        df.dateFormat = "hh:mm:ss.SSS a MM/dd/yyyy"
        
        lbMsg.text = ""
        ivThumb.isHidden = true
        if let regDate = df.date(from: msg_reg_date) {
            var tStr = ""
            let curDate = Date()
            let comps = curDate - regDate
            
            if let month = comps.month, month > 0 {
                tStr = "\(month)\(NSLocalizedString("activity_txt29", comment: "달전"))"
            }
            else if let day = comps.day, day > 0 {
                tStr = String(format: "%ld%@", day, NSLocalizedString("activity_txt24", comment: "일전"))
            }
            else if let hour = comps.hour, hour > 0 {
                tStr = String(format: "%02ld%@ %02ld%@", hour,  NSLocalizedString("activity_txt66", comment: "시간"), (comps.minute ?? 0),  NSLocalizedString("activity_txt30", comment: "분전"))
            }
            else if let minute = comps.minute, minute > 0 {
                tStr = String(format: "%02ld%@ %02ld%@", minute, NSLocalizedString("activity_txt27", comment: "분"), (comps.second ?? 0), NSLocalizedString("activity_txt28", comment: "초전"))
            }
            else if let second = comps.second, second > 0 {
                tStr = String(format: "%02ld%@", second, NSLocalizedString("activity_txt28", comment: "초전"))
            }
            lbMsg.text = tStr
        }
        
        DBManager.ins.getUnReadMessageCount(messageKey: "\(seq)") { (count) in
            if count > 0 {
                self.lbCount.isHidden = false
                self.lbCount.text = "\(count)"
            }
            else {
                self.lbCount.isHidden = true
            }
        }
    }

    @objc func tapGuestureHandler(_ gesture:UITapGestureRecognizer) {
        guard let tapView = gesture.view  else {
            return
        }
        if tapView == ivProfile {
            self.completion?(self.data, 100)
        }
        else if tapView == ivThumb {
            self.completion?(self.data, 101)
        }
    }
}
