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
	
	var tabItems = [USGScrollingTabItem]()
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		scrollingTabBar.delegate = self
		scrollingTabBar.tabBarInset = 8
		scrollingTabBar.tabSpacing = 16
		scrollingTabBar.focusVerticalMargin = 4
//		scrollingTabBar.fixedTabWidth = 213
		scrollingTabBar.setFocusView(focusView)
		
		buildSampleItems()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		view.layoutIfNeeded()
		
		buildSamplePages()
		
		let firstPageIndex = 2
		
		focusView.layer.cornerRadius = (scrollingTabBar.height - scrollingTabBar.focusVerticalMargin * 2.0) / 2.0
		scrollView.contentSize = CGSize(width: view.width * CGFloat(tabItems.count), height: scrollView.contentSize.height)
		scrollingTabBar.width = view.width
		scrollingTabBar.pageWidth = scrollView.width
		scrollingTabBar.reloadTabs(tabItems, indexOf: firstPageIndex)
		scrollView.setContentOffset(CGPoint(x: scrollView.width * CGFloat(firstPageIndex), y: scrollView.contentOffset.y), animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	fileprivate func buildSampleItems() {
		let strings = [
			"渋谷 Shibuya",
			"表参道 Omotesando",
			"青山一丁目 Aoyama-Itchome",
			"永田町 Nagatacho",
			"半蔵門 Hanzomon",
			"九段下 Kudanshita",
			"神保町 Jimbocho",
			"大手町 Otemachi",
			"三越前 Mitsukoshi-mae",
			"水天宮前 Suitengu-mae",
			"清澄白河 Kiyosumi-Shirakawa",
			"住吉 Sumiyoshi",
			"錦糸町 Kinshicho",
			"押上〈スカイツリー前〉 Oshiage (Skytree)",
			]
		
		let font = UIFont.systemFont(ofSize: 13)
		let color = UIColor.white
		let highlightedColor = UIColor(colorLiteralRed: 0.8654, green: 0.5059, blue: 0.8728, alpha: 1.0)
		let selectedColor = UIColor.black
		
		let highlightedAttributes = [
			NSForegroundColorAttributeName : highlightedColor
		]
		let selectedAttributes = [
			NSFontAttributeName : UIFont.boldSystemFont(ofSize: font.pointSize),
			NSForegroundColorAttributeName : selectedColor
		]
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		paragraph.lineBreakMode = .byTruncatingTail
		
		for str in strings {
			let normalString = NSAttributedString.attributedString(str,
			                                                       font: font,
			                                                       color: color,
			                                                       paragraphStyle: paragraph,
			                                                       otherAttributes: [(kCTLanguageAttributeName as String) : "ja"])
			
			let tabItem = USGScrollingTabItem()
			tabItem.normalString = normalString
			tabItem.highlightedString = normalString.addAttributes(attributes: highlightedAttributes)
			tabItem.selectedString = normalString.addAttributes(attributes: selectedAttributes)
			
			tabItems.append(tabItem)
		}
	}
	
	fileprivate func buildSamplePages() {
		for (idx, _) in tabItems.enumerated() {
			let label = UILabel(frame: CGRect.zero)
			label.textAlignment = .center
			label.backgroundColor = UIColor.clear
			label.text = "\(idx)"
			label.font = UIFont.boldSystemFont(ofSize: 20)
			label.numberOfLines = 0
			label.sizeToFit()
			label.x = scrollView.width * CGFloat(idx)
			label.y = 8
			label.width = scrollView.width
			scrollView.addSubview(label)
			
			let imageView = UIImageView(image: UIImage(named: "\(idx)"))
			imageView.contentMode = .scaleAspectFit
			imageView.x = scrollView.width * CGFloat(idx)
			imageView.y = 40
			imageView.height = 400
			imageView.width = scrollView.width
			scrollView.addSubview(imageView)
		}
	}

}

extension ViewController: USGScrollingTabBarDelegate {
	
	func tabBar(_ tabBar: USGScrollingTabBar, didSelectTabAt index: Int) {
		scrollView.setContentOffset(CGPoint(x: scrollView.width * CGFloat(index), y: scrollView.contentOffset.y), animated: true)
	}
}

extension ViewController: UIScrollViewDelegate {
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		scrollingTabBar.enabled = !scrollView.isTracking;
		
		if (scrollView.isTracking || scrollView.isDecelerating) {
			scrollingTabBar.scrollToOffset(scrollView.contentOffset.x)
		}
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		scrollingTabBar.stopScrollDeceleration()
		scrollingTabBar.enabled = false
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		scrollingTabBar.enabled = true
	}
}

