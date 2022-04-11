//
//  IAPManager.swift
//  TodayIsYou
//
//  Created by 김학철 on 2021/05/07.
//

import Foundation
import StoreKit
import SwiftyJSON

enum Product: String, CaseIterable {
    case point_00
    case point_01
    case point_02
    case point_03
    case point_04
    case point_05
    case subscribe_0
    case subscribe_1
    case subscribe_2
    case subscribe_3
    
    func severProductId() -> String {
        switch self {
            case .point_00:
            return "point_0"
            case .point_01:
            return "point_1"
            case .point_02:
            return "point_2"
            case .point_03:
            return "point_3"
            case .point_04:
            return "point_4"
            case .point_05:
            return "point_5"
            case .subscribe_0:
                return "subs_001"
            case .subscribe_1:
                return "subs_002"
            case .subscribe_2:
                return "subs_003"
            case .subscribe_3:
                return "subs_004"
        }
    }
    
    func productPrice() -> String {
        switch self {
            case .point_00:
            return "5500"
            case .point_01:
            return "11000"
            case .point_02:
            return "33000"
            case .point_03:
            return "55000"
            case .point_04:
            return "109000"
            case .point_05:
            return "219000"
            case .subscribe_0:
                return "3500"
            case .subscribe_1:
                return "5500"
            case .subscribe_2:
                return "11000"
            case .subscribe_3:
                return "33000"
        }
    }
    
    func serverItemPackageKey() ->String {
        switch self {
            case .subscribe_0:
                return "honeychat.payload.subscrip"
            case .subscribe_1:
                return "honeychat.payload.subscrip"
            case .subscribe_2:
                return "honeychat.payload.subscrip"
            case .subscribe_3:
                return "honeychat.payload.subscrip"
            case .point_00, .point_01, .point_02, .point_03, .point_04, .point_05:
                return ""
        }
    }
}

struct PointModel {
    let id:Product
    let handler: (() ->Void)
}
extension SKProduct {
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
}
final class IAPManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = IAPManager()
    private var products = [SKProduct]()
    private var productBeingPurchased:SKProduct?
    private var completion: ((_ pram:[String:Any]) -> Void)?
    private var product: Product = .point_00
    //앱스토어 상품정보를 불러온다.
    public func fetchProductus() {
        let set = Set(Product.allCases.compactMap({ $0.rawValue}))
//        let set = Set(["p_2500","p_5000","p_15000","p_25000","p_50000","p_100000"])
        let request = SKProductsRequest(productIdentifiers: set)
        request.delegate = self
        request.start()
    }
    
    public func purchage(product: Product, completion:@escaping ((_ pram:[String:Any]) -> Void)) {
        guard SKPaymentQueue.canMakePayments() else {
            return
        }
        
        self.product = product
        self.completion = completion
        if product == .subscribe_0 || product == .subscribe_1 || product == .subscribe_2 || product == .subscribe_3 {
            self.checkPendingSubscriptionProductId(product)
        }
        else {
            self.requestPayment()
        }
    }
    func requestPayment() {
        guard let storeKitProduct = products.first(where: {$0.productIdentifier == product.rawValue}) else {
            return
        }
        appDelegate.startIndicator()
        appDelegate.disableStopIndicater = true
        let paymentRequset = SKPayment(product: storeKitProduct)
        SKPaymentQueue.default().add(paymentRequset)
        SKPaymentQueue.default().add(self)
    }
    //정기결제이면 이미 구독중인 상품인지 체크한다.
    private func checkPendingSubscriptionProductId(_ product: Product) {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                var param = [String:Any]()
                param["receipt-data"] = receiptString
                param["password"] = "fd3920cace1942e187254a235ac658dc"
                
                ApiManager.ins.requestAppleValidateRecipient(param: param) {[weak self] res in
                    print(res)
                    let status = res["status"].intValue
                    if status == 0 {  //정상적인 거래 애플계정 거래
                        self?.checkVerifyReceipt(product, res)
                    }
                    else if status == 21007 {
                        //샌드박스 계정인지 한번더 체크한다.
                        ApiManager.ins.requestAppleValidateRecipientSandBox(param: param) { res in
                            let status = res["status"].intValue
                            if status == 0 {
                                self?.checkVerifyReceipt(product, res)
                            }
                            else {
                                appDelegate.window?.makeToast("Sandbox 결제 실패")
                            }
                        } fail: { error in
                            appDelegate.window?.makeToast("Sandbox 결제 실패")
                        }
                    }
                    else {
                        appDelegate.window?.makeToast("결제 실패")
                    }
                } fail: { error in
                    appDelegate.window?.makeToast("결제 실패")
                }
            }
            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        }
        else {
            print("error: aaa")
            self.requestPayment()
        }
    }
    private func checkVerifyReceipt(_ product:Product, _ res:JSON) {
        let pending_renewal_info = res["pending_renewal_info"].arrayValue
        print("subscribe proguct list: \(pending_renewal_info)")
        var isPending = false
        for item in pending_renewal_info {
//            "auto_renew_status" : "1", 자동갱신, "0" 자동갱신해지
//             "auto_renew_product_id" : "subs_0",
//             "product_id" : "subs_0",
//             "original_transaction_id" : "1000000820157263"
            let auto_renew_product_id = item["auto_renew_product_id"].stringValue
            let auto_renew_status = item["auto_renew_status"].stringValue
            
            if auto_renew_product_id == product.rawValue {
                isPending = true
            }
        }
        
        if isPending == true {
            appDelegate.window?.makeToast(NSLocalizedString("pending_renewal", comment: "이미 구독중인 상품입니다."))
        }
        else {
            self.requestPayment()
        }
    }
    private func validationCheckTransaction(transaction:SKPaymentTransaction ,callback : @escaping (_ finish : Bool) -> Void ) {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
//            서버에서 영수증 데이터, 비밀번호 (영수증에 자동 갱신 구독이 포함 된 경우) 및 requestBody에 자세히 설명 된
//            exclude-old-transactions 키를 사용하여 JSON 객체를 생성합니다. 이 JSON 객체를 HTTP POST 요청의 페이로드로 제출합니다.
//            샌드 박스에서 앱을 테스트 할 때와 애플리케이션을 검토하는 동안 테스트 환경
//            URL https://sandbox.itunes.apple.com/verifyReceipt를 사용하십시오. 앱이 App Store에 게시되면 프로덕션
//            URL https://buy.itunes.apple.com/verifyReceipt를 사용하세요. 이러한 엔드 포인트에 대한 자세한 내용은 verifyReceipt를 참조하세요.
            
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)
                
                let receiptString = receiptData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                guard let orderId = transaction.transactionIdentifier, receiptString.isEmpty == false  else {
                    callback(true)
                    return
                }
                
                #if DEBUG
