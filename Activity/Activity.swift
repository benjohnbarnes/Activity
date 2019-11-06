//
//  Copyright © 2019 Splendid Things. All rights reserved.
//

protocol Activity {
    associatedtype In
    associatedtype Out
    
    func perform(on input: In, _ completion: @escaping Completion)

    typealias Completion = (Out) -> Void
}
