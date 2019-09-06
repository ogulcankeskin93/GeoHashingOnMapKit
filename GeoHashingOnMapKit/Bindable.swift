
import Foundation

class Bindable<T> {
    
    typealias CallBack = (T) -> ()
    
    var callback: CallBack?
    var callbackforWillSet: CallBack?
    
    var value: T {
        didSet {
            callback?(value)
            callbackforWillSet?(oldValue)
        }
    }
    
    init(_ v: T) {
        value = v
    }
    
    func bind(_ callback: CallBack?) {
        self.callback = callback
    }
    
    func bindAndFire(_ callback: CallBack?) {
        self.callback = callback
        callback?(value)
    }
    
    func fire() {
        callback?(value)
    }
    
    func bindWillSet(_ callbackforWillSet: CallBack?) {
        self.callbackforWillSet = callbackforWillSet
    }
}
