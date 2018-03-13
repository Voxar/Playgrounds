//: Playground - noun: a place where people can play

import UIKit

protocol ConditionType {
    var isTrue: Bool { get }
}

extension ConditionType: Equatable {
    
}

protocol EquatableConditionType: Equatable, ConditionType {
    
}

struct EqualCondition<T: Equatable>: ConditionType {
    let left, right: T
    
    var isTrue: Bool {
        return left == right
    }
}

struct EquatableCondition<T: Equatable>: ConditionType {
    let left, right: T
    var isTrue: Bool {
        return left == right
    }
}

struct EqualValuePredicateCondition<T: Equatable>: ConditionType {
    let left, right: ValuePredicate<T>
    var isTrue: Bool {
        return left.b() == right.b()
    }
}


indirect enum Condition: ConditionType {
    case equal(ConditionType, ConditionType)
    case and(ConditionType, ConditionType)
    case or(ConditionType, ConditionType)
    case not(ConditionType)
    
    var isTrue: Bool {
        switch self {
        case .equal(let left, let right):
            return left.isTrue == right.isTrue
        case .and(let left, let right):
            return left.isTrue && right.isTrue
        case .or(let left, let right):
            return left.isTrue || right.isTrue
        case .not(let c):
            return !c.isTrue
        }
        
    }
}


func && ( left: ConditionType, right: ConditionType ) -> ConditionType {
    print("kjk")
    return Condition.and(left, right)
}

func || ( left: ConditionType, right: ConditionType ) -> ConditionType {
    print("kjk")
    return Condition.or(left, right)
}

prefix
func ! ( c: ConditionType ) -> ConditionType {
    print("kjk")
    return Condition.not(c)
}
//
//func ==<T: Equatable> (left: T?, right: T?) -> ConditionType {
//    return EquatableCondition(left: left, right: right)
//}

func ==<T: Equatable> (left: ValuePredicate<T>, right: ValuePredicate<T>) -> ConditionType {
    print("OKK")
    return EqualValuePredicateCondition<T>(left: left, right: right)
}



struct ValuePredicate<T>: ConditionType {
    let b: ()->T?
    init(_ b: @escaping ()->T?) {
        self.b = b
    }
    var isTrue: Bool {
        return b() != nil
    }
}

let label1 = UILabel()
let label2 = UILabel()

var isItDoneYet = false

func valueOf<T>(_ b: @autoclosure @escaping ()->T?) -> ValuePredicate<T> {
    return ValuePredicate(b)
}

func when<T>(_ b: @autoclosure @escaping ()->T?) -> ValuePredicate<T> {
    print(b())
    return ValuePredicate(b)
}

func when(_ x: ConditionType ) -> ConditionType {
    return x
}

extension UIUserInterfaceIdiom: ConditionType {
    var isTrue: Bool {
        return UIDevice.current.userInterfaceIdiom == self
    }
}

when( UIUserInterfaceIdiom.phone || UIUserInterfaceIdiom.pad && valueOf("hello") == "hello" ).isTrue

var a = [1,2,4]
print("2")
print(a.contains(3))
print(when(a.contains(3)))
print("3")
let x = when ( valueOf(isItDoneYet) && (valueOf(label1.text) == valueOf(label2.text)) && when(a.contains(3)) )
print("Before label1: \(x.isTrue)")
label1.text = "hello"
print("After label1: \(x.isTrue)")
isItDoneYet = true
print("After done: \(x.isTrue)")
label2.text = "hello"
print("After label2: \(x.isTrue)")
a.append(3)
print("After 3: \(x.isTrue)")

print(x)



