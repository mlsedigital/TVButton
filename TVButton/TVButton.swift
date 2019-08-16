//
//  TVButton.swift
//  TVButton
//
//  Created by Roy Marmelstein on 08/11/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation
/**
 Parallax Layer Object
 */
public struct TVButtonLayer {
    /// UIView to display.
    var view: UIView?
    var layerPressed: ((CGPoint?) -> ())?
}

public extension TVButtonLayer {
    /**
     Initialise the TVButton layer by passing a View
     - Parameter image: UIImage to display. It is essential that all images have the same dimensions.
     */
    init(view: UIView) {
        self.init(view: view, layerPressed: nil)
    }
}

/**
 TVButton Object
 */
open class TVButton: UIButton, UIGestureRecognizerDelegate {
    
    // MARK: Internal variables
    internal var containerView = UIView()
    internal var specularView = UIImageView()
    internal var tvButtonAnimation: TVButtonAnimation?
    
    internal var longPressGestureRecognizer: UILongPressGestureRecognizer?
    internal var panGestureRecognizer: UIPanGestureRecognizer?
    internal var tapGestureRecognizer: UITapGestureRecognizer?
    
    /// Stack of TVButtonLayers inside the button
    open var layers: [TVButtonLayer]?
    
    /// Determines the intensity of the parallax depth effect. Default is 1.0.
    open var parallaxIntensity: CGFloat = defaultParallaxIntensity
    
    /// Shadow color for the TVButton. Default is black.
    internal var shadowColor: UIColor = UIColor.black {
        didSet {
            self.layer.shadowColor = shadowColor.cgColor
        }
    }
    
    internal func setLayers(layers: [TVButtonLayer]) {
        self.layers = layers
        configureLayers()
    }
    
    // MARK: Public variables and functions
    
    // MARK: Lifecycle
    
    /**
     Default init for TVObject with coder.
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    /**
     Default init for TVObject with frame.
     */
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    /**
     Lays out subviews.
     */
    override open func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = self.bounds
        self.layer.masksToBounds = false;
        let shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius)
        self.layer.shadowPath = shadowPath.cgPath
        
        // Stop here if animation is on
        if let animation = tvButtonAnimation {
            if animation.highlightMode == true {
                return
            }
        }
        
        // Adjust size for every subview
        for subview in containerView.subviews {
            if subview == specularView {
                subview.frame = CGRect(origin: subview.frame.origin, size: CGSize(width: specularScale * containerView.frame.size.width, height: specularScale * containerView.frame.size.height))
            }
        }
    }
    
    //MARK: - Setup and configuration
    func setup() {
        containerView.isUserInteractionEnabled = false
        self.addSubview(containerView)
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        specularView.alpha = 0.0
        specularView.contentMode = UIViewContentMode.scaleAspectFill
        self.layer.shadowRadius = self.bounds.size.height/(2*shadowFactor)
        self.layer.shadowOffset = CGSize(width: 0.0, height: shadowFactor/3)
        self.layer.shadowOpacity = 0.5
        tvButtonAnimation = TVButtonAnimation(button: self)
        self.addGestureRecognizers()
    }
    
    func configureLayers() {
        // Remove existing parallax layer views
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
        
        // Instantiate an imageview with corners for every layer
        for layer in layers! {
            if let view = layer.view {
                view.layer.cornerRadius = cornerRadius
                view.clipsToBounds = true
                view.layer.needsDisplayOnBoundsChange = true
                containerView.addSubview(view)
                view.pinToSuperView()
            }
        }
        // Add specular shine effect
        let frameworkBundle = Bundle(for: TVButton.self)
        let specularViewPath = frameworkBundle.path(forResource: "Specular", ofType: "png")
        specularView.image = UIImage(contentsOfFile:specularViewPath!)
        self.containerView.addSubview(specularView)
    }
    
    // MARK: UIGestureRecognizer actions and delegate
    
    /**
     Adds the gesture recognizers to the button.
     */
    func addGestureRecognizers() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer?.delegate = self
        self.addGestureRecognizer(panGestureRecognizer!)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGestureRecognizer!)
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer?.delegate = self
        self.addGestureRecognizer(longPressGestureRecognizer!)
    }
    
    /**
     Pan gesture recognizer handler.
     - Parameter gestureRecognizer: TVButton's UIPanGestureRecognizer.
     */
    @objc func handlePan(_ gestureRecognizer: UIGestureRecognizer) {
        self.gestureRecognizerDidUpdate(gestureRecognizer)
    }
    
    /**
     Long press gesture recognizer handler.
     - Parameter gestureRecognizer: TVButton's UILongPressGestureRecognizer.
     */
    @objc func handleLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        self.gestureRecognizerDidUpdate(gestureRecognizer)
    }
    
    /**
     Tap gesture recognizer handler. Sends TouchUpInside to super.
     - Parameter gestureRecognizer: TVButton's UITapGestureRecognizer.
     */
    @objc func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        super.sendActions(for: UIControlEvents.touchUpInside)
        self.gestureRecognizerDidUpdate(gestureRecognizer)
    }
    
    /**
     Determines button's reaction to gesturerecognizer.
     - Parameter gestureRecognizer: either UITapGestureRecognizer or UILongPressGestureRecognizer.
     */
    func gestureRecognizerDidUpdate(_ gestureRecognizer: UIGestureRecognizer){
        guard let layers = layers else {
            return
        }
        let point = gestureRecognizer.location(in: self)
        
        if gestureRecognizer == tapGestureRecognizer {
            for layer in layers {
                if let function = layer.layerPressed {
                    function(point)
                }
            }
        }
        
        if let animation = tvButtonAnimation {
            if gestureRecognizer.state == .began {
                animation.enterMovement()
                animation.processMovement(point)
            }
            else if gestureRecognizer.state == .changed {
                animation.processMovement(point)
            }
            else {
                if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                    return
                }
                animation.exitMovement()
            }
        }
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    /**
     UIGestureRecognizerDelegate function to allow two UIGestureRecognizers to be recognized simultaneously.
     - Parameter gestureRecognizer: First gestureRecognizer.
     - Parameter otherGestureRecognizer: Second gestureRecognizer.
     */
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension UIView {
    func pinToSuperView() {
        guard let superview = self.superview else {
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            self.topAnchor.constraint(equalTo: superview.topAnchor),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor)])
    }
}

