//
//  ViewController.swift
//  Swift-HAR
//
//  Created by Nond on 3/25/17.
//  Copyright © 2017 BDAC. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation

let manager = CMMotionManager()

class ViewController: UIViewController {
    
    // MARK: Var outlets
    
    @IBOutlet weak var accelXText: UITextField!
    @IBOutlet weak var accelYText: UITextField!
    @IBOutlet weak var accelZText: UITextField!
    @IBOutlet weak var gyroXText: UITextField!
    @IBOutlet weak var gyroYText: UITextField!
    @IBOutlet weak var gyroZText: UITextField!
    @IBOutlet weak var currentAppStatus: UITextView!
    @IBOutlet weak var actionText: UITextField!
    
    // MARK: Buttons
    @IBAction func recDataButtonPressed(_ sender: Any) {
        print("Record Button Clicked!")
        actionType = actionText.text!
        delay(2){
            AudioServicesPlaySystemSound(self.systemSoundID)
            self.startLiveUpdates()
            self.startLoggingData()
        }
        
        delay(15){
            AudioServicesPlaySystemSound(self.systemSoundID)
            self.exportToText(currMatrix: self.dataMatrix, action: self.actionType)
            self.actionsLog = self.checkOutput(currentActions: self.actionsLog, newAction: self.actionType)
            let ind = self.actionsLog.firstIndex(of: self.actionType)
            print(ind!)
            if ind! == 0 || ind! == (self.actionsLog.count - 1) {
                //This is the first misc action
                self.miscActMatrix.append(self.dataMatrix)
            } else {
                self.miscActMatrix[ind!] = self.dataMatrix
            }
        }
        
    }
    
    @IBAction func saveBPressed(_ sender: Any) {
        self.exportToText(currMatrix: self.dataMatrix, action: self.actionType)
        
    }

    /* Deleted live accel and gyro update buttons
    @IBAction func startLiveRecBPressed(_ sender: Any) {
        print("Start Live Update Button Clicked!")
        self.startLiveUpdates()
    }
    @IBAction func stopLiveRecBPressed(_ sender: Any) {
        print("Stop Live Update Button Clicked!")
        self.stopUpdates()
    }
    */
    
    @IBAction func recSavStandBPressed(_ sender: Any) {
        actionType = "standing"
        self.startLoggingData()
        delay(14){
            self.exportToText(currMatrix: self.dataMatrix, action: self.actionType)
            self.standTrainMatrix = self.bootStrapDataM(arr2D: self.dataMatrix, setsNum: self.bootTrainDataNum, startPt: 0, stride: self.bootStepSize, windowSize: self.ptsPerData, rowNums: self.rowNum, xyz: 1)
            self.standTestMatrix = self.bootStrapDataM(arr2D: self.dataMatrix, setsNum: self.bootTestDataNum, startPt: self.testStartPt, stride: self.bootStepSize, windowSize: self.ptsPerData, rowNums: self.rowNum, xyz: 1)
            self.exportToText(currMatrix: self.standTrainMatrix, action: "standing-train")
            self.exportToText(currMatrix: self.standTestMatrix, action: "standing-test")
        }
    }
    
    @IBAction func recSaveWalkBPressed(_ sender: Any) {
        actionType = "walking"
        self.startLoggingData()
        delay(14){
            self.exportToText(currMatrix: self.dataMatrix, action: self.actionType)
            self.walkTrainMatrix = self.bootStrapDataM(arr2D: self.dataMatrix, setsNum: self.bootTrainDataNum, startPt: 0, stride: self.bootStepSize, windowSize: self.ptsPerData, rowNums: self.rowNum, xyz: 1)
            self.walkTestMatrix = self.bootStrapDataM(arr2D: self.dataMatrix, setsNum: self.bootTestDataNum, startPt: self.testStartPt, stride: self.bootStepSize, windowSize: self.ptsPerData, rowNums: self.rowNum, xyz: 1)
            self.exportToText(currMatrix: self.walkTrainMatrix, action: "walking-train")
            self.exportToText(currMatrix: self.walkTestMatrix, action: "walking-test")
        }
    }
    
