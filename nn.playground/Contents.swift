//: Playground - noun: a place where people can play

import UIKit


let l1 = [1,1]
let c1 = [1,1,1,1,1,1,1,1]
let l2 = [1,1,1,1]
let c2 = [1,1,1,1,1,1,1,1]
let l3 = [1,1]

func random() -> Float {
    return Float(arc4random()) / Float(UINT32_MAX)
}

class NameGenerator {
    var list = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    var count: Int = 0
    
    var next: String {
        var name = ""
        var count = self.count
        while count > list.count {
            name += String(list[list.index(list.startIndex, offsetBy: count % list.count)])
            count -= list.count
        }
        self.count += 1
        return name + String(list[list.index(list.startIndex, offsetBy: count)])
    }
}

class Weighted {
    static let nameGenerator = NameGenerator()
    var name: String = Weighted.nameGenerator.next
    var weight: Float = random()
}

class Node: Weighted, CustomStringConvertible, CustomDebugStringConvertible {
    var inputs: [Connection] = []
    var outputs: [Connection] = []
    
    var description: String {
        return "\(type(of: self)) \(name) with \(inputs.count) inputs and \(outputs.count) outputs and value \(weight)"
    }
    
    var debugDescription: String {
        return description
    }
}

class Connection: Weighted {
    var a, b: Node
    
    init(a: Node, b: Node) {
        self.a = a
        self.b = b
    }
}

class Layer: CustomStringConvertible, CustomDebugStringConvertible {
    var nodes: [Node]
    
    init(n: Int) {
        nodes = (0..<n).map { _ in Node() }
    }
    
    var description: String {
        return "\(type(of: self)) with \(nodes.count) nodes"
    }
    
    var debugDescription: String {
        return description + "\n  " + nodes.map{$0.debugDescription}.joined(separator: "\n  ")
    }
}

class Net: CustomStringConvertible, CustomDebugStringConvertible {
    var layers: [Layer]
    
    init(_ layers: [Int]) {
        self.layers = layers.map { Layer(n: $0) }
    }
    
    func connect() {
        for l1 in layers[..<(layers.count-1)] {
            for l2 in layers[1..<layers.count] {
                for n1 in l1.nodes {
                    for n2 in l2.nodes {
                        let connection = Connection(a: n1, b: n2)
                        n1.outputs.append(connection)
                        n2.inputs.append(connection)
                    }
                }
            }
        }
    }
    
    var inputs: [Node] {
        return layers.first?.nodes ?? []
    }
    
    var outputs: [Node] {
        return layers.last?.nodes ?? []
    }
    
    var description: String {
        return "Net with \(inputs.count) inputs, \(outputs.count), and \(layers.count-2) hidden layers"
    }
    
    var debugDescription: String {
        return description + "\n " + layers.map{$0.debugDescription}.joined(separator: "\n ")
    }
}


let net = Net([2, 2])
net.connect()
print(net)

let node = net.inputs.first!
print(node)
print(node.outputs.first!)

print(net.debugDescription)
