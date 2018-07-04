//
//  pictureDetectionViewController.swift
//  Monedas
//
//  Created by Bruno Scigliano on 6/28/18.
//  Copyright © 2018 123. All rights reserved.
//

import UIKit
import Vision

class PictureDetectionViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    @IBOutlet weak var currentFrame: UIImageView!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var sumLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let labels = getModelLabels()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func takePicture(_ sender: Any) {
        let imagePickerView = UIImagePickerController()
        imagePickerView.delegate = self
        imagePickerView.sourceType = .camera
        self.present(imagePickerView, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        currentFrame.image = image
        activityIndicator.startAnimating()
        updateDetection()
    }
    
    func updateDetection() {
        sumLabel.text = "Nothing Detected..."
        do{
            let vNModel = try VNCoreMLModel(for: CoinRecognizer().model)
            let request = VNCoreMLRequest(model: vNModel, completionHandler: { (request, error) in
                guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
                    self.showNothingDetectedAlert()
                    self.activityIndicator.stopAnimating()
                    return
                }
                
                let predictions = getPredictions(confidence: results[1].featureValue.multiArrayValue!, coordinates: results[0].featureValue.multiArrayValue!)
                if predictions.count == 0 {
                    self.showNothingDetectedAlert()
                    self.activityIndicator.stopAnimating()
                    return
                }
                var sum   = 0
                let image = self.currentFrame.image!
                UIGraphicsBeginImageContext(image.size)
                let context = UIGraphicsGetCurrentContext()!
                image.draw(at: CGPoint.zero)
                
                for p in predictions {
                    let label = self.labels[p.labelIndex]
                    sum += getCoinValue(coinClass: label)
                    self.drawDetection(image: image, context: context, bb: p.boundingBox, label: label)
                }
                self.sumLabel.text = String(sum) + "$"
                let myImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                self.currentFrame.image = myImage
                self.activityIndicator.stopAnimating()

            })
            let handler = VNImageRequestHandler(cvPixelBuffer: (currentFrame.image?.pixelBuffer())!, options: [:])
            try handler.perform([request])
        }catch{
            self.showNothingDetectedAlert()
            activityIndicator.stopAnimating()
        }
    }
    
    func handlerRetry(action: UIAlertAction) {
        takePicture(self)
    }
    func showNothingDetectedAlert(){
        let alert = UIAlertController(title: "Oooops", message: "Nothing Detected", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: handlerRetry))
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func drawDetection(image: UIImage, context: CGContext, bb: CGRect, label: String) {
        let width = image.size.width
        let height = image.size.height
        context.setStrokeColor(getClassColor(coinClass: label))
        context.setAlpha(10.0)
        context.setLineWidth(20.0)
        context.addRect(CGRect(x: bb.origin.x * width, y: bb.origin.y * height, width: bb.width * width, height: bb.height * height))
        context.drawPath(using: .stroke)
    }
    @IBAction func goToARMode(_ sender: Any) {
//        performSegue(withIdentifier: "goToAR", sender: nil)
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func showHelp(_ sender: Any) {
        let alert = UIAlertController(title: "Help\n", message: "📘 - Moneda 1$\n\n📗 - Moneda 2$\n\n📒 - Moneda 5$\n\n📙 - Moneda 10$\n\n📕 - Moneda 50$", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}



