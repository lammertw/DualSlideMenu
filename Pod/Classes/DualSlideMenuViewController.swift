//
//  DualSlideMenuViewController.swift
//  Pods
//
//  Created by Vincent Le on 3/24/16.
//  Main container class that accepts the sub view controllers on initialization
//  The main functions should be public to allow developers to use in specific cases

import UIKit

public enum State {
    case Left
    case Right
    case Main
}
public class DualSlideMenuViewController: UIViewController {

    //Create variables that will be used
    public var mainView: UIViewController!
    public var navigation: UINavigationController!
    public var currentState: State = .Main
    public var mainStoryboard: UIStoryboard!
    public var rightMenu: UIViewController!
    public var leftMenu: UIViewController!
    public var leftSideOffset: CGFloat = 150 // this variable will determine the offset of the main view when a menu view is in view
    public var rightSideOffset: CGFloat = 150 // this variable will determine the offset when the right menu is in view

    /**
      Main initialization method that is recommended for use

      The view controllers that are passed in can be navigation controllers if the developers decide to add navigation

      - parameter mainViewController
      - parameter leftMenuViewController
      - parameter rightMenuViewController
    */
    public convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        mainView = mainViewController
        leftMenu = leftMenuViewController
        rightMenu = rightMenuViewController

        addSwipeGestures(mainView)
        view.insertSubview(mainView.view, atIndex: 0) // adds main view at the bottom
        view.insertSubview(rightMenu.view, belowSubview: mainView.view) // stacks subview in order
        view.insertSubview(leftMenu.view, belowSubview: rightMenu.view) // the two subviews are added in this order, but makes no real noticeable difference
    }
    /**
     Method called on initialization that adds left and right swipe recognizers


     - parameter mainView: the view that will contain the gestures, which is the main view because only the main
       view will recognize the swipe gestures
     */
    func addSwipeGestures(mainView: UIViewController) {
        // creates two swipe gesture recognizers for the two side menus
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: Selector("handleSwipes:"))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: Selector("handleSwipes:"))
        // assigns correct direction for the two recognizers even though the names are confusing
        leftSwipe.direction = .Left
        rightSwipe.direction = .Right

        // adds the recognizers to the main view not the side views
        mainView.view.addGestureRecognizer(leftSwipe)
        mainView.view.addGestureRecognizer(rightSwipe)
    }
    
    /**
     Now allows developers to add swipe gesture in the side views
     
     - parameter viewController: the view controller that a recognizer will be added to
     - parameter direction:      the direction of type UISwipeGestureRecognizierDirection
     */
    public func addSwipeGestureInSide(viewController: UIViewController, direction: UISwipeGestureRecognizerDirection) {
        let swipe = UISwipeGestureRecognizer(target: self, action: Selector("handleSwipes:"))
        swipe.direction = direction
        viewController.view.addGestureRecognizer(swipe)
    }
    /**
     called when the user makes a swipe

     - parameter sender: the sender
     */
    func handleSwipes(sender:UISwipeGestureRecognizer) {
        // determines swipe direction from input and acts accordingly
        if (sender.direction == .Left) {
            toggle("left")
        }
        else if (sender.direction == .Right){
            toggle("right")
        }
    }

    /**
     Main toggle function that controls navigation of side menu

     - parameter swipeDirection: the direction of the swipe
        ex. "left" or "right" where swiping from left to right is a "right" swipe
     */
    public func toggle(swipeDirection: String) {
        // acts depending on the current state of the app
        switch currentState{
        case .Main :
            //Swipe left to open right panel
            if (swipeDirection == "left") {
                moveToView(true, type: .Right)
                swapPanels(.Right)
            }
            //Swipe right to open left panel
            else if (swipeDirection == "right") {
                moveToView(true, type: .Left)
                swapPanels(.Left)
            }
            break
        case .Left :
            //Swipe left to close left panel
            if (swipeDirection == "left") {
                moveToView(false, type: .Left)
            } else {
                collapseAll()
            }
            break
        case .Right :
            //Swipe right to close right panel
            if (swipeDirection == "right") {
                moveToView(false, type: .Right)
            } else {
                collapseAll()
            }
            break
        }
    }

    /**
      This is an escape method that will animate to the main view no matter what view the app
      is currently in

      This method will not animate the transition, so the main view will appear in view instantly
      Up to developers to decide which to use for their use case

      - parameter completion handler because animations are run asynchronously
    */
    public func toMain(completion: ((Bool) -> Void)! = nil) {
        // the animation has a duration of 0, so nothing is actually be animated
        // everthing is instantaneous
        UIView.animateWithDuration(0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.mainView.view.frame.origin.x = 0
            }, completion: completion)
    }

    /**
     Will move to main view from either left or right menu.
     Pretty straight forward, this is a cleaner implementation of toMain and does include animations
     Up to developers to decide to fit their use case
     */
    public func collapseAll() {
        // conditional all ends in main view, just determines which animation to do so
        if currentState == .Left {
            moveToView(false, type: .Left)
        } else if currentState == .Right {
            moveToView(false, type: .Right)
        }
    }
    /**
     Swap side panels positions
        example places right panel behind left panel

     - parameter type: the panel that will be on top
     */
    func swapPanels(type: State) {
        if (type == .Right){
            leftMenu.view.removeFromSuperview()
            view.insertSubview(leftMenu.view, belowSubview: rightMenu.view)
        }
        else if (type == .Left) {
            rightMenu.view.removeFromSuperview()
            view.insertSubview(rightMenu.view, belowSubview: leftMenu.view)
        }
    }

    /**
     Navigate to left or right panel

     - parameter open: to show the side view or to show the main view
     - parameter type: the type of view that is currently being displayed
     */
    func moveToView(open: Bool, type: State){
        if (open) {
            currentState = type
            var displacement: CGFloat = 0
            //Calculate the amount of distance the main view needs to move
            if (type == .Left) {
                displacement = CGRectGetWidth(mainView.view.frame) - leftSideOffset
            }
            else if (type == .Right) {
                displacement = rightSideOffset - CGRectGetWidth(mainView.view.frame)
            }
            moveMainViewBy(displacement)
        }
        else {
            //Move back to main view
            moveMainViewBy(0) { completion in
                self.currentState = .Main
            }

        }

    }
    /**
     Controls the animation of sliding a view on or off where the main view
     is the view that is being moved in order to show the side views
     - parameter xDisplacement: The slide value and direction
     - parameter completion:   The completion handler for asynchronous calls
     */
    func moveMainViewBy(xDisplacement: CGFloat, completion: ((Bool) -> Void)! = nil) {
        //Animate with a spring damping coefficient of 0.8
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.mainView.view.frame.origin.x = xDisplacement
        }, completion: completion)
    }
}
