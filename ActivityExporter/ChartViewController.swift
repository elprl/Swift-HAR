//
//  ChartViewController.swift
//  ActivityExporter
//
//  Created by Paul Leo on 06/06/2019.
//  Copyright © 2019 BDAC. All rights reserved.
//

import Foundation
import Firebase
import Charts
import SwiftCSV

class ChartViewController: UIViewController {
    @IBOutlet weak var chartView: LineChartView!
    var filePath: URL?
    var xVals: [Double] = []
    var accelX: [ChartDataEntry] = []
    var accelY: [ChartDataEntry] = []
    var accelZ: [ChartDataEntry] = []
    var gyroX: [ChartDataEntry] = []
    var gyroY: [ChartDataEntry] = []
    var gyroZ: [ChartDataEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customizeLineAndBarChart()
        
        if let filePath = filePath {
            let csv = try! CSV(url: filePath)
            csv.enumerateAsArray { array in
                guard let time = Double(array.first!) else {
                    return
                }
                self.xVals.append(time)
                if let accelX = Double(array[1]) {
                    let dataEntry = ChartDataEntry(x: time, y: accelX)
                    self.accelX.append(dataEntry)
                }
                if let accelY = Double(array[2]) {
                    let dataEntry = ChartDataEntry(x: time, y: accelY)
                    self.accelY.append(dataEntry)
                }
                if let accelZ = Double(array[3]) {
                    let dataEntry = ChartDataEntry(x: time, y: accelZ)
                    self.accelZ.append(dataEntry)
                }
                if let gyroX = Double(array[4]) {
                    let dataEntry = ChartDataEntry(x: time, y: gyroX)
                    self.gyroX.append(dataEntry)
                }
                if let gyroY = Double(array[5]) {
                    let dataEntry = ChartDataEntry(x: time, y: gyroY)
                    self.gyroY.append(dataEntry)
                }
                if let gyroZ = Double(array[6]) {
                    let dataEntry = ChartDataEntry(x: time, y: gyroZ)
                    self.gyroZ.append(dataEntry)
                }
            }
            
            let chartDataSetax = LineChartDataSet(entries: accelX, label: "accelX")
            let chartDataSetay = LineChartDataSet(entries: accelY, label: "accelY")
            let chartDataSetaz = LineChartDataSet(entries: accelZ, label: "accelZ")
            
            let chartDataSetgx = LineChartDataSet(entries: gyroX, label: "gyroX")
            let chartDataSetgy = LineChartDataSet(entries: gyroY, label: "gyroY")
            let chartDataSetgz = LineChartDataSet(entries: gyroZ, label: "gyroZ")
            
            chartDataSetax.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
            chartDataSetay.colors = [UIColor(red: 210/255, green: 126/255, blue: 34/255, alpha: 1)]
            chartDataSetaz.colors = [UIColor(red: 190/255, green: 126/255, blue: 34/255, alpha: 1)]
            
            chartDataSetgx.colors = [UIColor(red: 230/255, green: 126/255, blue: 1/255, alpha: 1)]
            chartDataSetgy.colors = [UIColor(red: 230/255, green: 106/255, blue: 1/255, alpha: 1)]
            chartDataSetgz.colors = [UIColor(red: 230/255, green: 96/255, blue: 1/255, alpha: 1)]
            
            chartDataSetax.mode = .cubicBezier
            chartDataSetay.mode = .cubicBezier
            chartDataSetaz.mode = .cubicBezier

            chartDataSetgx.mode = .cubicBezier
            chartDataSetgy.mode = .cubicBezier
            chartDataSetgz.mode = .cubicBezier

            chartDataSetax.circleRadius = 0.5
            chartDataSetay.circleRadius = 0.5
            chartDataSetaz.circleRadius = 0.5

            chartDataSetgx.circleRadius = 0.5
            chartDataSetgy.circleRadius = 0.5
            chartDataSetgz.circleRadius = 0.5
            
            chartDataSetax.lineWidth = 1
            chartDataSetay.lineWidth = 1
            chartDataSetaz.lineWidth = 1

            chartDataSetgx.lineWidth = 1
            chartDataSetgy.lineWidth = 1
            chartDataSetgz.lineWidth = 1

            let chartData = LineChartData()
            
            chartData.addDataSet(chartDataSetax) //,
            chartData.addDataSet(chartDataSetay)
            chartData.addDataSet(chartDataSetaz)
            chartData.addDataSet(chartDataSetgx)
            chartData.addDataSet(chartDataSetgy)
            chartData.addDataSet(chartDataSetgz)
            chartView.data = chartData
            chartView.pinchZoomEnabled = true
            chartView.scaleYEnabled = false
        }
    }
    
    @IBAction func doneBtnTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToHome", sender: self)
    }
    
    func customizeLineAndBarChart() {
        self.chartView.noDataText = "You need to provide data for the chart."
//        self.chartView.chartDescription?.text = "Acceleration & Gyro"
//        self.chartView.chartDescription?.textColor = UIColor.black
        self.chartView.gridBackgroundColor = UIColor.darkGray
//        self.chartView.xAxis.labelPosition = .
        self.chartView.rightAxis.enabled = false
        self.chartView.delegate = self
    }
}

extension ChartViewController: ChartViewDelegate {
    
}
