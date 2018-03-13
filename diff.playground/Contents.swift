//: Playground - noun: a place where people can play

import UIKit

struct Diff {
    let added: [Int]
    let removed: [Int]
    let moved: [(Int, Int)]
    let changed: [Int]
}

func diff<T>(old: [T], new: [T], sameItemFunc: @escaping (T, T)->Bool, equalItemFunc: @escaping (T, T)->Bool ) -> Diff {
    
    
    func find(_ item: T, in list: [T]) -> (same: [Int], equal: [Int]) {
        var sameItemIndex: [Int] = []
        var equalItemIndex: [Int] = []
        list.enumerated().forEach { offset, other in
            if sameItemFunc(item, other) {
                sameItemIndex.append(offset)
            }
            if equalItemFunc(item, other) {
                equalItemIndex.append(offset)
            }
        }
        return (same: sameItemIndex, equal: equalItemIndex)
    }
    
    var updated: [Int] = []
    
    let oldMap = old.enumerated().map { oldOffset, oldItem in
        // does new contain the same item
        
        var (same, equal) = find(oldItem, in: new)
        
        if same.count > 0 {
            // if any are the same object
            updated.append( same.removeFirst() )
            if same.count > 0 {
                // if there are more, then they were added
                
            }
        }
    }
}
//
//
//
//struct DiffItem<T: Equatable>: Equatable {
//    let offset: Int
//    let element: T
//
//    static func == (left: DiffItem, right: DiffItem) -> Bool {
//        return left.element == right.element && left.offset == right.offset
//    }
//}
//
//func diff<T: Equatable>(_ list1: [T], _ list2: [T]) -> (added: [Int], removed: [Int]) {
//
//    let list1 = list1.enumerated().map{DiffItem.init(offset: $0, element: $1)}
//    let list2 = list2.enumerated().map{DiffItem.init(offset: $0, element: $1)}
//
//    func indexesOfItems(presentIn list1: [DiffItem<T>], butNotIn list2: [DiffItem<T>]) -> [DiffItem<T>] {
//        return list1.filter { !list2.contains($0) }
//    }
//
//    let added = indexesOfItems(presentIn: list2, butNotIn: list1)
//    let removed = indexesOfItems(presentIn: list1, butNotIn: list2)
//
//    return (added: added.map{$0.offset}, removed: removed.map{$0.offset})
//}
//
//
//let a = [1,2,3,4]
//let b = [0,1]
//let (added, removed) = diff(a,b)
//(added, removed)
//added == [2]
//removed == [0]

