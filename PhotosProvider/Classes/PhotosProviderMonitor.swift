//
//  Monitor.swift
//  PhotosProvider
//
//  Created by Muukii on 8/7/15.
//  Copyright © 2015 muukii. All rights reserved.
//

import Foundation
import Photos

class PhotosProviderMonitor {
    
    var photosDidChange: ((PHChange) -> Void)?
    
    private(set) var isObserving: Bool = false
    
    func startObserving() {
        
        isObserving = true
        PHPhotoLibrary.shared().register(photosLibraryObserver)
    }
    
    func endObserving() {
        
        isObserving = false
        PHPhotoLibrary.shared().unregisterChangeObserver(photosLibraryObserver)
    }
    
    private lazy var photosLibraryObserver: PhotosLibraryObserver = { [weak self] in
        let observer = PhotosLibraryObserver()
        observer.didChange = { [weak self] change in
            
            self?.photosDidChange?(change)
        }
        return observer
    }()
}

fileprivate class PhotosLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
    
    var didChange: ((PHChange) -> Void)?
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        didChange?(changeInstance)
    }
}
