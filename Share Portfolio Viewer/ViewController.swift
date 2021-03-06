//
//  ViewController.swift
//  Share Portfolio Viewer
//

import UIKit
import Alamofire
import Charts
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var boughtLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var purchasedLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    @IBOutlet weak var stockName: UILabel!
    @IBOutlet weak var stockVolume: UILabel!
    @IBOutlet weak var stockBought: UILabel!
    @IBOutlet weak var stockValue: UILabel!
    @IBOutlet weak var stockPurchased: UILabel!
    @IBOutlet weak var stockDifference: UILabel!
    @IBOutlet weak var stockPrice: UILabel!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var lineChartView: LineChartView!
    
    
    // create instances of our helper classes
    
    let calc = SharesCalculator()
    
    
    // main entry point
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make this the source of data for the table and act as its delegate (enable function calls to come here)
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
// start first thing on the list
        self.getData(0, code: self.calc.getCode(0), name: self.calc.getTitle(0))
        
        
//        self.calc.saveNewShares("A2M.ax", description: "A2 Milk Company", units: 10000, purchasePrice: 1.658)
//        self.calc.saveNewShares("BGA.ax", description: "Bega Cheese", units: 1000, purchasePrice: 6.01)
//        self.calc.saveNewShares("CBA.ax", description: "Commonwealth Bank", units: 1000, purchasePrice: 76.786)
//        self.calc.saveNewShares("COH.ax", description: "Cochlear", units: 500, purchasePrice: 101.269)
//        self.calc.saveNewShares("CSL.ax", description: "CSL Limited", units: 800, purchasePrice: 103.991)
//        self.calc.saveNewShares("GEM.ax", description: "G8 Education", units: 15000, purchasePrice: 3.694)
//        self.calc.saveNewShares("GHC.ax", description: "Gen Healthcare", units: 25000, purchasePrice: 1.906)
//        self.calc.saveNewShares("MQG.ax", description: "Macquarie Group", units: 500, purchasePrice: 65.852)
//        self.calc.saveNewShares("TCL.ax", description: "Transurban Group", units: 7000, purchasePrice: 11.091)
//        self.calc.saveNewShares("WFD.ax", description: "Westfield", units: 8000, purchasePrice: 10.102)
//
//     
//        self.calc.saveNewGroup("Financials", code: "MQG.ax,CBA.ax", description: "Finance Companies")
        
    }
    
//---------------------------------------------------
// intercept segue and pass in our instance of calc
//---------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! SettingsViewController
            controller.calc = self.calc
    }
    
    //-------------------------------------
    // function to blank the screen data
    //-------------------------------------
    func blankScreen() {
        
        self.stockName.text = "Fetching..."
        self.stockPrice.text = ""
        self.stockBought.text = ""
        self.stockVolume.text = ""
        self.stockPurchased.text = ""
        self.stockValue.text = ""
        self.stockDifference.text = ""
        self.pageTitle.hidden = true
        self.priceLabel.hidden = true
        self.boughtLabel.hidden = true
        self.volumeLabel.hidden = true
        self.changeLabel.hidden = true
        self.purchasedLabel.hidden = true
        self.valueLabel.hidden = true
        
    }
    
    //---------------------------------------------------------
    // Function to get the stock data and update the screen
    //---------------------------------------------------------
    
    func getData(ind: Int, code: String, name : String) {
        
        self.blankScreen()
        
        self.calc.getDataForShareOrPortfolio(ind) { (data) -> () in
            
            self.stockName.text         = name
            self.stockPrice.text        = data.stockPrice
            self.stockBought.text       = data.stockPaid
            self.stockVolume.text       = data.stockVolume
            self.stockPurchased.text    = data.stockPurchase
            self.stockValue.text        = data.stockValue
            self.stockDifference.text   = data.stockDiff
            
            self.pageTitle.hidden = false
            self.priceLabel.hidden = false
            self.boughtLabel.hidden = false
            self.volumeLabel.hidden = false
            self.changeLabel.hidden = false
            self.purchasedLabel.hidden = false
            self.valueLabel.hidden = false
            
            // charts
            
            self.drawBarChart(data.barChartTitles, values: data.barChartData)
            
        }
        
        // Historic Data - this is outside the return function above so should run in parallel
        self.calc.getDataForHistoric(ind, code: code) { (tableData) ->() in
            if (tableData.headings != nil) {
                self.drawLineChart(tableData.headings, values: tableData.data)
            }
        }
    }
    
    //--------------------------------------//
    // functions for the table at the side  //
    //--------------------------------------//
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.getData(indexPath.row, code: self.calc.getCode(indexPath.row), name: self.calc.getTitle(indexPath.row))
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.calc.getLength()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = self.calc.getCode(indexPath.row)
        cell.detailTextLabel?.text = self.calc.getTitle(indexPath.row)
        return cell
    }
    
    //------------------------------------------//
    // draw the chart                           //
    //------------------------------------------//
    func drawBarChart(dataPoints: [String], values: [Double]) {
        
        // set the parameters
        
        barChartView.noDataText = "No data available."
        barChartView.descriptionText = ""
        barChartView.backgroundColor = UIColor.blackColor()
        barChartView.leftAxis.startAtZeroEnabled = true
        barChartView.xAxis.labelPosition = .BottomInside
        barChartView.xAxis.labelTextColor = UIColor.blueColor()
        barChartView.xAxis.labelFont = UIFont.boldSystemFontOfSize(20)
        
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.drawAxisLineEnabled = false
        //        barChartView.leftAxis.drawAxisLineEnabled = false
        //        barChartView.leftAxis.drawGridLinesEnabled = false
        //        barChartView.rightAxis.drawAxisLineEnabled = false
        //        barChartView.rightAxis.drawGridLinesEnabled = false
        //        barChartView.rightAxis.drawTopYLabelEntryEnabled = false
        barChartView.rightAxis.enabled = false
        barChartView.leftAxis.enabled = false
        barChartView.drawMarkers = false
        barChartView.drawValueAboveBarEnabled = false
        barChartView.legend.enabled = false
        
        
        
        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .EaseInCubic)
        
        // create data
        
        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        // draw chart
        
        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "")
        let chartData = BarChartData(xVals: dataPoints, dataSet: chartDataSet)
        barChartView.data = chartData
        
        chartDataSet.colors = ChartColorTemplates.joyful()
        chartDataSet.valueFont = UIFont.boldSystemFontOfSize(20)
        chartDataSet.valueFormatter = NSNumberFormatter()
        chartDataSet.valueFormatter?.numberStyle = .CurrencyStyle
        chartDataSet.valueFormatter?.currencySymbol = "$"
        chartDataSet.valueFormatter?.maximumFractionDigits = 0
        
    }
    
    
    func drawLineChart(dataPoints: [String], values: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        lineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        
        //    var colors: [UIColor] = []
        
        //    for _ in 0..<dataPoints.count {
        //        let red = Double(arc4random_uniform(256))
        //        let green = Double(arc4random_uniform(256))
        //        let blue = Double(arc4random_uniform(256))
        
        //        let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
        //        colors.append(color)
        //    }
        
        
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "")
        let lineChartData = LineChartData(xVals: dataPoints, dataSet: lineChartDataSet)
        
        lineChartView.data = lineChartData
        
    }
    
    
    
    
}



