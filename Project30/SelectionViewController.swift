//
//  SelectionViewController.swift
//  Project30
//
//  Created by TwoStraws on 20/08/2016.
//  Copyright (c) 2016 TwoStraws. All rights reserved.
//

import UIKit

class SelectionViewController: UITableViewController {
    var items = [String]() // this is the array that will store the filenames to load
    var images: [UIImage?] = [UIImage]()
    
//    var viewControllers = [UIViewController]() // create a cache of the detail view controllers for faster loading
    var dirty = false
    var finishedLoadingImages = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Reactionist"

        tableView.rowHeight = 90
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // Challenge 3
        DispatchQueue.global().async { [weak self] in
            self?.loadImages()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if dirty {
            // we've been marked as needing a counter reload, so reload the whole table
            tableView.reloadData()
        }
    }
    
    // Challenge 3
    func loadImages() {
        // load all the JPEGs into our array
        let fm = FileManager.default

        if let tempItems = try? fm.contentsOfDirectory(atPath: Bundle.main.resourcePath!) {
            for item in tempItems {
                if item.range(of: "Large") != nil {
                    items.append(item)
                    
                    if let image = loadFromCache(name: item) {
                        images.append(image)
                    } else {
                        images.append(createThumbnail(currentImage: item))
                    }
                }
            }
        }
        
        finishedLoadingImages = true
        tableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: false)
    }
    
    // Challenge 3
    func loadFromCache(name: String) -> UIImage? {
        let path = getDocumentsDirectory().appendingPathExtension(name)
        return UIImage(contentsOfFile: path.path)
    }
    
    // Challenge 3
    func saveToCache(name: String, image: UIImage){
        let imagePath = getDocumentsDirectory().appendingPathExtension(name)
        if let pngData = image.pngData() {
            try? pngData.write(to: imagePath)
        }
    }
    
    // Challenge 3
    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    // Challenge 3
    func createThumbnail(currentImage: String) -> UIImage? {
        // find the image for this cell, and load its thumbnail
        let imageRootName = currentImage.replacingOccurrences(of: "Large", with: "Thumb")
        
        // Challenge 1
        guard let path = Bundle.main.path(forResource: imageRootName, ofType: nil) else { return nil }
        guard let original = UIImage(contentsOfFile: path) else { return nil }

        let renderRect = CGRect(origin: CGPoint.zero, size: CGSize(width: 90, height: 90))
        let renderer = UIGraphicsImageRenderer(size: renderRect.size)

        let rounded = renderer.image { ctx in
            ctx.cgContext.addEllipse(in: renderRect)
            ctx.cgContext.clip()

            original.draw(in: renderRect)
        }
        
        return rounded

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if !finishedLoadingImages {
            return 0
        }
        
        return items.count * 10
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // first solution
//        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "Cell")
//
//        if cell == nil {
//            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
//        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Challenge 3
        let index = indexPath.row % items.count
        cell.imageView?.image = images[index]
        
        let renderRect = CGRect(origin: CGPoint.zero, size: CGSize(width: 90, height: 90))

        // give the images a nice shadow to make them look a bit more dramatic
        cell.imageView?.layer.shadowColor = UIColor.black.cgColor
        cell.imageView?.layer.shadowOpacity = 1
        cell.imageView?.layer.shadowRadius = 10
        cell.imageView?.layer.shadowOffset = CGSize.zero
        cell.imageView?.layer.shadowPath = UIBezierPath(ovalIn: renderRect).cgPath

        // each image stores how often it's been tapped
        let defaults = UserDefaults.standard
        cell.textLabel?.text = "\(defaults.integer(forKey: items[index]))"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = ImageViewController()
        vc.image = items[indexPath.row % items.count]
        vc.owner = self

        // mark us as not needing a counter reload when we return
        dirty = false

        // add to our view controller cache and show
//        viewControllers.append(vc)
        navigationController!.pushViewController(vc, animated: true)
    }
}
