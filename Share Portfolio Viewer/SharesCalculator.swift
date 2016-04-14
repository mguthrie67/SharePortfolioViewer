//
//  Handles the calculations, freeing the ViewController to manage the UI
//
//
//

import Foundation
import CoreData
import UIKit

struct basicShareStructure {
    var stockPrice      : String!
    var stockPaid       : String!
    var stockVolume     : String!
    var stockPurchase   : String!
    var stockValue      : String!
    var stockDiff       : String!
    var barChartTitles  : [String]!
    var barChartData    : [Double]!
}

struct tableData {
    var headings : [String]!
    var data     : [Double]!
}

struct shareOrPortfolioData {
    var code : String!
    var title : String!
    var purchase: Double!
    var units: Int!
    var isGroup: BooleanType!
    var members : [String!]!
    
}


class SharesCalculator {
    
    // static data - add UI to manage this later
    
    var dataArray = [shareOrPortfolioData]()

// helper class
    
    let yahoo=YahooShares()
    
// context for CoreData
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    init() {
        self.loadData()
    }
    
    func getDataForShareOrPortfolio(ind : Int, completion:(returnData: basicShareStructure) ->()) {
        
// pop our code on a thread
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

// number formatting
        
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            
        
        
        // Explanation: Don't worry about the weid syntax, this is Swift, it's all crazy.
        //              The call is asynchronous so we need to provide a function to run when
        //              it finishes. For some reason we don't put this inside the function call
        //              but instead it gets stuck on the end. So this says "call the function
        //              getYahooPrices with the parameter code and here is function stuck on the
        //              end in {} to run when you've done that. This won't then block.
            
            let code = self.dataArray[ind].code
        
            self.yahoo.getYahooPrices(code) { (shares) -> () in
            
// set the text on the screen
            
                var returnData = basicShareStructure()
            
                returnData.stockPrice = "$" + shares.bid!
                let purnum = self.dataArray[ind].purchase
                returnData.stockPaid = "$" + String(format: "%.2f", purnum)
                returnData.stockVolume = numberFormatter.stringFromNumber(self.dataArray[ind].units)
            
// calculations
            
                let pur = self.dataArray[ind].purchase
                let vol = Double(self.dataArray[ind].units)
                let now = Double(shares.last!)
                let bou = pur * vol
                let val = now! * vol
                let upd = abs(val - bou)
                returnData.stockPurchase = "$" + numberFormatter.stringFromNumber(bou)!
                returnData.stockValue = "$" + numberFormatter.stringFromNumber(val)!
                if val >= bou {  // profit
                    returnData.stockDiff = "$" + numberFormatter.stringFromNumber(upd)!
                } else {  // loss
                    returnData.stockDiff = "-$" + numberFormatter.stringFromNumber(upd)!
                }
            
// charts
            
                returnData.barChartTitles = ["Bought", "Close", "Now"]
                print(bou)
                returnData.barChartData = [bou, Double(shares.previousClose)! * vol, Double(shares.last)! * vol]
            
                dispatch_async(dispatch_get_main_queue()) {
                    completion(returnData : returnData)
                }
            }
        }
    }
 
    
    // return code and title info
    
    func getTitle(index: Int) -> String{
        return self.dataArray[index].title
    }

    func getCode(index: Int) -> String{
        return self.dataArray[index].code
    }

    func getLength() -> Int {
        return self.dataArray.count
    }
    
    
    func getDataForHistoric(code : String, completion:(returnData: tableData) ->()) {
        self.yahoo.getYahooHistoricPrices(code, timeString: "1d") { (shares) -> () in
            print(shares)
            var returnData = tableData()
            var hd = [String]()
            var dd = [Double]()

            for item in shares {
                hd.append(String(item.date))
                dd.append(item.value)
            }
            returnData.headings = hd
            returnData.data = dd
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(returnData : returnData)
            }
        }
    }
    
    //--------------------------------
    // save a group to core data
    //--------------------------------
    
    func saveNewGroup(name: String, code : String, description: String) {
        
        let group = NSEntityDescription.insertNewObjectForEntityForName("Groupings", inManagedObjectContext: self.managedObjectContext) as! Groupings
        
        group.code = code
        group.name = name
        group.title = description
        
        do {
            try self.managedObjectContext.save()
            print("Saved: \(name)")
        } catch {
            print("Error saving")
        }
    }
    //--------------------------------
    // save a share to core data
    //--------------------------------
    
    func saveNewShares(code : String, description: String, units: Int, purchasePrice: Double) {
        
        let share = NSEntityDescription.insertNewObjectForEntityForName("Shares", inManagedObjectContext: self.managedObjectContext) as! Shares
        
        
        share.code = code
        share.name = description
        share.volume = units
        share.purchasePrice = purchasePrice
        
        do {
            try self.managedObjectContext.save()
            print("Saved: \(share.code)")
        } catch {
            print("Error saving")
        }
    }
    
    
//-----------------------------------
// load our data from Core Data
//-----------------------------------
    func loadData() {

// Portfolios (Groups)
        let grReq: NSFetchRequest = NSFetchRequest(entityName: "Groupings")

        grReq.returnsObjectsAsFaults = false
//        grReq.returnsDistinctResults = true
        grReq.propertiesToFetch = ["name", "code","title"]
        
        do {
            let result : [AnyObject] = try self.managedObjectContext.executeFetchRequest(grReq)
            
            for (index, _) in result.enumerate() {
                var newItem = shareOrPortfolioData()
                newItem.code = result[index].valueForKey("name") as! String
                newItem.title = result[index].valueForKey("title") as! String
                newItem.units = nil
                newItem.purchase = nil
                newItem.isGroup = true
                newItem.members = nil
                self.dataArray.append(newItem)
            }
            
        } catch {
            print("Error")
        }

// codes
        
        let freq: NSFetchRequest = NSFetchRequest(entityName: "Shares")
 //       freq.predicate = NSPredicate(format: "code contains[c] %@", "CB")
        let sorter: NSSortDescriptor = NSSortDescriptor(key: "code", ascending: true)
        freq.sortDescriptors = [sorter]
        freq.returnsObjectsAsFaults = false
        do {
            let result : [AnyObject] = try self.managedObjectContext.executeFetchRequest(freq)
            
            for (index, _) in result.enumerate() {
                var newItem = shareOrPortfolioData()
                newItem.code = result[index].valueForKey("code") as! String
                newItem.title = result[index].valueForKey("name") as! String
                newItem.units = result[index].valueForKey("volume") as! Int
                newItem.purchase = result[index].valueForKey("purchasePrice") as! Double
                newItem.isGroup = false
                newItem.members = nil
                self.dataArray.append(newItem)
            }
            
        } catch {
            print("Error")
        }

    }
}