//
//  Copyright © 2019 Splendid Things. All rights reserved.
//

extension Activity where In == Void {
    func perform(_ completion: @escaping Completion) {
        perform(on: Void(), completion)
    }
}

extension Activity where Out == Void {
    func perform(on input: In, completion: @escaping ()->()) {
        perform(on: input) { _ in completion() }
    }
}

extension Activity where In == Void, Out == Void {
    func perform(_ completion: @escaping ()->()) {
        perform(on: Void()) { _ in completion() }
    }
}

