//
//  AINativeConsentView.swift
//  PaytmNativeSDK
//
//  Created by Sumit Garg on 15/01/20.
//  Copyright © 2020 Sumit Garg. All rights reserved.
//


import UIKit
import PaytmNativeSDK

public class PaytmConsentCheckBox: UIView {
    var consentView: AINativeConsentView?
    @objc var onCheckChange: RCTBubblingEventBlock?

    override init(frame: CGRect) {
        super.init(frame: frame)
          commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        self.consentView = AINativeConsentView()
        
        consentView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 150)
        if let consentView = consentView {
            consentView.clipsToBounds = true
            self.clipsToBounds = true
            self.translatesAutoresizingMaskIntoConstraints = false;
            self.backgroundColor = .gray
            self.frame = consentView.frame
            self.addSubview(consentView)
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: consentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: consentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: consentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: consentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
            self.layoutIfNeeded()
            
            consentView.consentCallback = {[weak self] (consent) in
                self?.onCheckChange?(["value": consent])
                print(consent)
            }
        }
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
           for subview in self.subviews{
            if let view = subview as? AINativeConsentView  {
                print(view.isUserInteractionEnabled)
                print(view.point(inside:point, with: event))
                if !view.isHidden && view.alpha > 0 && view.isUserInteractionEnabled && view.point(inside:point, with: event) {
                    return true
                }
            }
           }

       return false
    }
    
    public override func layoutSubviews() {
        print("Layout Subviews")
    }
}

extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self)
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

