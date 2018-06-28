//
//  Utils.swift
//  WeatherOverground
//
//  Created by Jim Martin on 6/25/18.
//  Copyright © 2018 Avi Cieplinski. All rights reserved.
//

import Foundation


// MARK: - threading

//add code block to background thread, usage:
// BG {
//    code
// }
public func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}
//add code block to main thread, usage:
// UI {
//    code
// }
public func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}