    @IBAction func trainNNBPressed(_ sender: Any) {
        
        
        self.nnInit(inputNums: self.nnInputNum, hiddenNums: self.hiddenLayerNum, actLog: self.actionsLog)
        
        // Comment this out if training for only standing and walking
        self.trainNNMisc(nnet: nn, structure: structure, dataSet: miscActMatrix, actLog: actionsLog, errorThreshold: errorThreshold, nnInputNum: self.nnInputNum, bootTrainDataNum: self.bootTrainDataNum, bootTestDataNum: self.bootTestDataNum, testStartPt: self.testStartPt, bootStepSize: self.bootStepSize, ptsPerData: self.ptsPerData, rowNum: self.rowNum)
        
        //Uncomment this if only training for standing and walking
        /*
        self.trainNN(nnet: nn, structure: structure, wTrainMatrix: walkTrainMatrix, wTestMatrix: walkTestMatrix, sTrainMatrix: standTrainMatrix, sTestMatrix: standTestMatrix)
        */
    }
    
    @IBAction func guessActBPressed(_ sender: Any) {
        actionType = "Guess"
        delay(2){
            AudioServicesPlaySystemSound(self.systemSoundID)
            self.startLoggingData()
        }
        delay(15){
            AudioServicesPlaySystemSound(self.systemSoundID)
            self.exportToText(currMatrix: self.dataMatrix, action: self.actionType)
            
            //self.guessMatrix = self.bootStrapDataM(arr2D: self.dataMatrix, setsNum: self.bootTestDataNum, startPt: self.testStartPt, stride: self.bootStepSize, windowSize: self.ptsPerData, rowNums: self.rowNum, xyz: 1)
            
            self.guessMatrix = self.triAxisBootWrapper(arr2D: self.dataMatrix, setsNum: self.bootTestDataNum, startPt: self.testStartPt, stride: self.bootStepSize, windowSize: self.ptsPerData, rowNums: self.rowNum)
            
            //Take 1 sample from the guessMatrix
            
            let guessSample = self.guessMatrix[2]
            do{
                let inference = try self.nn.infer(guessSample)
                print(inference)
                var roundedInfer = [String]()
                for inf in inference {
                    roundedInfer.append(String(format: "%.3f", inf))
                }
                /*
                let rounded0 = String(format: "%.3f", inference[0])
                let rounded1 = String(format: "%.3f", inference[1])
                let roundedInfer = "[\(rounded0), \(rounded1)]"
                */
                // Stand = [1, 0]
                // Walk = [0, 1]
                var action = ""
                let maxInference = inference.max()!
                let predictedAction = self.actionsLog[inference.firstIndex(of: maxInference)!]
                action = "NeuralNet predicts: \(predictedAction)\n\(roundedInfer)"
                
                /*
                if inference[0] > inference [1]{
                    action = "NeuralNet predicts: Standing\n\(roundedInfer)"
                } else if inference [0] < inference [1] {
                    action = "NeuralNet predicts: Walking\n\(roundedInfer)"
                } else {
                    action = "NeuralNet's confused\n\(roundedInfer)"
                }
                */
                
                self.currentAppStatus.text = action
            } catch {print(error)}
        }

    }
    
    @IBAction func resetMem(_ sender: Any) {
        self.dataMatrix = Array(repeating: Array(repeating:0.0, count: 4), count: rowNum)
        self.miscActMatrix.removeAll()
        self.miscActTrain.removeAll()
        self.miscActTest.removeAll()
        self.actionsLog.removeAll()
        self.currentAppStatus.text = "Memory cleared"
    }
    
    // MARK: Main constants and vars
    let updateInterval = 0.01
    let dataLogTime = 10.0 //seconds
    let systemSoundID: SystemSoundID = 1052
    let errorThreshold: Float = 0.05
    var rowNum:Int = 0
    var timer = Timer()
    var counter = 0
    var i = 0
    var dataInd: Float = 0.0
    var ax: Float = 0.0
    var ay:Float = 0.0
    var az:Float = 0.0
    var actionType = "unDefData"
    var nnInputNum: Int = 0
    var hiddenLayerNum: Int = 0
    
    //Vars below must satisfy this equation
    //ptsPerData = rowNum/(bootTrainDataNum + bootTestDataNum + bootStepSize)
    var bootTrainDataNum = 70
    var bootTestDataNum = 20
    var bootStepSize = 10
    var ptsPerData = 100
    var testStartPt = 0 //placeholder. Calculated once view init.
    
    //Number of possible actions the app will recognize
    var numOfActions = 2
    
