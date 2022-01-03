//
//  PromiseButton.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 22/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import UIKit
import PromiseKit

public class PromiseButton: UIButton {
    public lazy var guarantee = Guarantee<UIButton>.pending()
   
    var targetClosure: UIButtonTargetClosure?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        targetClosure = { (button) in
            self.guarantee.resolve(button)
        }
        addTarget(self, action: #selector(PromiseButton.closureAction), for: .touchUpInside)
    }
    
    @objc func closureAction() {
        guard let targetClosure = targetClosure else { return }
        isSelected = true
        targetClosure(self)
    }
}

typealias UIButtonTargetClosure = (UIButton) -> ()

class ClosureWrapper: NSObject {
    let closure: UIButtonTargetClosure
    init(_ closure: @escaping UIButtonTargetClosure) {
        self.closure = closure
    }
}

//extension UIButton {
//
//    private struct AssociatedKeys {
//        static var targetClosure = "targetClosure"
//    }
//
//    private var targetClosure: UIButtonTargetClosure? {
//        get {
//            guard let closureWrapper = objc_getAssociatedObject(self, &AssociatedKeys.targetClosure) as? ClosureWrapper else { return nil }
//            return closureWrapper.closure
//        }
//        set(newValue) {
//            guard let newValue = newValue else { return }
//            objc_setAssociatedObject(self, &AssociatedKeys.targetClosure, ClosureWrapper(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//
//    func addTargetClosure(closure: @escaping UIButtonTargetClosure) {
//        targetClosure = closure
//        addTarget(self, action: #selector(UIButton.closureAction), for: .touchUpInside)
//    }
//
//    @objc func closureAction() {
//        guard let targetClosure = targetClosure else { return }
//        targetClosure(self)
//    }
//}
