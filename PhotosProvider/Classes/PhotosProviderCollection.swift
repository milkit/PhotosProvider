//
//  Collection.swift
//  PhotosProvider
//
//  Created by Muukii on 8/7/15.
//  Copyright © 2015 muukii. All rights reserved.
//

import Foundation
import Photos

#if !PHOTOSPROVIDER_EXCLUDE_IMPORT_MODULES
    import GCDKit
#endif

public func == (lhs: PhotosProviderCollection, rhs: PhotosProviderCollection) -> Bool {
    
    return lhs === rhs
}

public class PhotosProviderCollection: Hashable {
    
    public private(set) var title: String
    
    public init(title: String, group: PhotosProviderAssetsGroup, configuration: PhotosProviderConfiguration, buildGroupByDay: Bool = false) {
        
        self.title = title
        self.configuration = configuration
        self.group = group

        if buildGroupByDay {
            group.requestAssetsGroupByDays { groupByDay in
                self.groupByDay = groupByDay
            }
        }
    }
    
    public init(title: String, sourceCollection: PHAssetCollection, configuration: PhotosProviderConfiguration, buildGroupByDay: Bool = false) {
        
        self.title = title
        self.configuration = configuration
        self.sourceCollection = sourceCollection
    }
    
    public func cancelRequestGroup() {
        
        self.currentReuqestGroupOperation?.cancel()
    }
        
    public func requestGroup(refetch refetch: Bool = false, completion: (group: PhotosProviderAssetsGroup) -> Void) {
        
        if let group = self.group where refetch == false {
            
            completion(group: group)
            return
        }
        
        guard let collection = self.sourceCollection else {
            
            if let group = self.group {
                
                completion(group: group)
            }
            else {
                
                assert(false, "group or sourceCollection must exist")
            }
            return
        }
        
        let operation = NSBlockOperation {
            
            let fetchOptions = self.configuration.fetchPhotosOptions()
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false),
            ]
            let _assets = PHAsset.fetchAssetsInAssetCollection(collection, options: fetchOptions)
            self.group = _assets
            
            GCDBlock.async(.Main) {
                completion(group: _assets)
            }
        }
        
        self.currentReuqestGroupOperation = operation
        PhotosProviderCollection.operationQueue.addOperation(operation)
    }
    
    public func requestGroupByDay(refetch refetch: Bool = false, completion: (groupByDay: PhotosProviderAssetsGroupByDay) -> Void) {
     
        if let groupByDay = self.groupByDay where refetch == false {
            completion(groupByDay: groupByDay)
            return
        }
        
        self.requestGroup(refetch: refetch) { [weak self] group in
            group.requestAssetsGroupByDays { _groupByDay in
                
                self?.groupByDay = _groupByDay
                completion(groupByDay: _groupByDay)
            }
        }
    }
    
    private var groupByDay: PhotosProviderAssetsGroupByDay?
    private var group: PhotosProviderAssetsGroup?
    private var sourceCollection: PHAssetCollection?
    private var configuration: PhotosProviderConfiguration
    
    public var hashValue: Int {
        
        return ObjectIdentifier(self).hashValue
    }
    
    private var currentReuqestGroupOperation: NSOperation?
    
    private static let operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 10
        return queue
    }()
}
