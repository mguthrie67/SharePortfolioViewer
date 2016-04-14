//
// Class to handle getting share data from yahoo finances
// There was an implementation of this (SwiftStockKit) but it doesn't work properly
//

import Foundation
import Alamofire

// structure for share data

struct ShareData {
    var ask:            String!
    var bid:            String!
    var changeNumeric:  String!
    var changePercent:  String!
    var dayHigh:        String!
    var dayLow:         String!
    var last:           String!
    var lastTradeTime:  String!
    var open:           String!
    var previousClose:  String!
    var volume:         String!
    var yearHigh:       String!
    var yearLow:        String!
}

// stucture for historic data - single points, we send these back as lists of points (ShareHistoricData)

struct ShareHistoricData {
    var date: NSDate!
    var value: Double!
}

// structure for portfolios

struct SharePortfolioPrices {
    var code: String!
    var price: Double!
}

// class

class YahooShares {
 
// ---------------------------------------------
// Get current price data for a single stock
// ---------------------------------------------
    
    func getYahooPrices(code : String, completion:(sd: ShareData) -> ()){
    
//
// Explanation: The underlying calls here are asynchronous so we need to put ourselves on a queue
//              and provide the function call with what to do when we finish. Hence the weird
//              completion() thing which I think means that we return nil but when we are really
//              finished we will call the function "completion" passing in a ShareData structure.
//              When we are called we need to be provided with a function to deal with the data
//              that we pass, so the syntax is pretty weird on the other side too. Its basically
//              just an inline function though.
//
        
// pop our code on a thread
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        
            let URL = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22\(code)%22)&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&format=json"
        
// call Alamofire to do the networking
        
            Alamofire.request(.GET, URL) .responseJSON { response in
        
// get the JSON payload
            
                if let resultJSON = response.result.value as? [String : AnyObject]  {
                
// it's nested, so pull out the bit we want
                
                    if let shareData = ((resultJSON["query"] as! [String : AnyObject])["results"] as! [String : AnyObject])["quote"] as? [String : AnyObject] {
           
// now put it into the structure and return it
                    
                        var sd = ShareData()
              
// optionals everywhere - need to get rid of them
                    
                        if let val = shareData["Bid"]                   {sd.bid             = String(val)}
                        if let val = shareData["Ask"]                   {sd.ask             = String(val)}
                        if let val = shareData["LastTradeTime"]         {sd.lastTradeTime   = String(val)}
                        if let val = shareData["ChangeinPercent"]       {sd.changePercent   = String(val)}
                        if let val = shareData["Change"]                {sd.changeNumeric   = String(val)}
                        if let val = shareData["LastTradePriceOnly"]    {sd.last            = String(val)}
                        if let val = shareData["LastTradeTime"]         {sd.lastTradeTime   = String(val)}
                        if let val = shareData["Open"]                  {sd.open            = String(val)}
                        if let val = shareData["Volume"]                {sd.volume          = String(val)}
                        if let val = shareData["PreviousClose"]         {sd.previousClose   = String(val)}
                        if let val = shareData["YearHigh"]              {sd.yearHigh        = String(val)}
                        if let val = shareData["YearLow"]               {sd.yearLow         = String(val)}
                        
// now we need to get ourselves on the main thread and to call the provided function, passing in our data
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(sd: sd)
                        }
                    }
                }
            }
        }
    }
    
// ---------------------------------------------
// Get historic prices data for a single stock
// ---------------------------------------------
    
    func getYahooHistoricPrices(code : String, timeString : String, completion:(sd: [ShareHistoricData]) -> ()){
        
// pop our code on a thread
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let URL = "http://chartapi.finance.yahoo.com/instrument/1.0/\(code)/chartdata;type=quote;range=\(timeString)/json"
            
// call Alamofire to do the networking [bug: need to use responseData as responseJSON fails]
            
            Alamofire.request(.GET, URL) .responseData { response in
        
// get the JSON payload
                
                if let data = response.result.value {

// we need to do some trickery. The parsers don't like the bracket parts we get on the outside
                    
                    var jsonString =  NSString(data: data, encoding: NSUTF8StringEncoding)!

// strip the wrapper
                    
                    jsonString = jsonString.substringFromIndex(30)
                    jsonString = jsonString.substringToIndex(jsonString.length-1)
                    
// put it in an NSData object
                    
                    var js=NSData()
                    js = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
                    
// at this point I fought with Swift and JSON for a long time before installing SwiftyJSON which is used here
                    
                    let historicData = JSON(data: js)
                    
// create array of data structures to hold return value
                    
                    var sd = [ShareHistoricData]()
                    
// get the gmt offset so we can adjust the timestamps for current location
                    
                    let ourOffset = NSTimeZone.localTimeZone().secondsFromGMT
                    let theirOffset = historicData["meta"]["gmtoffset"].int
                    let offset = theirOffset! + ourOffset
                    
// Go through the "series" data and add to array
                    
                    let valueBlock = historicData["series"]
                    
                    for (_, subJson):(String, JSON) in valueBlock {
                        
                        var item = ShareHistoricData()
                        let timestamp = subJson["Timestamp"].double! + Double(offset)
                        item.date=NSDate(timeIntervalSince1970: timestamp)
                        item.value=subJson["close"].double
                        sd.append(item)
                    }
                        
// now call the completion function
                        
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(sd: sd)
                    }
                }
            }
        }
    }
    
//----------------------------------------
// Get prices for multiple shares 
//----------------------------------------
    func getYahooPortfolioPrices(codes : String, completion:(results: [SharePortfolioPrices]) -> ()){
        
        // pop our code on a thread
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            var results = [SharePortfolioPrices]()
            
//            let URL = "https://query.yahooapis.com/v1/public/yql?q=select%20symbol,Bid%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22\(codes)%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="

            let URL = "https://query.yahooapis.com/v1/public/yql?q=select%20symbol,LastTradePriceOnly%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22\(codes)%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"

            print(URL)
            
            // call Alamofire to do the networking
            
            Alamofire.request(.GET, URL) .responseData { response in
            
                let json = JSON(data: response.result.value!)
                
                for (_, subJson):(String, JSON) in json["query"]["results"]["quote"] {
                    
// check we go something back
                    let symbolExists = subJson["symbol"] != nil
                    let priceExists = subJson["LastTradePriceOnly"] != nil
                    
                    if (symbolExists && priceExists) {
                        let item = SharePortfolioPrices(code: subJson["symbol"].string, price: Double(subJson["LastTradePriceOnly"].string!))
                        results.append(item)
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {
                    completion(results : results)
                }
            }
        }
    }
}