//
//  PurchasedItem.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 04/11/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
class PurchasedItem {
    @Attribute(.unique) var id: String
    var itemName: String
    var isSelected: Bool = false
    var needsSync: Bool = false

    init(
        id: String,
        itemName: String,
        isSelected: Bool = false,
        needsSync: Bool = false
    ) {
        self.id = id
        self.itemName = itemName
        self.isSelected = isSelected
        self.needsSync = needsSync
    }

    convenience init(record: CKRecord) {
        self.init(
            id: record.recordID.recordName,
            itemName: record["itemName"] as? String ?? "",
            isSelected: record["isSelected"] as? Int == 1
        )
    }

    var shopItem: ShopItem? {
        ShopItem(rawValue: itemName)
    }
}
