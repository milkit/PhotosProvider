//
//  PhotosProviderAsset.swift
//  PhotosProvider
//
//  Created by Muukii on 8/7/15.
//  Copyright © 2015 muukii. All rights reserved.
//

import Foundation
import Photos
import CoreLocation

public func == (lhs: PhotosProviderAsset, rhs: PhotosProviderAsset) -> Bool {
    
    return lhs.localIdentifier == rhs.localIdentifier
}

public protocol PhotosProviderAsset: class {
    
    var localIdentifier: String { get }
    
    var assetMediaType: AssetMediaType { get }
    var pixelWidth: Int { get }
    var pixelHeight: Int { get }
    
    var creationDate: Date? { get }
    var modificationDate: Date? { get }
    
    var location: CLLocation? { get }
    var duration: TimeInterval { get }
    
    var hidden: Bool { get }
    var favoriteAsset: Bool { get }
    
    var originalImageDownloadProgress: Progress? { get }
    
    func requestImage(
        targetSize: CGSize,
        progress: (Progress?) -> Void,
        option: PhotosProviderAssetOption?,
        completion: @escaping (PhotosProviderAsset, PhotosProviderAssetResult) -> Void)
    
    func requestOriginalImage(
        progress: @escaping (Progress?) -> Void,
        option: PhotosProviderAssetOption?,
        completion: @escaping (PhotosProviderAsset, PhotosProviderAssetResult) -> Void)
    
    func cancelRequestImage()
    func cancelRequestOriginalImage()
}

public enum AssetMediaType: Int {
    
    case unknown
    case image
    case video
    case audio
}

extension PHAsset: PhotosProviderAsset {
    
    public var favoriteAsset: Bool {
        
        return isFavorite
    }
    
    public var assetMediaType: AssetMediaType {
        
        return AssetMediaType(rawValue: mediaType.rawValue)!
    }
    
    public func requestImage(
        targetSize: CGSize,
        progress: (Progress?) -> Void,
        option: PhotosProviderAssetOption?,
        completion: @escaping (PhotosProviderAsset, PhotosProviderAssetResult) -> Void) {
        
        let contentMode: PHImageContentMode = option?.contentMode ?? .aspectFill
        
        imageRequestID = PHImageManager.default().requestImage(
            for: self,
            targetSize: targetSize,
            contentMode: contentMode,
            options: option?.imageRequestOptions) { [unowned self] image, info in
                
                guard let image = image else {
                    
                    DispatchQueue.main.async {
                        completion(self, .failure(PhotosProviderAssetResultErrorType.unknown))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(self, .success(image))
                }
        }
    }
    
    public func requestOriginalImage(
        progress: @escaping (Progress?) -> Void,
        option: PhotosProviderAssetOption?,
        completion: @escaping (PhotosProviderAsset, PhotosProviderAssetResult) -> Void) {
        
        let imageRequestOptions: PHImageRequestOptions = option?.imageRequestOptions ?? PHImageRequestOptions()
        
        if imageRequestOptions.progressHandler == nil {
            
            imageRequestOptions.progressHandler = { [unowned self] _progress, error, stop, info in
                
                DispatchQueue.main.async {
                    if self.originalImageDownloadProgress == nil {
                        self.originalImageDownloadProgress = Progress(totalUnitCount: 10000)
                        progress(self.originalImageDownloadProgress)
                    }
                    
                    self.originalImageDownloadProgress?.completedUnitCount = Int64(_progress * Double(10000))
                    
                    if _progress == 1.0 {
                        self.originalImageDownloadProgress = nil
                    }
                }
            }
        }
        
        let contentMode: PHImageContentMode = option?.contentMode ?? .aspectFill
        
        originalImageRequestID = PHImageManager.default().requestImage(
            for: self,
            targetSize: CGSize(width: pixelWidth, height: pixelHeight),
            contentMode: contentMode,
            options: imageRequestOptions) { [unowned self] (image, info) -> Void in
                
                guard let image = image else {
                    DispatchQueue.main.async {
                        completion(self, .failure(PhotosProviderAssetResultErrorType.unknown))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(self, .success(image))
                }
        }
    }
    
    public dynamic var originalImageDownloadProgress: Progress? {
        
        get {
            
            let value = objc_getAssociatedObject(self, &StoredProperties.originalImageDownloadProgress) as? Progress
            return value
        }
        set {
            
            objc_setAssociatedObject(
                self,
                &StoredProperties.originalImageDownloadProgress,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func cancelRequestImage() {
        
        guard let imageRequestID = imageRequestID else {
            return
        }
        PHImageManager.default().cancelImageRequest(imageRequestID)
    }
    
    public func cancelRequestOriginalImage() {
        
        guard let originalImageRequestID = originalImageRequestID else {
            return
        }
        PHImageManager.default().cancelImageRequest(originalImageRequestID)
        originalImageDownloadProgress?.cancel()
    }
    
    private var imageRequestID: PHImageRequestID? {
    
        get {
            
            let value = (objc_getAssociatedObject(self, &StoredProperties.imageRequestID) as? NSNumber)?.int32Value
            return value
        }
        set {
            
            guard let newValue = newValue else {
                return
            }
            objc_setAssociatedObject(
                self,
                &StoredProperties.imageRequestID,
                NSNumber(value: newValue as Int32),
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
        }
    }
    
    private var originalImageRequestID: PHImageRequestID? {
    
        get {
            
            let value = (objc_getAssociatedObject(self, &StoredProperties.originalImageRequestID) as? NSNumber)?.int32Value
            return value
        }
        set {
            
            guard let newValue = newValue else {
                return
            }
            objc_setAssociatedObject(
                self,
                &StoredProperties.originalImageRequestID,
                NSNumber(value: newValue),
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
        }
    }
    
    private struct StoredProperties {
        
        static var originalImageDownloadProgress: Void?
        static var imageRequestID: Void?
        static var originalImageRequestID: Void?
    }
}
