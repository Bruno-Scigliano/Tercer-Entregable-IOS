//
//  Utils.swift
//  Monedas
//
//  Created by Bruno Scigliano on 6/25/18.
//  Copyright © 2018 123. All rights reserved.
//

import Foundation
import CoreML
import UIKit

func getPredictionFromFeatures(confidence:  MLMultiArray, coordinates: MLMultiArray) -> [Prediction]{
    let confidenceThreshold = 0.3
    var unorderedPredictions = [Prediction]()
    let numBoundingBoxes = confidence.shape[0].intValue
    let numClasses = confidence.shape[1].intValue
    let confidencePointer = UnsafeMutablePointer<Double>(OpaquePointer(confidence.dataPointer))
    let coordinatesPointer = UnsafeMutablePointer<Double>(OpaquePointer(coordinates.dataPointer))
    for b in 0..<numBoundingBoxes {
        var maxConfidence = 0.0
        var maxIndex = 0
        for c in 0..<numClasses {
            let conf = confidencePointer[b * numClasses + c]
            if conf > maxConfidence {
                maxConfidence = conf
                maxIndex = c
            }
        }
        if maxConfidence > confidenceThreshold {
            let x = coordinatesPointer[b * 4]
            let y = coordinatesPointer[b * 4 + 1]
            let w = coordinatesPointer[b * 4 + 2]
            let h = coordinatesPointer[b * 4 + 3]
            
            let rect = CGRect(x: CGFloat(x - w/2), y: CGFloat(y - h/2),
                              width: CGFloat(w), height: CGFloat(h))
            
            let prediction = Prediction(labelIndex: maxIndex,
                                        confidence: Float(maxConfidence),
                                        boundingBox: rect)
            unorderedPredictions.append(prediction)
        }
    }
    return unorderedPredictions
}

func getCoinValue(coinClass: String) -> Int {
    switch coinClass {
        case "Coin-1":
            return 1
        case "Coin-2":
            return 2
        case "Coin-5":
            return 5
        case "Coin-10":
            return 10
        case "Coin-50":
            return 50
        default:
            return 0
        }
}
func getFinalPredictions(unorderedPredictions: [Prediction] ) -> [Prediction]{
    let nms_threshold = Float(0.5)
    var predictions: [Prediction] = []
    let orderedPredictions = unorderedPredictions.sorted { $0.confidence > $1.confidence }
    var keep = [Bool](repeating: true, count: orderedPredictions.count)
    for i in 0..<orderedPredictions.count {
        if keep[i] {
            predictions.append(orderedPredictions[i])
            let bbox1 = orderedPredictions[i].boundingBox
            for j in (i+1)..<orderedPredictions.count {
                if keep[j] {
                    let bbox2 = orderedPredictions[j].boundingBox
                    if IoU(bbox1, bbox2) > nms_threshold {
                        keep[j] = false
                    }
                }
            }
        }
    }
    return predictions
}

func getPredictions(confidence:  MLMultiArray, coordinates: MLMultiArray) -> [Prediction] {
    let rawPredictions = getPredictionFromFeatures(confidence: confidence, coordinates: coordinates)
    return getFinalPredictions(unorderedPredictions: rawPredictions)
}
func IoU(_ a: CGRect, _ b: CGRect) -> Float {
    let intersection = a.intersection(b)
    let union = a.union(b)
    return Float((intersection.width * intersection.height) / (union.width * union.height))
}

func getClassColor(coinClass: String) -> CGColor {
    switch coinClass {
    case "Coin-1":
        return UIColor.blue.cgColor
    case "Coin-2":
        return UIColor.green.cgColor
    case "Coin-5":
        return UIColor.yellow.cgColor
    case "Coin-10":
        return UIColor.orange.cgColor
    case "Coin-50":
        return UIColor.red.cgColor
    default:
        return UIColor.black.cgColor
    }
}

func getModelLabels() -> [String] {
    let userDefined: [String: String] = CoinRecognizer().model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey]! as! [String : String]
    return userDefined["classes"]!.components(separatedBy: ",")
}

