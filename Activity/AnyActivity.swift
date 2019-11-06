//
//  Copyright © 2019 Splendid Things. All rights reserved.
//

import Foundation


extension Activity {
    var typeErased: AnyActivity<In, Out> {
        return AnyActivity(self)
    }
}

//MARK:-

struct AnyActivity<In, Out>: Activity {
    init<Underlying: Activity>(_ underlying: Underlying) where Underlying.In == In, Underlying.Out == Out {
        performImp = underlying.perform
    }
    
    internal init(_ performImp: @escaping PerformImp) {
        self.performImp = performImp
    }
    
    func perform(on input: In, _ completion: @escaping (Out) -> Void) {
        performImp(input, completion)
    }
    
    private let performImp: PerformImp
    typealias PerformImp = (In, @escaping Completion) -> Void
}

