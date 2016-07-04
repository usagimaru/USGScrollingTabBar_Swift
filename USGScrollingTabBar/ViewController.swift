//
//  ViewController.swift
//  USGScrollingTabBar
//
//  Created by Satori Maru on 16.07.04.
//  Copyright © 2016年 usagimaru. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	@IBOutlet weak var scrollingTabBar: USGScrollingTabBar!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var focusView: UIView!
	
	var tabItems = Array<USGScrollingTabItem>()
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		scrollingTabBar.delegate = self
		scrollingTabBar.tabBarInset = 12
		scrollingTabBar.tabSpacing = 8
		scrollingTabBar.tabInset = 8
		scrollingTabBar.focusVerticalMargin = 4
		scrollingTabBar.focusView = focusView
		scrollingTabBar.decelerationRate = UIScrollViewDecelerationRateFast
		
		let strings = [
			"渋谷",
			"表参道",
			"青山一丁目",
			"永田町",
			"半蔵門",
			"九段下",
			"神保町",
			"大手町",
			"三越前",
			"水天宮前",
			"清澄白河",
			"住吉",
			"錦糸町",
			"押上〈スカイツリー前〉",
			]
		
		let font = UIFont.systemFontOfSize(13)
		let color = UIColor.whiteColor()
		let highlightedColor = UIColor(colorLiteralRed: 0.8654, green: 0.5059, blue: 0.8728, alpha: 1.0)
		let selectedColor = UIColor.blackColor()
		
		let highlightedAttributes = [
			NSForegroundColorAttributeName : highlightedColor
		]
		let selectedAttributes = [
			NSFontAttributeName : UIFont.boldSystemFontOfSize(font.pointSize),
			NSForegroundColorAttributeName : selectedColor
		]
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .Center
		paragraph.lineBreakMode = .ByTruncatingTail
		
		for str in strings {
			let string = USGScrollingTabItem.normalAttributedString(str,
			                                                        font: font,
			                                                        color: color,
			                                                        paragraphStyle: paragraph)
			
			let tabItem = USGScrollingTabItem()
			tabItem.normalString = string
			tabItem.highlightedString = USGScrollingTabItem.replaceAttributesInString(string, attributes: highlightedAttributes)
			tabItem.selectedString = USGScrollingTabItem.replaceAttributesInString(string, attributes: selectedAttributes)
			
			tabItems.append(tabItem)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		for (idx, _) in tabItems.enumerate() {
			let label = UILabel(frame: CGRectZero)
			label.textAlignment = .Center
			label.backgroundColor = UIColor.clearColor()
			label.text = "\(idx)"
			label.font = UIFont.boldSystemFontOfSize(20)
			label.numberOfLines = 0
			label.sizeToFit()
			label.x = scrollView.width * CGFloat(idx)
			label.y = 100
			label.width = scrollView.width
			scrollView.addSubview(label)
		}
		
		scrollView.contentSize = CGSizeMake(view.width * CGFloat(tabItems.count), scrollView.contentSize.height)
		
		focusView.layer.cornerRadius = (scrollingTabBar.height - scrollingTabBar.focusVerticalMargin * 2.0) / 2.0
		
		scrollingTabBar.width = view.width - 20
		scrollingTabBar.pageWidth = scrollView.width;
		scrollingTabBar.reloadTabs(tabItems)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
	}

}

extension ViewController: USGScrollingTabBarDelegate {
	
	func didSelectTabAtIndexPath(tabBar: USGScrollingTabBar, index: Int) {
		scrollView.setContentOffset(CGPointMake(scrollView.width * CGFloat(index), scrollView.contentOffset.y), animated: true)
	}
}

extension ViewController: UIScrollViewDelegate {
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		scrollingTabBar.enabled = !scrollView.tracking;
		
		if (scrollView.tracking || scrollView.decelerating) {
			scrollingTabBar.scrollToOffset(scrollView.contentOffset.x)
		}
	}
	
	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		scrollingTabBar.stopScrollDeceleration()
		scrollingTabBar.enabled = false
	}
	
	func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		scrollingTabBar.enabled = true
	}
}

