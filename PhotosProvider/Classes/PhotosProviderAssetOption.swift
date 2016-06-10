//
//  PhotosProviderAssetOption.swift
//  PhotosProvider
//
//  Created by Muukii on 9/3/15.
//  Copyright © 2015 muukii. All rights reserved.
//

import Foundation
import Photos

public protocol PhotosProviderAssetOption {
    
    var imageRequestOptions: PHImageRequestOptions { get set }
    var contentMode: PHImageContentMode? { get set }
}
