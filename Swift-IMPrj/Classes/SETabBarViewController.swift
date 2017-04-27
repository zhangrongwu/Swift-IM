//
//  SETabBarViewController.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/18.
//  Copyright © 2017年 bocom. All rights reserved.
//

import UIKit

class SETabBarViewController: UITabBarController {

    override class func initialize() {
        var  attrs = [String: NSObject]()
//        attrs[NSForegroundColorAttributeName] = UIColor(r: 87, g: 206, b: 138)
        // 设置tabBar字体颜色
        UITabBarItem.appearance().setTitleTextAttributes(attrs, for:.selected)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewControllers()
        // Do any additional setup after loading the view.
    }
    
    func addChildViewControllers() {
        setupChildViewController("消息", image: "", selectedImage: "", controller: SEMessageViewController.init())
        setupChildViewController("通讯", image: "", selectedImage: "", controller: SEMessageViewController.init())
        setupChildViewController("精灵", image: "", selectedImage: "", controller: SEMessageViewController.init())
        setupChildViewController("家园", image: "", selectedImage: "", controller: SEMessageViewController.init())
        setupChildViewController("我的", image: "", selectedImage: "", controller: SEMessageViewController.init())

    }
    
    fileprivate func setupChildViewController(_ title: String, image: String, selectedImage: String, controller: UIViewController) {
        
        controller.tabBarItem.title = title
        controller.title = title
//        controller.view.backgroundColor =
        controller.tabBarItem.image = UIImage(named: image)
        controller.tabBarItem.selectedImage = UIImage(named: selectedImage)
        let naviController = SENavigationViewController.init(rootViewController: controller)
        addChildViewController(naviController)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
