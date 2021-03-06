//
//  StudyBoxViewController.swift
//  StudyBox_iOS
//
//  Created by Kacper Cz on 03.03.2016.
//  Copyright © 2016 BLStream. All rights reserved.
//

import UIKit
import MMDrawerController

@objc protocol StudyBoxController {
    var isDrawerVisible: Bool { get set }
    func toggleDrawer()
}

extension StudyBoxController where Self:UIViewController {
    func setupDrawer() {
        if let drawer = UIApplication.sharedRootViewController as? MMDrawerController {
            if let controller = navigationController?.viewControllers[0] where controller === self {
                let hamburgerImage = UIImage(named: "Hamburger")
                let button = UIBarButtonItem(image: hamburgerImage, landscapeImagePhone: nil, style: UIBarButtonItemStyle.Plain, target: self,
                                             action: #selector(toggleDrawer))
                navigationItem.leftBarButtonItem = button
                drawer.openDrawerGestureModeMask = .Custom
            } else {
                drawer.openDrawerGestureModeMask = .None
            }
            
        }
        
    }
  
    
}

extension StudyBoxController where Self:SBDrawerCenterDelegate {
    func drawerToggleAnimation() {
        isDrawerVisible = !isDrawerVisible
        var animationTime: NSTimeInterval!
        if let drawer = UIApplication.sharedRootViewController as? SBDrawerController {
            animationTime = drawer.drawerAnimationTime
        }
        UIView.animateWithDuration(animationTime,
            animations: {
                self.updateStatusBar()
        })
    }
}
//View Controller, which will be inherited by other VC's

class StudyBoxViewController: UIViewController, StudyBoxController, SBDrawerCenterDelegate {

    var isDrawerVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDrawer()

    }
    func toggleDrawer(){
        if let drawer = UIApplication.sharedRootViewController as? MMDrawerController {
            drawer.toggleDrawerSide(.Left, animated: true, completion: nil)
        }
    }
    
    func updateStatusBar() {
        if let navigationController = self.navigationController {
            navigationController.setNeedsStatusBarAppearanceUpdate()
        } else {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
   
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if isDrawerVisible {
            return .LightContent
        }
        
        return .Default
    }

    func disposeResources(isVisible: Bool) {
        
    }
  
}

class StudyBoxCollectionViewController: UICollectionViewController, StudyBoxController, SBDrawerCenterDelegate, DrawerResourceDisposable {
    
    var isDrawerVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDrawer()
        
    }
    func toggleDrawer(){
        if let drawer = UIApplication.sharedRootViewController as? MMDrawerController {
            drawer.toggleDrawerSide(.Left, animated: true, completion: nil)
        }
    }
    
    func updateStatusBar() {
        if let navigationController = self.navigationController {
            navigationController.setNeedsStatusBarAppearanceUpdate()
        } else {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if isDrawerVisible {
            return .LightContent
        }
        
        return .Default
    }
   
    func disposeResources(isVisible: Bool) {
        
    }
}
