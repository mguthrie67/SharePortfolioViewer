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


class SharesCalculator {
    
    // static data - add UI to manage this later
    
    var titleArray = ["All shares", "A2 Milk Company", "Bega Cheese", "Commonwealth Bank", "Cochlear", "CSL Limited", "G8 Education", "Gen Healthcare", "Macquarie Group", "Transurban Group", "Westfield"]
    var codeArray = ["All", "A2M.ax", "BGA.ax", "CBA.ax", "COH.ax", "CSL.ax", "GEM.ax", "GHC.ax", "MQG.ax", "TCL.ax", "WFD.ax"]
    var purchaseArray = ["0", "1.658", "6.01", "76.786", "101.269", "103.991", "3.694", "1.906", "65.852", "11.091", "10.102"]
    var unitsArray = ["0", "10000", "1000", "1000", "500", "800", "15000", "25000", "500", "7000", "8000"]

// helper class
    
    let yahoo=YahooShares()
    
// context for CoreData
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func getDataForShareOrPortfolio(code : String, completion:(returnData: basicShareStructure) ->()) {
        
// pop our code on a thread
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

// number formatting
        
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
    
            
            
  //          var coredata = [NSManagedObject]()
            
        
        
        // Explanation: Don't worry about the weid syntax, this is Swift, it's all crazy.
        //              The call is asynchronous so we need to provide a function to run when
        //              it finishes. For some reason we don't put this inside the function call
        //              but instead it gets stuck on the end. So this says "call the function
        //              getYahooPrices with the parameter code and here is function stuck on the
        //              end in {} to run when you've done that. This won't then block.
        
            self.yahoo.getYahooPrices(code) { (shares) -> () in
            
// find index of arrays from the code passed
            
                let ind = self.codeArray.indexOf(code)
            
// set the text on the screen
            
                var returnData = basicShareStructure()
            
                returnData.stockPrice = "$" + shares.bid!
                let purnum = Double(self.purchaseArray[ind!])
                returnData.stockPaid = "$" + String(format: "%.2f", purnum!)
                returnData.stockVolume = numberFormatter.stringFromNumber(Double(self.unitsArray[ind!])!)
            
// calculations
            
                let pur = Double(self.purchaseArray[ind!])
                let vol = Double(self.unitsArray[ind!])
                let now = Double(shares.last!)
                let bou = pur! * vol!
                let val = now! * vol!
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
                returnData.barChartData = [bou, Double(shares.previousClose)! * vol!, Double(shares.last)! * vol!]
            
                dispatch_async(dispatch_get_main_queue()) {
                    completion(returnData : returnData)
                }
            }
        }
    }
 
    
    // return code and title info
    
    func getTitle(index: Int) -> String{
        return self.titleArray[index]
    }

    func getCode(index: Int) -> String{
        return self.codeArray[index]
    }

    func getLength() -> Int {
        return self.codeArray.count
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
    
 //   func saveNewShares(code : String, description: String, units: Int, purchasePrice: Double, purchaseDate: NSDate) {
        
        
   //     var share = NSEntityDescription.insertNewObjectForEntityForName("DataModel", inManagedObjectContext: self.managedObjectContext) as Code
            
   //     share.code = code
   //     share.title = description
   //     share.purchased = purchaseDate
   //     share.volume = units
   //     share.price = purchasePrice
        
    //    do {
    //        try self.managedObjectContext.save()
    //    } catch {
    //        print("Error saving")
    //    }
        
        
  //  }
    
}