//
//  PhotosProviderAssetsGroup.swift
//  PhotosProvider
//
//  Created by Muukii on 8/7/15.
//  Copyright © 2015 muukii. All rights reserved.
//

import Foundation
import Photos
import CoreLocation

#if !PHOTOSPROVIDER_EXCLUDE_IMPORT_MODULES
    import GCDKit
#endif

public protocol PhotosProviderAssetsGroup {
    
    func requestAssetsGroupByDays(result: ((assetsGroupByDay: PhotosProviderAssetsGroupByDay) -> Void)?)
    func enumerateAssetsUsingBlock(block: ((asset: PhotosProviderAsset) -> Void)?)
    
    var count: Int { get }
    
    subscript (index: Int) -> PhotosProviderAsset? { get }
    var first: PhotosProviderAsset? { get }
    var last: PhotosProviderAsset? { get }
}

public class CustomAssetsGroup: PhotosProviderAssetsGroup {
    
    public private(set) var assets : [PhotosProviderAsset] = []
    
    public init(assets: [PhotosProviderAsset]) {
        
        self.assets = assets
    }
    
    public func requestAssetsGroupByDays(result: ((assetsGroupByDay: PhotosProviderAssetsGroupByDay) -> Void)?) {
        
        GCDBlock.async(.Default) {
            
            let dividedAssets = divideByDay(dateSortedAssets: self)
            
            GCDBlock.async(.Main) {
                result?(assetsGroupByDay: dividedAssets)
            }
        }
    }
    
    public func enumerateAssetsUsingBlock(block: ((asset: PhotosProviderAsset) -> Void)?) {
        
        let sortedAssets = self.assets.sort({ $0.creationDate?.compare($1.creationDate ?? NSDate()) == NSComparisonResult.OrderedDescending })
        for asset in sortedAssets {
            
            block?(asset: asset)
        }
    }
    
    public var count: Int {
        
        return self.assets.count
    }
    
    public subscript (index: Int) -> PhotosProviderAsset? {
        
        return self.assets[index]
    }
    
    public var first: PhotosProviderAsset? {
        
        return self.assets.first
    }
    
    public var last: PhotosProviderAsset? {
        
        return self.assets.last
    }
}

extension PHFetchResult: PhotosProviderAssetsGroup {
    
    public func requestAssetsGroupByDays(result: ((assetsGroupByDay: PhotosProviderAssetsGroupByDay) -> Void)?) {
        
        assert(self.count == 0 || self.firstObject is PHAsset, "AssetsGroup must be PHFetchResult of PHAsset.")
        
        GCDBlock.async(.Default) {
            
            let dividedAssets = divideByDay(dateSortedAssets: self)
            
            GCDBlock.async(.Main) {
                result?(assetsGroupByDay: dividedAssets)
            }
        }
    }
    
    public func enumerateAssetsUsingBlock(block: ((asset: PhotosProviderAsset) -> Void)?) {
        
        assert(self.count == 0 || self.firstObject is PHAsset, "AssetsGroup must be PHFetchResult of PHAsset.")
        
        self.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            
            if let asset = asset as? PHAsset {
                
                block?(asset: asset)
            }
        }
    }
        
    public subscript (index: Int) -> PhotosProviderAsset? {
        
        assert(self.count == 0 || self.firstObject is PHAsset, "AssetsGroup must be PHFetchResult of PHAsset.")
        
        return self.objectAtIndex(index) as? PHAsset
    }
    
    
    public var first: PhotosProviderAsset? {
        
        return self.firstObject as? PhotosProviderAsset
    }
    
    public var last: PhotosProviderAsset? {
        
        return self.lastObject as? PhotosProviderAsset
    }
}

private func divideByDay(dateSortedAssets dateSortedAssets: PhotosProviderAssetsGroup) -> PhotosProviderAssetsGroupByDay {
    
    let dayAssets = PhotosProviderAssetsGroupByDay()
    
    var tmpDayAsset: PhotosProviderAssetsGroupByDay.DayAssets!
    
    dateSortedAssets.enumerateAssetsUsingBlock { (asset) -> Void in
        
        guard let processingDate = dateWithoutTime(asset.creationDate) else {
            
            return
        }
        
        if tmpDayAsset != nil && processingDate.isEqualToDate(tmpDayAsset!.day) == false {
            
            tmpDayAsset = nil
        }
        
        if tmpDayAsset == nil {
            
            tmpDayAsset = PhotosProviderAssetsGroupByDay.DayAssets(day: processingDate)
            dayAssets.dayAssets.append(tmpDayAsset!)
        }
        
        tmpDayAsset.assets.append(asset)
    }
    
    return dayAssets
}

private func dateWithoutTime(date: NSDate?) -> NSDate? {
    
    guard let date = date else {
        
        return nil
    }
    
    let calendar: NSCalendar = NSCalendar.currentCalendar()
    let units: NSCalendarUnit = [.Year, .Month, .Day]
    let comp: NSDateComponents = calendar.components(units, fromDate: date)
    return calendar.dateFromComponents(comp)
}