    //Variables for the NeuralNet
    var structure: NeuralNet.Structure!
    var config: NeuralNet.Configuration!
    var nn: NeuralNet!
    
    //Create an FFNN instance
    //let network = FFNN(inputs: 100, hidden: 64, outputs: 2, learningRate: 0.7, momentum: 0.4, weights: nil, activationFunction: .Sigmoid, errorFunction: .crossEntropy(average: false))
    
    //Create instance of NN class
    
    
    //Create an empty array to store the data
    // Try just looking at the z acceleration for now to test FFNN
    var dataMatrix = [[Float]]()
    var standTrainMatrix = [[Float]]()
    var walkTrainMatrix = [[Float]]()
    var standTestMatrix = [[Float]]()
    var walkTestMatrix = [[Float]]()
    var trainAnswers = [[Float]]()
    var testAnswers = [[Float]]()
    var guessMatrix = [[Float]]()
    var miscActMatrix = [[[Float]]]()
    var miscActTrain = [[Float]]()
    var miscActTest = [[Float]]()
    var actionsLog = [String]()
    
    // MARK: init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        accelXText.delegate = self
        accelYText.delegate = self
        accelZText.delegate = self
        actionText.delegate = self
        definesPresentationContext = true
        
        //default values on init
        accelXText.text = "Accel-X: 0.0"
        accelYText.text = "Accel-Y: 0.0"
        accelZText.text = "Accel-Z: 0.0"
        gyroXText.text = "Gyro-X: 0.0"
        gyroYText.text = "Gyro-Y: 0.0"
        gyroZText.text = "Gyro-Z: 0.0"
        rowNum = Int(dataLogTime/updateInterval)
        testStartPt = bootTrainDataNum * bootStepSize
        nnInputNum = ptsPerData * 3 //100 pts per data * 3 axis
        hiddenLayerNum = Int(round(Double(nnInputNum) * (2.0/3.0)))
        //Initialize a preliminary untrained neural network for binary classification
        do {
            structure = try NeuralNet.Structure(inputs: nnInputNum, hidden: hiddenLayerNum, outputs: 2)
            config = try NeuralNet.Configuration(hiddenActivation: .rectifiedLinear, outputActivation: .sigmoid, cost: .meanSquared, learningRate: 0.4, momentum: 0.2)
            nn = try NeuralNet(structure: structure, config: config)
        }
        catch {
            print(error)
        }
        
        //Preallocate matrices for storing data
        dataMatrix = Array(repeating: Array(repeating:0.0, count: 4), count: rowNum)
        standTrainMatrix = Array(repeating: Array(repeating: 0.0, count: nnInputNum), count: bootTrainDataNum)
        walkTrainMatrix = Array(repeating: Array(repeating: 0.0, count: nnInputNum), count: bootTrainDataNum)
        standTestMatrix = Array(repeating: Array(repeating: 0.0, count: nnInputNum), count: bootTestDataNum)
        walkTestMatrix = Array(repeating: Array(repeating: 0.0, count: nnInputNum), count: bootTestDataNum)
        trainAnswers = Array(repeating: Array(repeating: 0.0, count: numOfActions), count: bootTrainDataNum)
        testAnswers = Array(repeating: Array(repeating: 0.0, count: numOfActions), count: bootTestDataNum)
        guessMatrix = Array(repeating: Array(repeating: 0.0, count: nnInputNum), count: bootTestDataNum)
        
