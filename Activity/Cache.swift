//
//  Copyright © 2019 Splendid Things. All rights reserved.
//

/*
 A proof of concept.
 */

import Dispatch

extension Activity where In: Hashable {

    var memoized: AnyActivity<In, Out> {
        return Memoize(underlying: self).typeErased
    }
}

//MARK:-

private final class Memoize<Underlying: Activity>: Activity where Underlying.In: Hashable {

    typealias In = Underlying.In
    typealias Out = Underlying.Out
    
    init(underlying: Underlying) {
        self.underlying = underlying
    }
    
    func perform(on input: In, _ completion: @escaping Completion) {
        serialRecordLookupQueue.async {
            self.record(for: input).sendTo(completion)
        }
    }
    
    private func record(for input: In) -> Record {
        // If a record already exists then use that record. It may not have been fulfiled yet, but
        // in that case it is already being evaluated.
        //
        if let record = records[input] {
            return record
        }

        // No record exists for this input. I should create one, remember it, and evaluate the output.
        //
        let record = Record()
        records[input] = record

        // I don't want to allow the work to occur on my serial record look up queue so I will dispatch
        // to `fulfilmentQueue`.
        //
        // This sucks because, underlying may then immediately dispatch that to some other queue that it
        // prefers. It'd be nice to avoid this. I think this is related to the handling of queues
        // generally.
        //
        fulfilmentQueue.async {
            self.underlying.perform(on: input, record.fulfil)
        }
        
        return record
    }
    
    let underlying: Underlying
    private var records: [In: Record] = [:]

    // This is basically a promise / future.
    private class Record {
        
        init() {
            fulfilling.enter()
        }
        
        func fulfil(_ result: Out) {
            if let result = self.result { fatalError("Already fulfilled with \(result)") }

            // Ordering here must be assign _before_ leaving `fulfilling`.
            //
            self.result = result
            fulfilling.leave()
        }
        
        func sendTo(_ completion: @escaping Completion) {
            fulfilling.notify(queue: .global()) { completion(self.result) }
        }
        
        private let fulfilling: DispatchGroup = DispatchGroup()
        private var result: Out! = nil
    }
}

private let serialRecordLookupQueue = DispatchQueue(label: "Memoize serial record lookup queue")
private let fulfilmentQueue = DispatchQueue.global()
