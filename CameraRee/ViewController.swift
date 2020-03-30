//
//  ViewController.swift
//  CameraRee
//
//  Created by Md Reshad Bin Harun on 3/10/20.
//  Copyright © 2020 Md Reshad Bin Harun. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var ImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func chooseImage(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose an image", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action: UIAlertAction) in
            // only pick camera if available (prevents app from crashing)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            } else {
                print("Camera is not available for this device")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action: UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // delegate or protocol method that needs to be implemented
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }

        // add API to send image to backend
        ImageView.image = selectedImage
        sendImageTimestamp(image: selectedImage, filename: "NewImage")
        picker.dismiss(animated: true, completion: nil)
    }
    
    // delegate or protocol method that needs to be implemented
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Code for sending httpPost request
    func sendImageTimestamp(image: UIImage, filename: String) {
        // 2nd argument ins compression quality [0, 1.0]
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Unable to form JPEG representation")
            return
        }

        let url = URL(string: "http://localhost:3000/camera/sendImage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.timeoutInterval = 30.0

        let CRLF = "\r\n"
        let formName = "file"
        let type = "image/jpeg"     // file type
        let boundary = String(format: "----iOSURLSessionBoundary.%08x%08x", arc4random(), arc4random())
        var body = Data()

        // file data //
        body.append(("--\(boundary)" + CRLF).data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(formName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append(("Content-Type: \(type)" + CRLF + CRLF).data(using: .utf8)!)
        body.append(imageData as Data)
        body.append(CRLF.data(using: .utf8)!)

        // footer //
        body.append(("--\(boundary)--" + CRLF).data(using: .utf8)!)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]

                    if let json = jsonSerialized {
                        print(json)
                        let imageSuccessAlert =  UIAlertController(title: "Image Upload Successful!", message: json["message"] as? String, preferredStyle: .actionSheet)
                        self.present(imageSuccessAlert, animated: true, completion: nil)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }

        task.resume()
    }
    
}