        if manager.isGyroAvailable && manager.isAccelerometerAvailable && manager.isDeviceMotionAvailable {
            //Set sensor data updates to the updateInterval
            manager.accelerometerUpdateInterval = updateInterval
            manager.gyroUpdateInterval = updateInterval

        }
    }
    // TODO: Turn all this mess under here into classes instead of func
    
    // MARK: Live update data functions
    func outputAccData(acceleration: CMAcceleration){
        accelXText.text = "Accel-X: " + "\(acceleration.x).2fg"
        accelYText.text = "Accel-Y: " + "\(acceleration.y).2fg"
        accelZText.text = "Accel-Z: " + "\(acceleration.z).2fg"
        // NSLog("%f, %f, %f", acceleration.x, acceleration.y, acceleration.z)
    }
    
    func outputGyroData(rotation: CMRotationRate){
        gyroXText.text = "Gyro-X: " + "\(rotation.x).2fg"
        gyroYText.text = "Gyro-Y: " + "\(rotation.y).2fg"
        gyroZText.text = "Gyro-Z: " + "\(rotation.z).2fg"
    }
    
    func startLiveUpdates(){
//        manager.startAccelerometerUpdates(to: .main) {
//            [weak self] (data: CMAccelerometerData?, error: Error?) in
//            if (data?.acceleration) != nil {
//                self?.outputAccData(acceleration: (data?.acceleration)!)
//            }
//        }
        manager.startGyroUpdates(to: .main) {
            [weak self] (data: CMGyroData?, error: Error?) in
            if (data?.rotationRate) != nil {
                self?.outputGyroData(rotation: (data?.rotationRate)!)
            }
        }
    }
    
    // MARK: Data logging
    func startLoggingData(){
        print("Start logging data")
        currentAppStatus.text = "Data Logging Started"
        //start accelerometer data and loop through the dataMatrix to store data
        manager.startAccelerometerUpdates(to: .main) {
            [weak self] (data: CMAccelerometerData?, error: Error?) in
            if (data?.acceleration) != nil {
                self?.ax = Float((data?.acceleration.x)!)
                self?.ay = Float((data?.acceleration.y)!)
                self?.az = Float((data?.acceleration.z)!)
                self?.outputAccData(acceleration: (data?.acceleration)!)
            }
        }
        delay(0.5){
            self.timer = Timer.scheduledTimer(timeInterval: self.updateInterval, target:self, selector: #selector(self.recordToDataMatrix), userInfo: nil, repeats: true)
        }
    }

    @objc func recordToDataMatrix(){
        if i == rowNum{
            self.timer.invalidate()
            print("Finished logging data")
            //print(dataMatrix) //for testing only
            currentAppStatus.text = "Data Logging Complete"
            i = 0
            dataInd = 0.0
            stopUpdates()
        }
        else {
            dataMatrix[i][0] = dataInd
            dataMatrix[i][1] = ax
            dataMatrix[i][2] = ay
            dataMatrix[i][3] = az
            i += 1
            dataInd += Float(self.updateInterval)
        }
    }
    
    func stopUpdates(){
        manager.stopAccelerometerUpdates()
        manager.stopGyroUpdates()
        self.timer.invalidate()
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()){
        //function from stack overflow. Delay in seconds
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
        
    }
    
    // MARK: Data bootstrapper
    //      Create the test and training sets
    
    func bootStrapDataM(arr2D: [[Float]], setsNum: Int, startPt: Int, stride: Int, windowSize: Int, rowNums: Int, xyz: Int) -> [[Float]]{
        //xyz = 1 -> x data, xyz = 2 -> y data, xyz = 3 -> z data
        let accel1DOnly = get1DArray(arr2D: arr2D, rowNums: rowNums, xyz: xyz)
        let accel1Min = accel1DOnly.min()!
        let accel1Max = accel1DOnly.max()!
        
        var shiftBy: Float = 0
        if accel1Max >= Float(0) && accel1Min >= Float(0){
            shiftBy = accel1Min * (-1)
        } else if accel1Max >= Float(0) && accel1Min <= Float(0){
            shiftBy = accel1Min * (-1)
        } else {
            shiftBy = accel1Max * (-1)
        }
        
        /*
        var halfRange:Float = 0
        if accel1Max >= Float(0) && accel1Min >= Float(0){
            halfRange = (accel1Max - accel1Min)/2
        } else if accel1Max >= Float(0) && accel1Min <= Float(0){
            halfRange = (accel1Max + (-1 * accel1Min))/2
        } else {
            halfRange = ((accel1Min * -1) - (accel1Max * -1))/2 + (accel1Max * -1) //adding max again to make all data >= 0
        }
        */
        //var processedArr = accel1DOnly.map{$0 + halfRange}
        var processedArr = accel1DOnly.map{$0 + shiftBy}
        var returnArray: [[Float]] = Array(repeating: Array(repeating: 0.0, count: windowSize), count: setsNum)
        var pointer1 = startPt
        var pointer2 = pointer1 + windowSize
        for k in 0..<setsNum {
            returnArray[k]=Array(processedArr[pointer1..<pointer2])
            pointer1 += stride
            pointer2 = pointer1 + windowSize
        }
        
        return returnArray
    }
    
    func get1DArray(arr2D: [[Float]], rowNums: Int, xyz: Int) -> [Float]{
        var accel1D: [Float] = Array(repeating: 0.0, count: rowNums)
        var j: Int = 0
        //flatten accel in z to a 1D array
        for row in arr2D {
            accel1D[j] = row[xyz] //1 is x axis, 2 is y axis, 3 is z axis
            j += 1
        }
        return accel1D
    }
    
    // Three axis wrapper for the data bootstrapper
    //      Joins the bootstrapped data from each array into log segments
    //      The segements are x, y, z in that order.
    
    func triAxisBootWrapper(arr2D: [[Float]], setsNum: Int, startPt: Int, stride: Int, windowSize: Int, rowNums: Int) -> [[Float]] {
        var xArr: [[Float]] = Array(repeating: Array(repeating: 0.0, count: windowSize), count: setsNum)
        var yArr: [[Float]] = Array(repeating: Array(repeating: 0.0, count: windowSize), count: setsNum)
        var zArr: [[Float]] = Array(repeating: Array(repeating: 0.0, count: windowSize), count: setsNum)
        var returnArray: [[Float]] = Array(repeating: Array(repeating: 0.0, count: windowSize * 3), count: setsNum)
        
        xArr = self.bootStrapDataM(arr2D: arr2D, setsNum: setsNum, startPt: startPt, stride: stride, windowSize: windowSize, rowNums: rowNums, xyz: 1)
        yArr = self.bootStrapDataM(arr2D: arr2D, setsNum: setsNum, startPt: startPt, stride: stride, windowSize: windowSize, rowNums: rowNums, xyz: 2)
        zArr = self.bootStrapDataM(arr2D: arr2D, setsNum: setsNum, startPt: startPt, stride: stride, windowSize: windowSize, rowNums: rowNums, xyz: 3)
        
        for i in 0..<setsNum {
            returnArray[i] = xArr[i] + yArr[i] + zArr[i]
        }
        
        return returnArray
    }
    
    // MARK: NeuralNetwork Config
    //      Initialize a specific untrained NeuralNet
    //      that can handle more than 2 classifications.
    func nnInit(inputNums: Int, hiddenNums: Int, actLog: [String]) {
        do {
            let outputNums = actLog.count
            print(inputNums)
            print(hiddenNums)
            print(outputNums)
            structure = try NeuralNet.Structure(inputs: inputNums, hidden: hiddenNums, outputs: outputNums)
            config = try NeuralNet.Configuration(hiddenActivation: .rectifiedLinear, outputActivation: .sigmoid, cost: .meanSquared, learningRate: 0.4, momentum: 0.2)
            nn = try NeuralNet(structure: structure, config: config)
        }
        catch {
            print(error)
        }
    }
    
    //Checks the log of actions and appends the log if it's a new action
    func checkOutput(currentActions: [String], newAction: String) -> [String] {
        var currentActions = currentActions
        if currentActions.contains(newAction) {
            //do nothing, action already there
        } else {
            currentActions.append(newAction)
        }
        return currentActions
    }
    
    // MARK: NeuralNetwork Training
    //      Can only be called after the walking and standing test
    //      and train matrices have been created
    
    func trainNN(nnet: NeuralNet, structure: NeuralNet.Structure, wTrainMatrix: [[Float]], wTestMatrix: [[Float]], sTrainMatrix: [[Float]], sTestMatrix: [[Float]]){
        
        //Create the output train and test answers
        let sTrainAns: [[Float]] = Array(repeating: [1,0], count: bootTrainDataNum)
        let sTestAns: [[Float]] = Array(repeating: [1,0], count: bootTestDataNum)
        let wTrainAns: [[Float]] = Array(repeating: [0,1], count: bootTrainDataNum)
        let wTestAns: [[Float]] = Array(repeating: [0,1], count: bootTestDataNum)
        
        //Answer and data matrices have to be in the same order
        
        let allTrainAns = sTrainAns + wTrainAns
        let allTestAns = sTestAns + wTestAns
        
        let allTrainData = sTrainMatrix + wTrainMatrix
        let allTestData = sTestMatrix + wTestMatrix
        
        // Create the neural net dataset object
        do {
            let nnDataSet = try NeuralNet.Dataset(
                trainInputs: allTrainData,
                trainLabels: allTrainAns,
                validationInputs: allTestData,
                validationLabels: allTestAns,
                structure: structure)
            try nnet.train(nnDataSet, errorThreshold: 0.004, maxEpochs: 30)
            //print(nnet.allWeights())
            currentAppStatus.text = "Training Complete"
        } catch {print(error)}
        
    }
    
    //  train Neural Network for the misc action dataset
    func trainNNMisc(nnet: NeuralNet, structure: NeuralNet.Structure, dataSet: [[[Float]]], actLog: [String], errorThreshold: Float, nnInputNum: Int, bootTrainDataNum: Int, bootTestDataNum: Int, testStartPt: Int, bootStepSize: Int, ptsPerData: Int, rowNum: Int){
        
        self.currentAppStatus.text = "Training NeuralNet"
        
        print(actLog)
        
        //Create the output train and test answers
        var tmpTrainAns = [[Float]]()
        var tmpTestAns = [[Float]]()
        let actNum = actLog.count
        var tmpAns: [Float] = Array(repeating: 0.0, count: actNum)
        for action in actLog {
            let ind = actLog.firstIndex(of: action)!
            tmpAns = Array(repeating: 0.0, count: actNum)
            tmpAns[ind] = 1.0
            for _ in 0..<bootTrainDataNum {
                tmpTrainAns.append(tmpAns)
            }
            for _ in 0..<bootTestDataNum {
                tmpTestAns.append(tmpAns)
            }
            
        }
        
        //Create train and test datasets
        var mTrain = [[Float]]()
        var mTest = [[Float]]()
        for action in actLog {
            let ind = actLog.firstIndex(of: action)!
            mTrain += (self.triAxisBootWrapper(arr2D: dataSet[ind], setsNum: bootTrainDataNum, startPt: 0, stride: bootStepSize, windowSize: ptsPerData, rowNums: rowNum))
            mTest += (self.triAxisBootWrapper(arr2D: dataSet[ind], setsNum: bootTestDataNum, startPt: testStartPt, stride: bootStepSize, windowSize: ptsPerData, rowNums: rowNum))
        }
        
        self.exportToText(currMatrix: mTrain, action: "Training-FullSet")
        self.exportToText(currMatrix: mTest, action: "Testing-FullSet")
        
        do {
            let nnDataSet = try NeuralNet.Dataset(
                trainInputs: mTrain,
                trainLabels: tmpTrainAns,
                validationInputs: mTest,
                validationLabels: tmpTestAns,
                structure: structure)
            try nnet.train(nnDataSet, errorThreshold: errorThreshold, maxEpochs: 30)
            //print(nnet.allWeights())
            self.currentAppStatus.text = "Training Complete"
        } catch {print(error)}
        
    }
    
    // MARK: NeuralNetwork Inference
    //      This is the action "guessing" portion.
    
    // MARK: Data exporting
    func exportToText(currMatrix: [[Float]], action: String){
        print("Exporting")
        currentAppStatus.text = "Exporting..."
        /*
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("dataFile.txt")
        (dataMatrix[0] as NSArray).write(to: fileURL, atomically: true)
        */
        
        //this is the file. we will write to.
        //let file = "dataLog.txt"
        
        let file = makeFileName(action)
        
        let exportText = flattenDataMatrix(currMatrix)
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let path = dir.appendingPathComponent(file)
            
            //writing
            do {
                try exportText.write(to: path, atomically: true, encoding: String.Encoding.utf8)
                print("Export Successful!")
                currentAppStatus.text = "Export Complete!"
            }
            catch {print(error)} //and then QQ in the fetal position
            /*
            do {
                let text2 = try String(contentsOf: path, encoding: String.Encoding.utf8)
                print("\(text2)")
            }
            catch {/* error handling here */}
            */
        }
    }
    
    func flattenDataMatrix(_ arr2D: [[Float]]) -> String {
        var returnString = "time,accelx,accely,accelz"
        for row in arr2D {
            let stringArray: [String] = row.compactMap{String($0)}
            let string = stringArray.joined(separator: ",")
            returnString.append("\n"+string)
        }
        
        return returnString
    }
    
    func makeFileName(_ state: String) -> String {
        return state + "_" + fileTagger() + ".csv"
    }
    
    func fileTagger() -> String {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from:date)
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        return "\(year)\(month)\(day)-\(hour)\(minutes)\(seconds)"
    }
    
    // TODO: Write function for clearing doc directory
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
