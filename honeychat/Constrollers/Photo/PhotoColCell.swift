//
//  CamTalkColCell.swift
//  TodayIsYou
//
//  Created by 김학철 on 2021/03/06.
//

import UIKit
import SwiftyJSON
import UIImageViewAlignedSwift

class PhotoColCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var btnHartCnt: UIButton!
    @IBOutlet weak var btnImgCnt: CButton!
    @IBOutlet weak var ivThumb: UIImageViewAligned!
    @IBOutlet weak var lbInfo: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var markBgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        btnHartCnt.transform = CGAffineTransform(rotationAngle: -0.785)
        containerView.layer.cornerRadius = 4
        containerView.clipsToBounds = true
    }

    func configurationData(_ data: JSON?) {
        guard let data = data else {
            lbInfo.text = ""
            return
        }
        
        let user_sex = data["user_sex"].stringValue //: "여",
        let recommend_cnt = data["recommend_cnt"].intValue //: 2,
        let view_cnt = data["view_cnt"].intValue //: 15,
        let user_id = data["user_id"].stringValue //: "a3823b02ddd794a2ea988ef385496fb7",
        let contents = data["contents"].stringValue //: "",
        let user_name = data["user_name"].stringValue //: "아이리스즈",
        let file_name = data["file_name"].stringValue //: "20210310174723375.jpg",
        let user_age = data["user_age"].stringValue //: "20대",
        let mod_date = data["mod_date"].stringValue //: 1615366319953,
        let img_cnt = data["img_cnt"].intValue //: 1,
        let locale = data["locale"].stringValue //: "",
        let seq = data["seq"].intValue //: 44
        
        if user_sex == "남" {
            ivThumb.image = Gender.mail.avatar()
        }
        else {
            ivThumb.image = Gender.femail.avatar()
        }
        
        
        if let imgUrl = Utility.thumbnailUrl(user_id, file_name) {
            ivThumb.setImageCache(imgUrl)
        }
        
        var subStr = "♀︎"
        if user_sex == "남" {
            subStr = "♂︎"
        }
        
        subStr.append(" \(Age.localizedString(user_age))")
        
        let reuslt = "\(user_name), \(subStr)"
        let attr = NSMutableAttributedString.init(string: reuslt)
        attr.addAttribute(.foregroundColor, value: UIColor.appColor(.appColor), range: NSMakeRange(0, user_name.length))
        attr.addAttribute(.foregroundColor, value: UIColor.appColor(.appColor), range: (reuslt as NSString).range(of: subStr))
        lbInfo.attributedText = attr
        btnHartCnt.setTitle("\(recommend_cnt)", for: .normal)
        btnImgCnt.setTitle("\(img_cnt)", for: .normal)
        
        
        markBgView.clipsToBounds = true
        markBgView.image = nil
        let width = markBgView.bounds.size.width
        let scale = CGAffineTransform(scaleX: 1.5, y: 1.5)
        let rotation = CGAffineTransform(rotationAngle: (45.0 * .pi)/180)
        let move = CGAffineTransform(translationX: -width/2, y: -width/2)
        let combine = scale.concatenating(rotation).concatenating(move)
        markBgView.transform = combine
        markBgView.backgroundColor = .appColor(.appColor)
        
        
    }
    
}