//                let url: String = "https://sandbox.itunes.apple.com/verifyReceipt"
//                print("=== receipt: \(receiptString)")
                #else
//                let url: String = "https://buy.itunes.apple.com/verifyReceipt"
                #endif
                var param = [String:Any]()
                param["receipt-data"] = receiptString
                param["password"] = "fd3920cace1942e187254a235ac658dc"
                
                ApiManager.ins.requestAppleValidateRecipient(param: param) {[weak self] res in
                    print(res)
                    
                    callback(true)
                    
                    let data = ["transactionId": orderId, "receipt": receiptString]
                    self?.completion?(data)

                    /*
                    let status = res["status"].intValue
                    if status == 0 {  //정상적인 거래 애플계정 거래
                        let data = ["transactionId": orderId, "receipt": receiptString]
                        self?.completion?(data)
                    }
                    else if status == 21007 {
                        //샌드박스 계정인지 한번더 체크한다.
                        ApiManager.ins.requestAppleValidateRecipientSandBox(param: param) { res in
                            let status = res["status"].intValue
                            if status == 0 {
                                let data = ["transactionId": orderId, "receipt": receiptString]
                                self?.completion?(data)
                            }
                            else {
                                appDelegate.window?.makeToast("Sandbox 결제 실패")
                            }
                        } fail: { error in
                            appDelegate.window?.makeToast("Sandbox 결제 실패")
                        }
                    }
                    else {
                        appDelegate.window?.makeToast("결제 실패")
                    } */
                } fail: { error in
                    callback(true)
                    let data = ["transactionId": orderId, "receipt": "ERROR" + receiptString]
                    self.completion?(data)
                    appDelegate.window?.makeToast("결제 실패")
                }
            }
            catch {
                print("Couldn't read receipt data with error: " + error.localizedDescription)
                let orderId = transaction.transactionIdentifier ?? "ERROR"
                let data = ["transactionId": orderId, "receipt": "ERROR" ]
                self.completion?(data)
                callback(true)
            }
        }
    }
    
    
    ///MARK:: SKProductsRequestDelegate 앱스토어 설정한 상품정보 받음
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        print("fetch item: \(products)")
        products.forEach { p in
            print("fetch item: \(p.priceLocale), \(p.productIdentifier), \(p.localizedPrice())")
        }
    }
    
    // Observe the transaction state
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            appDelegate.disableStopIndicater = false
            appDelegate.stopIndicator()
            switch transaction.transactionState {
            case .purchasing:
                break
            case .purchased:
                self.validationCheckTransaction(transaction: transaction) { isfinish in
                    SKPaymentQueue.default().finishTransaction(transaction)
                    SKPaymentQueue.default().remove(self)
                }
                break
            case .failed:
                break
            case .restored:
                break
            case .deferred:
                break
            @unknown default:
                break
            }
        }
    }
    
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        appDelegate.stopIndicator()
        guard request is SKProductsRequest else {
            return
        }
        print("Product fetch reqeust failed")
    }
}
