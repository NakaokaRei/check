//
//  ViewControllerMen.swift
//  check
//
//  Created by 中岡黎 on 2018/12/16.
//  Copyright © 2018 NakaokaRei. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO
import GoogleMobileAds
import Accounts

class ViewControllerMen: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GADBannerViewDelegate {

    //@IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var goodLabel: UILabel!
    var inputImage: CIImage!
    
    var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //テスト広告
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .bottom,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.resultLabel.text = "Analyzing"
        self.goodLabel.text = "Image..."
        
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.cameraView.contentMode = .scaleAspectFit
            self.cameraView.image = pickedImage
        }
        
        imagePicker.dismiss(animated: true, completion: {
            guard let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
                else { fatalError("no image from image picker") }
            guard let ciImage = CIImage(image: uiImage)
                else { fatalError("can't create CIImage from UIImage") }
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(uiImage.imageOrientation.rawValue))
            self.inputImage = ciImage.oriented(forExifOrientation: Int32(orientation!.rawValue))
            
            //リクエストハンドラの作成。ここでカメラで撮影した画像を渡します。
            let handler = VNImageRequestHandler(ciImage: self.inputImage)
            self.classificationRequest_vgg = VNCoreMLRequest(model: self.model, completionHandler: self.handleClassification)
            do {
                try handler.perform([self.classificationRequest_vgg])
            } catch {
                print(error)
            }
        })
        
    }
    
    //リクエスト
    var classificationRequest_vgg: VNCoreMLRequest!
    let model = try! VNCoreMLModel(for: fashion_good_men().model)
    
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let values = observations[0].featureValue.multiArrayValue
            else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
            //self.resultLabel.numberOfLines = 2;
            self.resultLabel.text = "\(Int(Double(truncating: values[0])))"
            self.goodLabel.text = "LIKE"
        
        }
    }
    
    @IBAction func openCamera(_ sender: UIButton) {
        let camera = UIImagePickerController.SourceType.camera
        
        if UIImagePickerController.isSourceTypeAvailable(camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = camera
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        } else {
            print("error")
        }
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let camera = UIImagePickerController.SourceType.photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = camera
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        } else {
            print("error")
        }
    }
    
    @IBAction func share(_ sender: Any) {
        // 共有する項目
        let shareText = "あなたの服装は\(resultLabel.text!)いいね！！ #CHECK #服装採点アプリ\n https://itunes.apple.com/jp/app/check-%E6%9C%8D%E8%A3%85%E6%8E%A1%E7%82%B9%E3%82%A2%E3%83%97%E3%83%AA/id1448979928?l=ja&ls=1&mt=8"
        //let shareWebsite = NSURL(string: "https://itunes.apple.com/jp/app/check-%E6%9C%8D%E8%A3%85%E6%8E%A1%E7%82%B9%E3%82%A2%E3%83%97%E3%83%AA/id1448979928?l=ja&ls=1&mt=8")!
        //let shareImage = UIImage(named: "shareSample.png")!
        
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0.0)
        //viewを書き出す
        self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        // imageにコンテキストの内容を書き出す
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        //コンテキストを閉じる
        UIGraphicsEndImageContext()
        
        // 初期化処理
        let activityItems = [shareText, image] as [Any]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // 使用しないアクティビティタイプ
        let excludedActivityTypes = [
            UIActivity.ActivityType.postToFacebook,
            //UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.message,
            //UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.print
        ]
        
        activityVC.excludedActivityTypes = excludedActivityTypes
        
        // UIActivityViewControllerを表示
        self.present(activityVC, animated: true, completion: nil)
    
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
