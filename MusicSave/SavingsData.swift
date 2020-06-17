//
//  SavingsData.swift
//  MusicSave
//
//  Created by Nathan O'Sullivan on 5/05/2016.
//  Copyright © 2016 Nathan O'Sullivan. All rights reserved.
//

import UIKit
import CoreData


class SavingsData: NSObject {
    
//    func encode(with coder: NSCoder) {
//        // do nothing
//    }
    
    
    var dollarsPerHour:Double?
    var numberOfHours:Double?
    var amountSaved:Double
    var totalSaved:Double
    var dateOfUpdate:Date
    var instrument:String
    
    init(withNumberOfHours: Double, andDollarsPerHours:Double, andAmountSaved:Double, andTotalSaved:Double, withInstrument:String, onDate:Date)
    {
        self.dollarsPerHour = andDollarsPerHours;
        self.numberOfHours = withNumberOfHours;
        self.amountSaved = andAmountSaved;
        self.totalSaved = andTotalSaved;
        self.instrument = withInstrument;
        self.dateOfUpdate = onDate;
    }
    
    init(withNumberOfHours: Double, andDollarsPerHours:Double, andCurrentSavings:[SavingsData], onDate:Date)
    {
        self.dollarsPerHour = andDollarsPerHours;
        self.numberOfHours = withNumberOfHours;
        self.amountSaved = self.dollarsPerHour! * self.numberOfHours!
        if andCurrentSavings.count > 0
        {
            self.totalSaved = andCurrentSavings.last!.totalSaved + self.dollarsPerHour! * self.numberOfHours!
        }
        else
        {
            self.totalSaved = self.amountSaved
        }
        
        self.dateOfUpdate = onDate;
        self.instrument = "Guitar"
    }
    
    init(withResetOnDate:Date)
    {
        self.totalSaved = 0.0
        self.amountSaved = 0.0
        self.dateOfUpdate = withResetOnDate
        self.instrument = "RESET VALUES"
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
            savingsDescription = savingsDescription + "Total saved: $\(String(describing: amountSaved)) as at \(dateOfUpdate.description)"
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
    
    static func TotalAmountSaved(savings:[SavingsData]) -> Double
    {
        var totalAmountSaved = 0.0
        
        if !savings.isEmpty
        {
            totalAmountSaved = savings.last!.totalSaved
        }
        
        return totalAmountSaved
    }
    
    static func OutputCSV(savings:[SavingsData]) -> String
    {
        var csv : String = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YYYY HH:mm:ss"
        
        // create CSV file in memory
        csv = "\"DateTime\",\"Instrument\",\"NumberOfHours\",\"DollarsPerHour\",\"AmountSaved\",\"TotalSaved\"\n"
        
        if savings.count != 0
        {
            for row in savings
            {
                let dateString = dateFormatter.string(from: row.dateOfUpdate)
                csv = csv + "\"\(dateString)\","
                
                csv = csv + "\"\(row.instrument)\","

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
                
                csv = csv + "\(String(describing: row.amountSaved)),"
                
                csv = csv + "\(String(describing: row.totalSaved))\n"
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
    
    private class func getFileURL(fileName: String) -> URL
    {
        //let FILE_NAME = "SavingsDataArray"
        let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent(fileName)

        return archiveURL
    }

}
