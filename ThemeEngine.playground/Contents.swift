//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

var ThemeEngineStyleNameKey: UInt8 = 0
extension UIView {
    @IBInspectable var styleName: String? {
        get { return objc_getAssociatedObject(self, &ThemeEngineStyleNameKey) as? String }
        set { objc_setAssociatedObject(self, &ThemeEngineStyleNameKey, newValue, .OBJC_ASSOCIATION_COPY)}
    }
    
    var stylePath: [String] {
        get { return (superview?.stylePath ?? []) + [styleName].flatMap{$0} }
    }
}

enum Constraint {
    /// Contained in given style path
    case containedIn(String)
}

struct Style {
    var name: String?
    
    var constraints: [Constraint]?
    
    var foregroundColor: UIColor?
    var backgroundColor: UIColor?
    var font: UIFont?
    
    init(_ name: String? = nil, config: (inout Style)->()) {
        self.name = name
        config(&self)
    }
}

Style { s in
    s.name = "root"
    s.backgroundColor = .yellow
}


@IBDesignable
class ThemeEngine: NSObject {
    
    let styles: [Style] = [
        Style { s in
            s.name = "root"
            s.backgroundColor = .gray
        },
        Style("back") { s in
            s.backgroundColor = .yellow
        },
        Style("title") { s in
              s.constraints = [.containedIn("back")]
              s.foregroundColor = .green
              s.backgroundColor = UIColor.init(white: 1, alpha: 0.5)
              s.font = UIFont.systemFont(ofSize: 56, weight: UIFont.Weight.heavy)
            },
        Style("title") { s in
              s.constraints = [.containedIn("root")]
              s.foregroundColor = .blue
              s.backgroundColor = UIColor.init(white: 1, alpha: 0.5)
              s.font = UIFont.systemFont(ofSize: 56, weight: UIFont.Weight.heavy)
        }
        ]
    
    @IBOutlet var managedObjects: [UIView] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }
    
    func stylesFor(view: UIView) -> [Style] {
        if let name = view.styleName {
            return styles.filter({ style in
                guard style.name == name else { return false }
                
                for constraint in style.constraints ?? [] {
                    switch constraint {
                    case .containedIn(let path):
                        if !view.stylePath.contains(path) {
                            return false
                        }
                    }
                }
                return true
            })
        }
        return []
    }
    
    func applyStyles() {
        for view in managedObjects {
            let styles = stylesFor(view: view)
            
            func attr<T>(block: (Style)->T?) -> T? {
                return styles.flatMap(block).last
            }
            
            view.backgroundColor = attr { $0.backgroundColor }
            view.backgroundColor = styles.flatMap({$0.backgroundColor}).last ?? view.backgroundColor
            
            if let label = view as? UILabel {
                label.textColor = style.foregroundColor ?? label.textColor
                label.font = style.font ?? label.font
            }
            
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        applyStyles()
    }
}


let root = UIStackView(frame: CGRect(x: 0, y: 0, width: 500, height: 700))
root.alignment = .fill
root.distribution = .fillEqually
root.axis = .vertical
root.styleName = "root"


func view<T: UIView>(_ type: T.Type, style: String, sub: [UIView] = []) -> UIView {
    let v = type.init()
    v.styleName = style
    if let label = v as? UILabel {
        label.text = style
    }
    if let stack = v as? UIStackView {
        stack.alignment = .fill
        stack.distribution = .fillEqually
        for s in sub {
            stack.addArrangedSubview(s)
        }
    } else {
        for s in sub {
            v.addSubview(s)
        }
    }
    return v
}

let views: [UIView] = [
    view(UILabel.self, style: "title"),
    view(UIStackView.self, style: "back", sub: [
        view(UILabel.self, style: "title")
        ]),
]



let label = UILabel()
label.text = "Hello World!"
label.sizeToFit()

for view in views {
    root.addArrangedSubview(view)
}

let engine = ThemeEngine()
engine.managedObjects = [root] + views + views.flatMap({$0.subviews})
engine.applyStyles()

root.layoutIfNeeded()
PlaygroundPage.current.liveView = root
print(root.debugDescription)
