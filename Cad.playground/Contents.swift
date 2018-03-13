//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

typealias Identifier = String

// abstract node.
class Node {
    typealias Identifier = String
    
    var id: Identifier
    var name: String = ""
    var children: [Node] = []
    
    init(id: Identifier) {
        self.id = id
    }
    
    var actual: Node {
        return self
    }
}

// has position and stuff
class ConcreteNode: Node {
    
    override init(id: Identifier) {
        super.init(id: id)
    }
}

// A node doing something with it's child nodes and generates a new node in it's place
class CompositionNode: Node {
    
}

class ShapeNode: Node {
    var shape: Shape
    
    init(id: Identifier, shape: Shape) {
        self.shape = shape
        super.init(id: id)
    }
}

class CompoundNode: Node {
    var compound: Compond
    
    init(id: Identifier, compound: Compond) {
        self.compound = compound
        super.init(id: id)
    }
}

enum Compond {
    case union
}

protocol Shape {
    
}

struct Box: Shape {
    let x, y, z: Float
}

struct Sphere: Shape {
    let r: Float
}

struct Translation: Shape {
    let x, y, z: Float
}

struct Rotation: Shape {
    let x, y, z: Float
}


let root = Node(id: "root")
let union = CompoundNode(id: "union", compound: .union)
let translate = ShapeNode(id: "translate", shape: Translation(x: -35, y: 5, z: 0))
let sphere = ShapeNode(id: "sphere1", shape: Sphere(r: 20))
let rotation = ShapeNode(id: "rotate1", shape: Rotation(x: 0, y: 0, z: 45))
let box = ShapeNode(id: "box1", shape: Box(x: 70, y: 30, z: 10))


root.children.append(union)
union.children.append(sphere)
union.children.append(translate)
translate.children.append(rotation)
rotation.children.append(box)


protocol Painter {
    associatedtype Context
    
    func didVisit(node: Node, in context: Context)
    func hasVisited(node: Node, in context: Context) -> Bool
    
    func draw(sphere: Sphere, node: Node, in context: Context)
    func draw(box: Box, node: Node, in context: Context)
    func draw(translation: Translation, node: Node, in context: Context)
    func draw(rotation: Rotation, node: Node, in context: Context)
    
    func drawUnion(node: Node, in context: Context)
}

extension Painter {
    func draw(shapeNode node: ShapeNode, in context: Context) {
        switch node.shape {
        case let shape as Sphere:
            draw(sphere: shape, node: node, in: context)
        case let shape as Box:
            draw(box: shape, node: node, in: context)
        case let shape as Translation:
            draw(translation: shape, node: node, in: context)
        case let shape as Rotation:
            draw(rotation: shape, node: node, in: context)
        default:
            break
        }
    }
    
    func draw(compondNode node: CompoundNode, in context: Context) {
        switch node.compound {
        case .union:
            drawUnion(node: node, in: context)
        }
    }
    
    func drawNext(from node: Node, in context: Context) {
        for child in node.children where !hasVisited(node: child, in: context) {
            draw(node: child, in: context)
        }
    }
    
    func draw(node: Node, in context: Context) {
        didVisit(node: node, in: context)
        
        switch node {
        case let node as ShapeNode:
            draw(shapeNode: node, in: context)
        case let node as CompoundNode:
            draw(compondNode: node, in: context)
        default:
            break
        }
        
        drawNext(from: node, in: context)
    }
    
}

class Coder: Painter {
    
    class Context {
        var indentation: String
        var tree = [String]()
        var visited: [Node] = []
        
        func add(_ str: String) {
            tree.append(indentation + str)
        }
        
        init(indentation: String) {
            self.indentation = indentation
        }
    }
    
    func draw(sphere: Sphere, node: Node, in context: Context) {
        context.add("sphere(r=\(sphere.r));")
    }
    
    func draw(box: Box, node: Node, in context: Coder.Context) {
        context.add("cube([\(box.x), \(box.y), \(box.z)]);")
    }
    
    func push(node: Node, in context: Context) {
        let coder = Coder()
        let nextContext = Context(indentation: context.indentation + "  ")
        coder.drawNext(from: node, in: nextContext)
        context.tree.append(contentsOf: nextContext.tree)
        context.visited.append(contentsOf: nextContext.visited)
        context.add("};")
    }
    
    func draw(translation: Translation, node: Node, in context: Coder.Context) {
        context.add("translate([\(translation.x), \(translation.y), \(translation.z)]) {")
        push(node: node, in: context)
    }
    
    func draw(rotation: Rotation, node: Node, in context: Coder.Context) {
        context.add("rotate([\(rotation.x), \(rotation.y), \(rotation.z)]) {")
        push(node: node, in: context)
    }
    
    func drawUnion(node: Node, in context: Coder.Context) {
        context.add("union() {")
        push(node: node, in: context)
    }
    
    func draw(root: Node) -> String {
        
        let context = Context(indentation: "")
        draw(node: root, in: context)
        
        return context.tree.joined(separator: "\n")
    }
    
    
    func didVisit(node: Node, in context: Context) {
        context.visited.append(node)
    }
    func hasVisited(node: Node, in context: Context) -> Bool {
        return context.visited.contains(where: {$0===node})
    }
}

class CGContextPainter: Painter {
    
    typealias Context = CGContext
    
    func draw(sphere: Sphere, node: Node, in context: Context) {
        context.setStrokeColor(UIColor.red.cgColor)
        let r = CGFloat(sphere.r)
        context.addEllipse(in: CGRect(x: -r, y: -r, width: r*2, height: r*2))
        context.strokePath()
    }
    
    func draw(box: Box, node: Node, in context: CGContext) {
        context.addRect(CGRect(x: 0, y: 0, width: CGFloat(box.x), height: -CGFloat(box.y)))
        context.strokePath()
    }
    
    func draw(translation: Translation, node: Node, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: CGFloat(translation.x), y: -CGFloat(translation.y))
        drawNext(from: node, in: context)
        context.restoreGState()
    }
    
    func draw(rotation: Rotation, node: Node, in context: CGContext) {
        context.saveGState()
        context.rotate(by: CGFloat(-rotation.z))
        drawNext(from: node, in: context)
        context.restoreGState()
    }
    
    func drawUnion(node: Node, in context: CGContext) {
        
    }
    
    var visited: [Node] = []
    func didVisit(node: Node, in context: CGContext) {
        visited.append(node)
    }
    func hasVisited(node: Node, in context: CGContext) -> Bool {
        return visited.contains(where: {$0===node})
    }
    
    
    func drawImage(from node: Node, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext( size );
        defer { UIGraphicsEndImageContext() }
    
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        context.translateBy(x: size.width/2, y: size.height/2)
        draw(node: node, in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

class PaintView: UIView {
    var root: Node? = nil
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let root = root else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.translateBy(x: bounds.width/2, y: bounds.height/2)
        
        let painter = CGContextPainter()
        painter.draw(node: root, in: context)
    }
}

let image = CGContextPainter().drawImage(from: root, size: CGSize(width: 150, height: 150))

let view = PaintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
view.backgroundColor = .gray
view.root = root
PlaygroundPage.current.liveView = view

let coder = Coder()
print(coder.draw(root: root))
