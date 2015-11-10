//
//  TVButtonAnimation.swift
//  TVButton
//
//  Created by Roy Marmelstein on 10/11/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation

class TVButtonAnimation {
    
    var highlightMode: Bool = false
    var button: TVButton?

    init(button: TVButton) {
        self.button = button
    }
    
    func enterMovement() {
        if highlightMode == true {
            return
        }
        if let tvButton = button {
            self.highlightMode = true
            let targetShadowOffset = CGSizeMake(0.0, tvButton.bounds.size.height/shadowFactor)
            tvButton.layer.removeAllAnimations()
            CATransaction.begin()
            CATransaction.setCompletionBlock({ () -> Void in
                tvButton.layer.shadowOffset = targetShadowOffset
            })
            let shaowOffsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
            shaowOffsetAnimation.toValue = NSValue(CGSize: targetShadowOffset)
            shaowOffsetAnimation.duration = animationDuration
            shaowOffsetAnimation.removedOnCompletion = false
            shaowOffsetAnimation.fillMode = kCAFillModeForwards
            shaowOffsetAnimation.timingFunction = CAMediaTimingFunction(name: "easeOut")
            tvButton.layer.addAnimation(shaowOffsetAnimation, forKey: "shadowOffset")
            CATransaction.commit()
        }
    }
    
    func processMovement(point: CGPoint){
        if (highlightMode == false) {
            return
        }
        if let tvButton = button {
            let offsetX = point.x / tvButton.bounds.size.width
            let offsetY = point.y / tvButton.bounds.size.height
            let dx = point.x - tvButton.bounds.size.width/2
            let dy = point.y - tvButton.bounds.size.height/2
            let xRotation = (dy - offsetY)*(rotateXFactor/tvButton.bounds.size.width)
            let yRotation = (offsetX - dx)*(rotateYFactor/tvButton.bounds.size.width)
            let zRotation = (xRotation + yRotation)/rotateZFactor
            
            let xTranslation = (-2*point.x/tvButton.bounds.size.width)*maxTranslation
            let yTranslation = (-2*point.y/tvButton.bounds.size.height)*maxTranslation
            
            let xRotateTransform = CATransform3DMakeRotation(degreesToRadians(xRotation), 1, 0, 0)
            let yRotateTransform = CATransform3DMakeRotation(degreesToRadians(yRotation), 0, 1, 0)
            let zRotateTransform = CATransform3DMakeRotation(degreesToRadians(zRotation), 0, 0, 1)
            
            let combinedRotateTransformXY = CATransform3DConcat(xRotateTransform, yRotateTransform)
            let combinedRotateTransformZ = CATransform3DConcat(combinedRotateTransformXY, zRotateTransform)
            let translationTransform = CATransform3DMakeTranslation(-xTranslation, yTranslation, 0.0)
            let combinedRotateTranslateTransform = CATransform3DConcat(combinedRotateTransformZ, translationTransform)
            let targetScaleTransform = CATransform3DMakeScale(highlightedScale, highlightedScale, highlightedScale)
            let combinedTransform = CATransform3DConcat(combinedRotateTranslateTransform, targetScaleTransform)
            
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                tvButton.layer.transform = combinedTransform
                tvButton.specularView.alpha = 0.3
                tvButton.specularView.center = point
                }, completion: nil)
            for var i = 1; i < tvButton.containerView.subviews.count ; i++ {
                let subview = tvButton.containerView.subviews[i]
                if subview != tvButton.specularView {
                    subview.center = CGPointMake(tvButton.bounds.size.width/2 + xTranslation*CGFloat(i)*tvButton.parallaxIntensity*parallaxIntensityXFactor, tvButton.bounds.size.height/2 + yTranslation*CGFloat(i)*tvButton.parallaxIntensity)
                }
            }
        }
    }
    
    func exitMovement() {
        if highlightMode == false {
            return
        }
        if let tvButton = button {
            let targetShadowOffset = CGSizeMake(0.0, shadowFactor/3)
            let targetScaleTransform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            tvButton.specularView.layer.removeAllAnimations()
            CATransaction.begin()
            CATransaction.setCompletionBlock({ () -> Void in
                tvButton.layer.transform = targetScaleTransform
                tvButton.layer.shadowOffset = targetShadowOffset
                self.highlightMode = false
            })
            let shaowOffsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
            shaowOffsetAnimation.toValue = NSValue(CGSize: targetShadowOffset)
            shaowOffsetAnimation.duration = animationDuration
            shaowOffsetAnimation.fillMode = kCAFillModeForwards
            shaowOffsetAnimation.removedOnCompletion = false
            shaowOffsetAnimation.timingFunction = CAMediaTimingFunction(name: "easeOut")
            tvButton.layer.addAnimation(shaowOffsetAnimation, forKey: "shadowOffset")
            let scaleAnimation = CABasicAnimation(keyPath: "transform")
            scaleAnimation.toValue = NSValue(CATransform3D: targetScaleTransform)
            scaleAnimation.duration = animationDuration
            scaleAnimation.removedOnCompletion = false
            scaleAnimation.fillMode = kCAFillModeForwards
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: "easeOut")
            tvButton.layer.addAnimation(scaleAnimation, forKey: "scaleAnimation")
            CATransaction.commit()
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                tvButton.transform = CGAffineTransformIdentity
                tvButton.specularView.alpha = 0.0
                for var i = 0; i < tvButton.containerView.subviews.count ; i++ {
                    let subview = tvButton.containerView.subviews[i]
                    subview.center = CGPointMake(tvButton.bounds.size.width/2, tvButton.bounds.size.height/2)
                }
                }, completion:nil)
        }
    }
    
    // MARK: Convenience
    
    func degreesToRadians(value:CGFloat) -> CGFloat {
        return value * CGFloat(M_PI) / 180.0
    }

}