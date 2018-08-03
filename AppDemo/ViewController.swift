//
//  ViewController.swift
//  AppDemo
//
//  Created by Development on 7/30/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchKeywordLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet var mainView: UIView!
    var imagePicker: UIImagePickerController
    var items: [[String: Any]]
    
    required init?(coder aDecoder: NSCoder) {
        imagePicker = UIImagePickerController()
        self.items = []
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func pictureAction(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Take Picture", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.triggerPicker(.camera)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Select From Library", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.triggerPicker(.photoLibrary)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func triggerPicker(_ source: UIImagePickerControllerSourceType) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let sourceImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        image.image = sourceImage?.circleMasked
        
        imageSearch(sourceImage)
    }
    
    func imageSearch(_ anImage: UIImage?) {
        guard let image = anImage else {
            return
        }
        
        let imageData = UIImageJPEGRepresentation(image, 0.5)
        let base64Image = imageData?.base64EncodedString()
        
        let body: [String: Any] =
            ["inputs": [[
                "data": [
                    "image": ["base64": base64Image]
                    ]
            ]],
            "model": [
                "output_info": [
                    "output_config": [
                        "max_concepts": 3
                    ]
                ]
            ]
        ]
        
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("Cannot encode payload")
            return
        }
        
        let key = "3cd29c1142464c0c8b8cb6a1f1c400ca"
        
        let url = URL(string: "https://api.clarifai.com/v2/models/aaa03c23b3724a16a56b629203edc62c/outputs")!
        var request = URLRequest(url: url)
        request.setValue("Key \(key)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                let alert = UIAlertController(title: "Cannot process image", message: "An error occurred: \(errorMessage)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }

            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                self.processResponse(responseJSON)
            } else {
                let alert = UIAlertController(title: "Cannot process image", message: "Couldn't process JSON data from the image recognition provider.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)

            }
        }
        
        task.resume()
        setLabel("Analyzing image…")
    }
    
    func processResponse(_ response: [String: Any]) {
        guard let outputs = response["outputs"] as? [[String: Any]] else {
            setLabel("Try again")
            return
        }
        
        guard let firstOutput = outputs.first else {
            setLabel("No results")
            return
        }
        
        guard let data = firstOutput["data"] as? [String: Any] else {
            setLabel("No data")
            return
        }

        guard let concepts = data["concepts"] as? [[String: Any]] else {
            setLabel("Try again")
            return
        }
        
        for concept in concepts {
            guard let keyword = concept["name"] as? String else {
                continue
            }

            if keyword != "no person" {
                setLabel(keyword)
                searchProductsByKeyword(keyword)
                return
            }
        }
        
        setLabel("Try again")
    }
    
    func searchProductsByKeyword(_ keyword: String) {
        
        let key = "t44zjhyudjf2xjhvckumennq"
        let baseUrl = "https://api.walmartlabs.com/v1/search?query=\(keyword)&format=json&apiKey=\(key)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let url = URL(string: baseUrl)!
        
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                let alert = UIAlertController(title: "Cannot search products", message: "An error occurred: \(errorMessage)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                self.setLabel(keyword)
                self.processProductResponse(responseJSON)
            } else {
                let alert = UIAlertController(title: "Cannot search products", message: "Couldn't process JSON data from the search provider.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)
                
            }
        }
        
        task.resume()
        setLabel("Getting products…")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath)
        let data = items[indexPath.row]
        let price = NSNumber(value: (data["price"] as? NSNumber ?? 0).floatValue)
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        let formattedPrice = formatter.string(from: price)
        cell.textLabel?.text = data["name"] as? String ?? "Product name"
        cell.detailTextLabel?.text = formattedPrice
        
        let thumbnailURL = URL(string: data["thumbnailImage"] as! String)!
        let thumbnailData = try? Data(contentsOf: thumbnailURL)
        cell.imageView?.image = UIImage(data: thumbnailData!)
        return cell
    }
    
    func processProductResponse(_ data: [String: Any]) {
        guard data["items"] != nil else {
            items = []
            DispatchQueue.main.sync {
                self.tableView.reloadData()
            }
            return
        }
        
        items = data["items"] as! [[String: Any]]
        DispatchQueue.main.sync {
            self.tableView.reloadData()
        }
    }
    
    func setLabel(_ label: String) {
        if Thread.current.isMainThread {
            searchKeywordLabel.text = label
        } else {
            DispatchQueue.main.sync {
                searchKeywordLabel.text = label
            }
        }
    }
}

extension UIImage {
    var isPortrait:  Bool    { return size.height > size.width }
    var isLandscape: Bool    { return size.width > size.height }
    var breadth:     CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation).draw(in: breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
