//: Playground - noun: a place where people can play

import UIKit


class Node {
    let name: String
    var kids: [Node] = []
    init(_ name: String) {
        self.name = name
    }
}

class LoopNode: Equatable {
    let name: String
    var kids: [LoopNode] = []
    init(_ name: String) {
        self.name = name
    }
    
    static func == (left: LoopNode, right: LoopNode) -> Bool {
        return left.name == right.name && left.kids == right.kids
    }
}

var root = Node("root")
var a = Node("a")
var aa = Node("aa")
var ab = Node("ab")
var b = Node("b")
var ba = Node("ba")
let c = Node("c")
var ca = Node("ca")

root.kids = [a, b, c]
a.kids = [aa, ab]
b.kids = [ba]
c.kids = [ca]

var loopRoot = LoopNode("Root")
var loopA = LoopNode("A")
var loopB = LoopNode("B")
loopRoot.kids = [loopA, loopB]
loopA.kids = [loopB]
loopB.kids = [loopRoot]


public struct Tree<T> {
    // receives the curent `node` and the nodes that led to it. Return the nodes children
    public typealias Walkfunc = (_ node: T, _ parents: [T])->[T]
    
    // the root node of the tree
    public let root: T
}

/// Depth first
extension Tree {
    public func walkDepthFirst(block: Walkfunc) {
        Tree.walkDepthFirst(from: root, block: block)
    }
    
    public static func walkDepthFirst(from node: T, block: Walkfunc) {
        _walkDepthFirst(node, parents: [], block: block)
    }

    private static func _walkDepthFirst(_ node: T, parents: [T], block: Walkfunc) {
        let children = block(node, parents)
        
        let parents = parents + [node]
        for child in children {
            _walkDepthFirst(child, parents: parents, block: block)
        }
    }
}

// Width first
extension Tree {
    public func walkWidthFirst(block: Walkfunc) {
        Tree.walkWidthFirst(from: root, block: block)
    }
    
    public static func walkWidthFirst(from node: T, block: Walkfunc) {
        _walkWidthFirst([node], parents: [], block: block)
    }
    
    private static func _walkWidthFirst(_ nodes: [T], parents: [T], block: Walkfunc) {
        var allChildren: [(T, [T])] = []
        for node in nodes {
            let children = block(node, parents)
            allChildren.append((node, children))
        }
        
        for (node, children) in allChildren {
            _walkWidthFirst(children, parents: parents + [node], block: block)
        }
    }
}

/// If T is equatable it's possible to check for circular node references
extension Tree where T: Equatable {
    public func walkDepthFirst(block: Walkfunc) {
        Tree.walkDepthFirst(from: root, block: block)
    }
    
    public static func walkDepthFirst(from node: T, block: Walkfunc) {
        _walkDepthFirst(node, parents: [], visited: [], block: block)
    }
    
    private static func _walkDepthFirst(_ node: T, parents: [T], visited: [T], block: Walkfunc) {
        let children = block(node, parents)
        
        let parents = parents + [node]
        let visited = visited + [node]
        for child in children where !visited.contains(child) {
            _walkDepthFirst(child, parents: parents, visited: visited, block: block)
        }
    }
}

extension Tree where T: Equatable {
    public func walkWidthFirst(block: Walkfunc) {
        Tree.walkWidthFirst(from: root, block: block)
    }
    
    public static func walkWidthFirst(from node: T, block: Walkfunc) {
        _walkWidthFirst([node], parents: [], visited: [], block: block)
    }
    
    private static func _walkWidthFirst(_ nodes: [T], parents: [T], visited: [T], block: Walkfunc) {
        var visited = visited;
        
        var allChildren: [(T, [T])] = []
        for node in nodes where !visited.contains(node) {
            let children = block(node, parents)
            allChildren.append((node, children))
        }
        
        for (node, children) in allChildren where !visited.contains(node) {
            visited.append(node)
            _walkWidthFirst(children, parents: parents + [node], visited: visited, block: block)
        }
    }
}


func walkfunc(item: Node, parents: [Node]) -> [Node] {
    let indentation = parents.map{_ in "  "}.joined(separator: "")
    print(indentation + item.name)
    return item.kids
}

func walkfunc(item: LoopNode, parents: [LoopNode]) -> [LoopNode] {
    let indentation = parents.map{_ in "  "}.joined(separator: "")
    print(indentation + item.name)
    return item.kids
}

Tree.walkWidthFirst(from: root, block: walkfunc)
Tree.walkDepthFirst(from: root, block: walkfunc)
Tree.walkWidthFirst(from: loopRoot, block: walkfunc)
Tree.walkDepthFirst(from: loopRoot, block: walkfunc)

Tree(root: root).walkWidthFirst(block: walkfunc)
Tree(root: root).walkDepthFirst(block: walkfunc)

Tree(root: loopRoot).walkWidthFirst(block: walkfunc)
Tree(root: loopRoot).walkDepthFirst(block: walkfunc)

print("OK")

// walking a dictionary
let dic: [String: Any] = [
    "this": "that",
    "here": ["one": "two"],
    "there": ["three": ["five": ["six": 6]]]
]

Tree.walkDepthFirst(from: dic) { item, parents in
    let indentation = parents.map{_ in "  "}.joined(separator: "")
    print(indentation + item.description)
    return item.values.flatMap { $0 as? [String:Any] }
}

