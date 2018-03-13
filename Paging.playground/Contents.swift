//: Playground - noun: a place where people can play

import UIKit


class Paging<PageDataType> {
    typealias PageIndex = Int
    typealias PageRange = Range<PageIndex>
    
    var pageData = [PageDataType]()
    var pageRanges = [PageIndex: PageRange]()
    
    func load(page pageIndex: PageIndex) {
        request(page: pageIndex) { range, data in
            pageRanges[pageIndex] = range
            pageData.append(contentsOf: data)
        }
    }
    
    func request(page: PageIndex, complete: (PageRange, [PageDataType])->()) {
        
    }
}

class SomePage: Paging<Int> {
    override func request(page: PageIndex, complete: (PageRange, [Int]) -> ()) {
        complete(PageRange(uncheckedBounds: (lower: 0, upper: 4)), [1,2,3,4,5])
        
    }
}

