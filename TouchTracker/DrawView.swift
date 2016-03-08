//
//  DrawView.swift
//  TouchTracker
//
//  Created by Sebastian on 3/8/16.
//  Copyright © 2016 Sebastian. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    
    var currentLines = [NSValue: Line]()
    var finishedLines = [Line]()
    var moveRecognizer: UIPanGestureRecognizer!
    
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                UIMenuController.sharedMenuController().setMenuVisible(false, animated: true)
            }
        }
    }
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor: UIColor = UIColor.redColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func strokeLine(line: Line) {
        
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = CGLineCap.Round
        
        path.moveToPoint(line.begin)
        path.addLineToPoint(line.end)
        path.stroke()
    }
    
    override func drawRect(rect: CGRect) {
        
        finishedLineColor.setStroke()
        
        for line in finishedLines {
            strokeLine(line)
        }
        
        currentLineColor.setStroke()
        
        for (_, line) in currentLines {
            strokeLine(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.greenColor().setStroke()
            let selectedLine = finishedLines[index]
            strokeLine(selectedLine)
        }
    }
    
    func indexOfLineAtPoint(point: CGPoint) -> Int? {
        
        for (index, line) in finishedLines.enumerate() {
            
            let begin = line.begin
            let end = line.end
            
            for t in CGFloat(0).stride(to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        
        //if nothing is close enough to the tapped point
        return nil
    }
    
    func deleteLine(sender: AnyObject) {
        if let index = selectedLineIndex {
            finishedLines.removeAtIndex(index)
            selectedLineIndex = nil
            
            setNeedsDisplay()
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapRecognizer.numberOfTapsRequired = 2
        //to avoid first dot drawn when detecting a double tap
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tap:")
        //to avoid catching a possible double tap
        tapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
        tapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: "moveLine:")
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }

    
    //MARK: - UIResponder
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        //to see the order of events
        print(__FUNCTION__)
        
        for touch in touches {
            
            let location = touch.locationInView(self)
            let newLine = Line(begin: location, end: location)
            
            //documentation says not to hold strong reference to touches
            let key = NSValue(nonretainedObject: touch)
            
            currentLines[key] = newLine
        
        }
        
        //flags the view to be redrawn at the end of the run loop
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
      
        print(__FUNCTION__)
        
        for touch in touches {
            
            let key = NSValue(nonretainedObject: touch)
            
            currentLines[key]?.end = touch.locationInView(self)
            
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        print(__FUNCTION__)
        
        for touch in touches {
            
            let key = NSValue(nonretainedObject: touch)
            
            if var line = currentLines[key] {
            
                line.end = touch.locationInView(self)
                
                finishedLines.append(line)
                currentLines.removeValueForKey(key)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {

        print(__FUNCTION__)
        
        currentLines.removeAll()
        
        setNeedsDisplay()
        
    }
    
    
    //MARK: - UIGestureRecognizerProtocol
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: - Gesture Recognizer Implementations
    
    func doubleTap(gestureRecognizer: UIGestureRecognizer) {
        
        selectedLineIndex = nil
        
        currentLines.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity: false)
        
        setNeedsDisplay()
    }
    
    func tap(gestureRecognizer: UIGestureRecognizer) {
        
        let point = gestureRecognizer.locationInView(self)
        selectedLineIndex = indexOfLineAtPoint(point)
        
        let menu = UIMenuController.sharedMenuController()
        
        if selectedLineIndex != nil {
            
            //needed for the menu to appear
            becomeFirstResponder()
            
            let deleteItem = UIMenuItem(title: "Delete", action: "deleteLine:")
            menu.menuItems = [deleteItem]
            menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    func longPress(gestureRecognizer: UIGestureRecognizer) {
        
        if gestureRecognizer.state == .Began {
            let point = gestureRecognizer.locationInView(self)
            selectedLineIndex = indexOfLineAtPoint(point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll(keepCapacity: false)
            }
        } else if gestureRecognizer.state == .Ended {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    func moveLine(gestureRecognizer: UIPanGestureRecognizer) {
        
        if let index = selectedLineIndex {
            
            if gestureRecognizer.state == .Changed {
                
                let translation = gestureRecognizer.translationInView(self)
                
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, inView: self)
                
                setNeedsDisplay()
            }
        } else { //no line is selected
            
            return
        }
    }
    
}
