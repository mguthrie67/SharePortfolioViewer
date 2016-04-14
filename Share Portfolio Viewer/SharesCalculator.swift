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
    var members : [String]!
    
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
    

//----------------------------------------------
// single entry point. So that the UI doesn't
// need to know about porfolios
//----------------------------------------------
    func getDataForShareOrPortfolio(ind : Int, completion:(returnData: basicShareStructure) ->()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if (self.dataArray[ind].members != nil) {                                       // checking isGroup causes a seg fault!
//            if (a == 1) {
                self.getDataForPortfolio(ind) { (returnData) -> () in
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(returnData : returnData)
                    }
                }
            } else {
                self.getDataForShare(ind) { (returnData) -> () in
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(returnData : returnData)
                    }
                }
            }
        }
    }

    
//-------------------------------------
// Do portfolios
//-------------------------------------
    func getDataForPortfolio(ind : Int, completion:(returnData: basicShareStructure) ->()) {
        
        // pop our code on a thread
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
// create string of codes
            
            let codes = self.dataArray[ind].members.joinWithSeparator(",")
            
// number formatting
            
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            
// call yahoo class and process results
            
            self.yahoo.getYahooPortfolioPrices(codes) { (sharelist) -> () in
                print(sharelist)
                
                var returnData = basicShareStructure()
                
                returnData.stockPrice = "N/A"
                returnData.stockVolume = "N/A"
                returnData.stockPaid = "N/A"
                
                var currentValue = Double(0.0)
                var originalValue = Double(0.0)
                for item in sharelist {
                    
// current
                    let index = self.getIndexofCode(item.code)
                    let volume = Double(self.dataArray[index].units)
                    var value = item.price * volume
                    currentValue = currentValue + value
                    
// original
                    value = volume * self.dataArray[index].purchase
                    originalValue = originalValue + value
                    
                
                }
                
                let dif = abs(currentValue - originalValue)
                
                returnData.stockValue = "$" + numberFormatter.stringFromNumber(currentValue)!
                returnData.stockPurchase = "$" + numberFormatter.stringFromNumber(originalValue)!

                if currentValue >= originalValue {  // profit
                    returnData.stockDiff = "$" + numberFormatter.stringFromNumber(dif)!
                } else {  // loss
                    returnData.stockDiff = "-$" + numberFormatter.stringFromNumber(dif)!
                }
                
                returnData.barChartTitles = ["Bought", "Now"]
                returnData.barChartData = [originalValue, currentValue]
                
                dispatch_async(dispatch_get_main_queue()) {
                    completion(returnData : returnData)
                }
            }
        }
    }
    
//-----------------------------------
// function to find index in structure
//-----------------------------------
    func getIndexofCode(code : String) -> Int{
        for (i,x) in self.dataArray.enumerate() {
            if (x.code == code) {
                return(i)
            }
        }
        return(-1)
    }

//-------------------------------------
// Do single shares
//-------------------------------------
    
    func getDataForShare(ind : Int, completion:(returnData: basicShareStructure) ->()) {
        
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
    
    
    func getDataForHistoric(ind : Int, code : String, completion:(returnData: tableData) ->()) {
        
        if (self.dataArray[ind].members == nil) {
            self.yahoo.getYahooHistoricPrices(code, timeString: "1d") { (shares) -> () in
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
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                let returnData = tableData()
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
        
// synthetic All group
        var newItem = shareOrPortfolioData()
        newItem.code = "All"
        newItem.isGroup = true
        newItem.members = nil
        newItem.purchase = nil
        newItem.title = "All Shares"
        newItem.units = nil

        self.dataArray.append(newItem)
        
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
                
                var memberString : String
                memberString = result[index].valueForKey("code") as! String
                let memberArray = memberString.characters.split{$0 == ","}.map(String.init)  // what a shit way to do string.split(",")
                newItem.members = memberArray
                self.dataArray.append(newItem)
            }
            
        } catch {
            print("Error")
        }

// codes
        
        let freq: NSFetchRequest = NSFetchRequest(entityName: "Shares")
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
        
// update All group with the codes
        var allcodes = [String]()
        for item in self.dataArray {
            if (item.code != "All") && (item.members == nil){
                allcodes.append(item.code)
            }
        }

        self.dataArray[0].members = allcodes
    }
    
//------------------------------------------
// Delete a share from memory and storage
//------------------------------------------
    func deleteShare(code : String) {
        
// delete from our array        
        let index = self.getIndexofCode(code)
        self.dataArray.removeAtIndex(index)

// delete from Core Data
        let predicate = NSPredicate(format: "code == %@", code)
        
        let fetchRequest = NSFetchRequest(entityName: "Shares")
        fetchRequest.predicate = predicate
        
        do {
            let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Shares]
            if let entityToDelete = fetchedEntities.first {
                self.managedObjectContext.deleteObject(entityToDelete)
            }
        } catch {
            print("Failed to delete object")
        }
        
        do {
            try self.managedObjectContext.save()
        } catch {
            print("Failed to save Context")
        }
        
    }
}