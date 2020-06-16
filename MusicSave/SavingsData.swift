//
//  SavingsData.swift
//  MusicSave
//
//  Created by Nathan O'Sullivan on 5/05/2016.
//  Copyright © 2016 Nathan O'Sullivan. All rights reserved.
//

import UIKit

class SavingsData: NSObject, NSCoding {
    
    func encode(with coder: NSCoder) {
        // do nothing
    }
    
    
    var dollarsPerHour:Double?
    var numberOfHours:Double?
    var amountSaved:Double
    var dateOfUpdate:Date
    
    init(dollarsPerHour: Double?, numbersOfHours: Double?, amountSaved: Double, dateOfUpdate: Date)
    {
        self.dollarsPerHour = dollarsPerHour
        self.numberOfHours = numbersOfHours
        self.amountSaved = amountSaved
        self.dateOfUpdate = dateOfUpdate
    }
    
    init(withNumberOfHours: Double, andDollarsPerHours:Double, andCurrentSavings:[SavingsData], onDate:Date)
    {
        dollarsPerHour = andDollarsPerHours;
        numberOfHours = withNumberOfHours;
        if andCurrentSavings.count > 0
        {
            amountSaved = andCurrentSavings.last!.amountSaved + dollarsPerHour! * numberOfHours!
        }
        else
        {
            amountSaved = dollarsPerHour! * numberOfHours!
        }
        
        dateOfUpdate = onDate;
    }
    
    init(withResetOnDate:Date)
    {
        amountSaved = 0
        dateOfUpdate = withResetOnDate
    }
    
    override var description: String
    {
        var savingsDescription:String
        
        if (numberOfHours == nil)
        {
            //CHECK//savingsDescription = "Savings value reset on \(dateOfUpdate.description(NSLocale.current))"
            savingsDescription = "Savings value reset on \(dateOfUpdate.description)"
        }
        else
        {
            savingsDescription = "You played for \(numberOfHours!) hours, at $\(dollarsPerHour!) per hour\n"
            //CHECK//savingsDescription = savingsDescription + "Total saved: $\(amountSaved) as at \(dateOfUpdate.description(NSLocale.current))"
            savingsDescription = savingsDescription + "Total saved: $\(amountSaved) as at \(dateOfUpdate.description)"
        }
        
        return savingsDescription
    }
    
    static func WhenWasLastReset(savings:[SavingsData]) -> Date
    {
        var lastReset = Date()
        var found = false
        
        for item in savings.reversed()
        {
            if (item.numberOfHours == nil) && (!found)
            {
                lastReset = item.dateOfUpdate
                found = true
            }
        }
        return lastReset
    }
    
    static func TotalPracticeTimeSinceReset(savings:[SavingsData]) -> Double
    {
        var totalTime = 0.0
        var lastSavingEntry:SavingsData
        var tempSavingsData = savings
        
        while !tempSavingsData.isEmpty
        {
            lastSavingEntry = tempSavingsData.popLast()!
            
            if lastSavingEntry.numberOfHours == nil
            {
                tempSavingsData = []
            }
            else
            {
                totalTime += lastSavingEntry.numberOfHours!
            }
        }

    return totalTime
    }
    
    static func AmountSaved(savings:[SavingsData]) -> Double
    {
        var amountSaved = 0.0
        
        if !savings.isEmpty
        {
            amountSaved = savings.last!.amountSaved
        }
        
        return amountSaved
    }
    
    static func OutputCSV(savings:[SavingsData]) -> String
    {
        var csv : String = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YYYY HH:mm:ss"
        
        // create CSV file in memory
        csv = "\"DateTime\",\"NumberOfHours\",\"DollarsPerHour\",\"TotalSaved\"\n"
        
        if savings.count != 0
        {
            for row in savings
            {
                let dateString = dateFormatter.string(from: row.dateOfUpdate)
                csv = csv + "\"\(dateString)\","

                if let tempVal = row.numberOfHours
                {
                    csv = csv + "\(tempVal),"
                }
                else
                {
                    csv = csv + "0.0,"
                }
                
                if let tempVal = row.dollarsPerHour
                {
                    csv = csv + "\(tempVal),"
                }
                else
                {
                    csv = csv + "0.0,"
                }
                
                csv = csv + "\(row.amountSaved)\n"
            }
        }
        
        // Write to file
        do
        {
            try csv.write(to: getFileURL(fileName: "Export.csv"), atomically: true, encoding: String.Encoding.utf8)
            NSLog("Export.csv saved")
            
        }
        catch
        {
            NSLog("Failed to save - Export.csv")
        }
        
        return csv
    }
    
    // MARK: - Conform to NSCoding
    func encodeWithCoder(aCoder: NSCoder)
    {
        print("encodeWithCoder")
        aCoder.encode(dollarsPerHour, forKey: "dollarsPerHour")
        aCoder.encode(numberOfHours, forKey: "numberOfHours")
        aCoder.encode(amountSaved, forKey: "amountSaved")
        aCoder.encode(dateOfUpdate, forKey: "dateOfUpdate")
    }
    
    // since we inherit from NSObject, we're not a final class -> therefore this initializer must be declared as 'required'
    // it also must be declared as a 'convenience' initializer, because we still have a designated initializer as well
    required convenience init?(coder aDecoder: NSCoder)
    {
        print("decodeWithCoder")
        guard let unarchivedDPH = aDecoder.decodeObject(forKey: "dollarsPerHour") as? Double?
            else {
                return nil
        }
        guard let unarchivedNOH = aDecoder.decodeObject(forKey: "numberOfHours") as? Double?
            else {
                return nil
        }
        guard let unarchivedAS = aDecoder.decodeObject(forKey: "amountSaved") as? Double
            else {
                return nil
        }
        guard let unarchivedDOU = aDecoder.decodeObject(forKey: "dateOfUpdate") as? Date
            else {
                return nil
        }
        
        NSLog("\(String(describing: unarchivedDPH)) and \(String(describing: unarchivedNOH)) and \(unarchivedAS) and \(unarchivedDOU)")
        // now (we must) call the designated initializer
        self.init(dollarsPerHour: unarchivedDPH, numbersOfHours: unarchivedNOH, amountSaved: unarchivedAS, dateOfUpdate: unarchivedDOU)
    }

    private class func getFileURL(fileName: String) -> URL
    {
        //let FILE_NAME = "SavingsDataArray"
        let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent(fileName)
        
        return archiveURL
    }
    
    class func saveData(savings: [SavingsData])
    {
        // takes savings array and writes it to file
        
        let success = NSKeyedArchiver.archiveRootObject(savings, toFile: SavingsData.getFileURL(fileName: "SavingsDataArray").path)
        if success
        {
            NSLog("You did it! File saved")
        }
        else
        {
            NSLog("Boo! File failed to save")
        }
    }
    
    class func loadData() -> [SavingsData]?
    {
        return NSKeyedUnarchiver.unarchiveObject(withFile: SavingsData.getFileURL(fileName: "SavingsDataArray").path) as? [SavingsData]
    }


}
