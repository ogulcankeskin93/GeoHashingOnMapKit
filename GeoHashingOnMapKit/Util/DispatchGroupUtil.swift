//
//  DispatchGroupUtil.swift
//
//  Created by Oğulcan Keskin on 16.11.2018.
//

import Foundation


class DispatchGroupUtil {
    
    // birden fazla sorgu veya beklenmesi gereken async islemler sonucunda bir islem yapmak istiyorsak, bu utili kullaniyoruz.
    
    private static var dispatchDict: [String:DispatchGroup] = [:]
    class func setup(dispatchKey: String, _ count: Int, onNotify: @escaping () -> ()) {
        let dispatchGroup = DispatchGroup()
        
        for _ in 0..<count {
            dispatchGroup.enter()
        }
        
        dispatchDict[dispatchKey] = dispatchGroup
        
        
        dispatchGroup.notify(queue: .main) {  // nerede olursa olsun, enter sayisi kadar islem leave olduktan sonra bu methoda giriyor.
            onNotify()
            dispatchDict.removeValue(forKey: dispatchKey)
        }
    }
    
    class func leave(dispatchKey: String) {
        guard let dispatchGroup = dispatchDict[dispatchKey] else {return}
        dispatchGroup.leave()
    }
    
}
