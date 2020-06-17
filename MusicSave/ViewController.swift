//
//  ViewController.swift
//  MusicSave
//
//  Created by Nathan O'Sullivan on 22/02/2016.
//  Copyright © 2016 Nathan O'Sullivan. All rights reserved.
//
//  Done:
//      1. Implement Persistence. Done using archiver objects - see p459 of iOS5 book. Flexible and easier than CoreData for my data.
//      2. Practice (hrs and mins) since last clear (date)
//      4. set up SavingsData class
//      3. Log file capturing date, delta change and running total
//      5. Work out a better way of saving data on exit - ie using AppDelegate - because I can't get [savings] into app delegate function - THIS IS NOT WORKING
//      6. Swap to CoreData (or whatever the latest thing is)
//
//  To do:

//      7. Add another screen for adding data
//      8. Include instrument type options
//      9. Historical displays of usage - bar chart
//      10. 
//
//  Tidy up: constraints

import UIKit
import CoreData
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var labelAmountSaved: UILabel!
    @IBOutlet weak var labelHistory: UILabel!
    
    // MARK: Constants
    let dollarsPerHour:Double = 5.0
    
    // MARK: Variables
    var lastReset = Date()
    var totalPractice = 0.0
    var totalAmountSaved = 0.0 as NSNumber
    
    var savings: [SavingsData] = []
    
    var history: [NSManagedObject] = []

    // MARK: Functions
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //MARK: DEBUG
        let deleteAll = false
        
        if (deleteAll) {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SavingsModel.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
            
            
        }
        
        // load data - if file doesn't exist create clear record
        savings = loadData()
        if savings.count == 0 {
            savings.append(SavingsData(withResetOnDate: Date()))
            try? saveData(newData: savings[0])
        }
        
        NSLog("Existing record count: \(savings.count)")
        
        // update displays
        updateDisplay()
    }

    func updateDisplay() {
        
        lastReset = SavingsData.WhenWasLastReset(savings: savings)
        totalPractice = SavingsData.TotalPracticeTimeSinceReset(savings: savings)
        
        let historyText = "Since \(dateString(date: lastReset)),\nYou have practiced for\n\(daysHoursMinutes(inputHours: totalPractice))"
        labelHistory.text = historyText
        
        totalAmountSaved = SavingsData.TotalAmountSaved(savings: savings) as NSNumber
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        //formatter.numberStyle = .CurrencyStyle
        labelAmountSaved.text = formatter.string(from: totalAmountSaved)!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Actions
    @IBAction func addPracticeTime(sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "More Practice!", message: "Add hours of practice", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default,
            handler: { (action:UIAlertAction) -> Void in
                let textToNumber = NumberFormatter()
                let hoursAsNSNumber = textToNumber.number(from: alert.textFields!.first!.text!)
                if hoursAsNSNumber != nil
                {
                    let hours = hoursAsNSNumber!.doubleValue
                    
                    let newSavingAmount = SavingsData(withNumberOfHours: hours, andDollarsPerHours: self.dollarsPerHour, andCurrentSavings: self.savings, onDate: Date())
                    self.savings.append(newSavingAmount)
                    NSLog(self.savings.last!.description)
                    
                    self.updateDisplay()
                    
                    // save data
                    try? self.saveData(newData: newSavingAmount)
                }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action: UIAlertAction) -> Void in }
        
      
        alert.addTextField { (textField:UITextField ) -> Void in
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func clearAmountSaved(sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Clear total?", message: "Are you sure you want to clear the total saved?",
                                      preferredStyle: .actionSheet)
        
        let imsureAction = UIAlertAction(title: "I\'m Sure", style: .destructive,
            handler: { (action:UIAlertAction) -> Void in
        
                //savingsamount class test
                let newReset = SavingsData(withResetOnDate: Date())
                self.savings.append(newReset)
                NSLog(self.savings.last!.description)
                
                self.updateDisplay()
                
                // save data
                do {
                    try self.saveData(newData: newReset)
                }
                catch {
                    debugPrint(error)
                }
                
                
            })
        
        let ohnoAction = UIAlertAction(title: "Oh no! Cancel", style: .cancel, handler: {(action:UIAlertAction) -> Void in })
        
        alert.addAction(imsureAction)
        alert.addAction(ohnoAction)
        
        present(alert, animated: true, completion: nil)
        
    }

    @IBAction func exportAction(sender: UIButton)
    {
        var csv:String
        
        csv = SavingsData.OutputCSV(savings: self.savings)
        
        guard let csvFile = csv.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }
        
        let emailViewController = configuredMailComposeViewController(data: csvFile as Data)
        if MFMailComposeViewController.canSendMail()
        {
            self.present(emailViewController, animated: true, completion: nil)
        }
        
        NSLog("\(csv)")
        
    }
    
    // MARK: CoreData functions
    func saveData(newData: SavingsData) throws {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        //context.automaticallyMergesChangesFromParent = true
        
        let newSaving = SavingsModel(entity: SavingsModel.entity(), insertInto: context)
        newSaving.amountSaved = newData.amountSaved as NSNumber
        newSaving.dateOfUpdate = newData.dateOfUpdate
        newSaving.dollarsPerHour = newData.dollarsPerHour as NSNumber?
        newSaving.instrument = newData.instrument
        newSaving.numberOfHours = newData.numberOfHours as NSNumber?
        newSaving.totalSaved = newData.totalSaved as NSNumber
        
        try context.save()
        
        NSLog("New record saved!")
    }
    
    func loadData() -> [SavingsData] {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        //let fetchRequest: NSFetchRequest<SavingsData> = NSManagedObject.fetchRequest()
        
        let fetchRequest: NSFetchRequest<SavingsModel> = SavingsModel.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        var savings: [SavingsData] = []
        do {
            let results = try context.fetch(fetchRequest) as [SavingsModel]

            NSLog("Number of saved records: \(results.count)")
            //return results as! [SavingsData]
            
            for r in results {
                let dph = r.dollarsPerHour ?? 0.0
                let noh = r.numberOfHours ?? 0.0
                let amsv = r.amountSaved ?? 0.0
                let dou = r.dateOfUpdate ?? Date()
                let inst = r.instrument ?? "Guitar"
                let totsv = r.totalSaved ?? 0.0
                
                savings.append(SavingsData(withNumberOfHours: Double(truncating: noh), andDollarsPerHours: Double(truncating: dph), andAmountSaved: Double(truncating: amsv), andTotalSaved: Double(truncating: totsv), withInstrument: inst, onDate: dou))
            }
        }
        catch {
            debugPrint(error)
        }
        return savings
    }
    
    
    // MARK: helper functions
    func daysHoursMinutes(inputHours:Double) -> String {
        // returns string value showing days, hours and minutes of practice
        
        let inputMinutes = NSNumber(value: inputHours * 60).intValue
        let days:Int = inputMinutes / (24*60)
        let hours:Int = (inputMinutes - days*24*60) / 60
        let minutes:Int = inputMinutes - days*24*60 - hours*60
        
        let outputString = String(format: "\(days) days, \(hours) hours and \(minutes) minutes")
        
        return outputString
    }
    
    func dateString(date:Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full;
        
        return dateFormatter.string(from: date)
    }
    
    func initDateFromDateString(dateString:String="01-02-2016") ->Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        return dateFormatter.date(from: dateString)!
    }
    
    // MARK: Mail a file
    func configuredMailComposeViewController(data:Data) -> MFMailComposeViewController
    {
        let emailController = MFMailComposeViewController()
        emailController.mailComposeDelegate = self
        emailController.setSubject("Export CSV File")
        emailController.setMessageBody("", isHTML: false)
        
        // Attaching the .CSV file to the email.
        emailController.addAttachmentData(data, mimeType: "text/csv", fileName: "Export.csv")
        
        return emailController
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    private func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismiss(animated: true, completion: nil)
    }

}

