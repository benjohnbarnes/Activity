//
//  Copyright © 2019 Splendid Things. All rights reserved.
//

/*
 No more than a proof of concept.
 */

import Dispatch

extension Activity where In: Hashable {

    var cached: AnyActivity<In, Out> {
        return Cache(underlying: self).typeErased
    }
}

//MARK:-

private final class Cache<Underlying: Activity>: Activity where Underlying.In: Hashable {

    init(underlying: Underlying) {
        self.underlying = underlying
    }
    
    func perform(on input: Underlying.In, _ completion: @escaping Underlying.Completion) {
        cacheProcessQueue.async {
            self.record(for: input).sendTo(completion)
        }
    }
    
    private func record(for input: In) -> Record {
        if let record = records[input] {
            return record
        }
        
        let record = Record()
        
        // The queue used for work should be that prefered by the underlying activity?
        self.underlying.perform(on: input, record.fulfil)
        
        records[input] = record
        return record
    }
    
    let underlying: Underlying
    private var records: [In: Record] = [:]

    private class Record {
        
        init() {
            working.enter()
        }
        
        func fulfil(_ result: Out) {
            guard self.result == nil else { fatalError() }
            self.result = result
            working.leave()
        }
        
        func sendTo(_ completion: @escaping Completion) {
            working.notify(queue: .global()) { completion(self.result) }
        }
        
        let working: DispatchGroup = DispatchGroup()
        var result: Out! = nil
    }
}

private let cacheProcessQueue = DispatchQueue(label: "cache worker queue")
