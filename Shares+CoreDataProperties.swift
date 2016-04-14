//
//  Shares+CoreDataProperties.swift
//  
//
//  Created by fullname on 14/04/2016.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Shares {

    @NSManaged var code: String?
    @NSManaged var volume: NSNumber?
    @NSManaged var purchasePrice: NSNumber?
    @NSManaged var name: String?

}
