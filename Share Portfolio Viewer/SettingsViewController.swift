//
//  SettingsViewController.swift
//  Share Portfolio Viewer
//
//  Created by fullname on 14/04/2016.
//  Copyright © 2016 markguthrie. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var shareTableView: UITableView!
    @IBOutlet weak var titleField: UILabel!

    
// Share the calculator from the other view controller, this is set from the other view controller
    var calc: SharesCalculator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Inside")
        self.shareTableView.dataSource = self
        self.shareTableView.delegate = self
        
    }

//---------------------------
// pop up to delete share
//---------------------------
    func confirmDelete(index : Int, indexPath: NSIndexPath) {
        if let code = self.calc?.getCode(index) {
            let message = "Confirm deletion of \(code)."
            let alertController = UIAlertController(title: "Confirm", message: message, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
            alertController.addAction(cancelAction)
        
            let delete = UIAlertAction(title: "Delete", style: .Default) { (action) in

// delete row from calc
                self.calc?.deleteShare(code)
                
// delete row from table
                self.shareTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
// refresh
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.shareTableView.reloadData()
                })
                
            }
            alertController.addAction(delete)

            let modify = UIAlertAction(title: "Modify", style: .Default) { (action) in
                print("Do modify")
                
            }
            
            alertController.addAction(modify)
            
            self.presentViewController(alertController, animated: true) {}
        }
    }
    
    //--------------------------------------//
    // functions for the table at the side  //
    //--------------------------------------//
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.confirmDelete(indexPath.row, indexPath: indexPath)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.calc!.getLength()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = self.calc!.getCode(indexPath.row)
        cell.detailTextLabel?.text = self.calc!.getTitle(indexPath.row)
        return cell
    }


}
