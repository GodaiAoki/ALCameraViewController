//
//  ViewController.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2015/06/17.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    var croppingEnabled: Bool = false
    var libraryEnabled: Bool = true
    
    let apikey:String = Bundle.main.infoDictionary!["Visual Recognition API Key"] as! String
    let classifierId:String = Bundle.main.infoDictionary!["Visual Recognition Classifier Id"] as! String
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openCamera(_ sender: AnyObject) {
        let cameraViewController = CameraViewController(croppingEnabled: croppingEnabled, allowsLibraryAccess: libraryEnabled) { [weak self] image, asset in
            self?.imageView.image = image
            
            let classifyURL = "https://gateway-a.watsonplatform.net/visual-recognition/api/v3/classify?api_key="
                + (self?.apikey)! + "&version=2016-05-20"
            
            let resizedImage:UIImage = self!.resizeImage(src: image!)
            
            let imageData:Data = UIImagePNGRepresentation(resizedImage)! as Data
            
            let jsonParams: [String: AnyObject] = ["classifier_ids": self!.classifierId as AnyObject]
            
            Alamofire.upload(
                multipartFormData: { (multipartFormData) in
                    
                    multipartFormData.append((self?.jsonToData(json: jsonParams as AnyObject)!)!, withName: "parameters")
                    
                    multipartFormData.append(imageData, withName: "images_file", fileName: "test.png", mimeType: "image/png")
                },
                to:classifyURL,
                // リクエストボディ生成のエンコード処理が完了したら呼ばれる
                encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    // エンコード成功時
                    case .success(let upload, _, _):
                        // 実際にAPIリクエストする
                        upload.responseJSON { response in
                            
                            print("responseResult: \(response.result.value)")
                            
                            
                            guard let object = response.result.value else {
                                return
                            }
                            
                            let json = JSON(object)
                            
                            var matchClass = ""
                            var matchScore:Float = 0
                            json["images"][0]["classifiers"][0]["classes"].forEach { (_, json) in
                                print("class: \(json["class"].string)")
                                print("score: \(json["score"].stringValue)")
                                if(matchScore < json["score"].floatValue){
                                    matchClass = json["class"].string!
                                    matchScore = json["score"].floatValue
                                }
                            }
                            
                            let message = "confidence:" + matchScore.description
                            let alert: UIAlertController = UIAlertController(title: "This is " + matchClass, message: message, preferredStyle:  UIAlertControllerStyle.alert)

                            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
                                // ボタンが押された時の処理を書く（クロージャ実装）
                                (action: UIAlertAction!) -> Void in
                                print("OK")
                            })
                            
                             alert.addAction(defaultAction)
                            
                            self?.present(alert, animated: true, completion: nil)
                            
                        }
                    // エンコード失敗時
                    case .failure(let encodingError):
                        print(encodingError)
                    }
                }
            )
            
            self?.dismiss(animated: true, completion: nil)
        }
        
        present(cameraViewController, animated: true, completion: nil)
    }
    
    // Convert from JSON to nsdata
    func jsonToData(json: AnyObject) -> Data?{
        do {
            return try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) as Data?
        } catch let myJSONError {
            print(myJSONError)
        }
        return nil;
    }
    
    //resizeImage
    func resizeImage(src: UIImage) -> UIImage {
        
        //Classifyするイメージはせいぜい最大320 * 320(教育データに習う)
        let maxLongSide:Int = 320
        var resizedSize:CGSize
        
        let ss = src.size
        if maxLongSide == 0 || ( Int(ss.width) <= maxLongSide && Int(ss.height) <= maxLongSide ) {
            resizedSize = ss
            return src
        }
        
        
        // リサイズ後のサイズを計算
        let ax = Int(ss.width) / maxLongSide
        let ay = Int(ss.height) / maxLongSide
        let ar = ax > ay ? ax : ay
        let re = CGRect(x: 0, y: 0, width: Int(ss.width) / ar, height: Int(ss.height) / ar)
        
        // リサイズ
        UIGraphicsBeginImageContext(re.size)
        src.draw(in: re)
        let dst = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        resizedSize = dst!.size
        
        return dst!
    }
    
    @IBAction func openLibrary(_ sender: AnyObject) {
        let libraryViewController = CameraViewController.imagePickerViewController(croppingEnabled: croppingEnabled) { image, asset in
            self.imageView.image = image
            self.dismiss(animated: true, completion: nil)
        }
        
        present(libraryViewController, animated: true, completion: nil)
    }
    
    @IBAction func libraryChanged(_ sender: AnyObject) {
        libraryEnabled = !libraryEnabled
    }
    
    @IBAction func croppingChanged(_ sender: AnyObject) {
        croppingEnabled = !croppingEnabled
    }
}

