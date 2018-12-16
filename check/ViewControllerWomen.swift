//
//  ViewControllerWomen.swift
//  check
//
//  Created by 中岡黎 on 2018/12/16.
//  Copyright © 2018 NakaokaRei. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewControllerWomen: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    var inputImage: CIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.resultLabel.text = "Analyzing Image…"
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
    let model = try! VNCoreMLModel(for: fashion_good_women().model)
    
    //分類結果はVNClassificationObservation型のオブジェクトで返ってきます。
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let values = observations[0].featureValue.multiArrayValue
            else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
            self.resultLabel.numberOfLines = 2;
            self.resultLabel.text = "あなたの服装は\(Int(Double(truncating: values[0])))いいね!"
        }
    }
    
    
    @IBAction func openCamera(_ sender: Any) {
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
