//
//  USGScrollingTabBar.h
//  ScrollingTabBar
//
//  Created by Satori Maru on 16.07.04.
//  Copyright © 2015-2016 usagimaru. All rights reserved.
//

import UIKit

protocol USGScrollingTabBarDelegate: class {
	func didSelectTabAtIndexPath(tabBar: USGScrollingTabBar, index: Int)
}

class USGScrollingTabBar: UIView {
	
	weak var delegate: USGScrollingTabBarDelegate?
	var pageWidth: CGFloat = 0.0
	var tabBarInset: CGFloat = 0.0
	var tabSpacing: CGFloat = 0.0
	var tabInset: CGFloat = 0.0
	var focusVerticalMargin: CGFloat = 0.0
	//var focusCornerRadius: CGFloat = 0.0
	//var focusColor: UIColor?
	var decelerationRate: CGFloat = UIScrollViewDecelerationRateNormal
	var enabled: Bool {
		get {
			if let collectionView = collectionView {
				return collectionView.scrollEnabled
			}
			else {
				return false
			}
		}
		set {
			collectionView?.scrollEnabled = newValue
		}
	}
	private(set) var tabCount: Int = 0
	private(set) var indexOfSelectedTab: Int = 0
	
	private var collectionView: UICollectionView?
	var focusView: UIView? {
		didSet {
			if let focusView = focusView {
				collectionView?.addSubview(focusView)
			}
			else {
				focusView?.removeFromSuperview()
			}
		}
	}
	
	private var tabItems = Array<USGScrollingTabItem>()
	private var tabWidths = Array<CGFloat>()
	private var tabIntervals = Array<CGFloat>()
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		_init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		_init()
	}
	
	private func _init() {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .Horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		layout.sectionInset = UIEdgeInsetsZero
		
		collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
		collectionView!.dataSource = self
		collectionView!.delegate = self
		collectionView!.backgroundColor = UIColor.clearColor()
		collectionView!.showsVerticalScrollIndicator = false
		collectionView!.showsHorizontalScrollIndicator = false
		collectionView!.scrollsToTop = false
		collectionView!.directionalLockEnabled = true
		collectionView!.delaysContentTouches = true
		collectionView!.scrollEnabled = true
		addSubview(collectionView!)
		
//		collectionView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//		collectionView!.frame = bounds
		collectionView!.layer.borderColor = UIColor.redColor().CGColor
		collectionView!.layer.borderWidth = 1.0
		collectionView!.translatesAutoresizingMaskIntoConstraints = false
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]-0-|",
			options: NSLayoutFormatOptions(rawValue: 0),
			metrics: nil,
			views: ["view" : collectionView!]))
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|",
			options: NSLayoutFormatOptions(rawValue: 0),
			metrics: nil,
			views: ["view" : collectionView!]))
		
		collectionView?.registerNib(USGScrollingTabCell.nib(), forCellWithReuseIdentifier: "cell")
	}
	
	
	// MARK: -
	
	private func tabInfo(tabItems: Array<USGScrollingTabItem>) -> (tabWidths: Array<CGFloat>, tabIntervals: Array<CGFloat>) {
		
		guard let collectionView = collectionView else {
			return (tabWidths: Array<CGFloat>(), tabIntervals: Array<CGFloat>())
		}
		
		var tabWidthArray = Array<CGFloat>()
		var tabIntervalArray = Array<CGFloat>()
		
		let viewWidth_half = CGFloat(collectionView.width / 2.0)
		var totalTabWidth = tabBarInset
		var tabIntervalAdjusted = false
		
		for (idx, prevTabItem) in tabItems.enumerate() {
			let prevTabWidth = USGScrollingTabCell.tabWidth(prevTabItem.normalString, tabInset: tabInset)
			tabWidthArray.append(prevTabWidth)
			
			// タブ同士の間隔を計算
			if idx < tabItems.count - 1 {
				// 累計タブ幅
				totalTabWidth += prevTabWidth + tabSpacing
				
				// 次のタブ項目と、そこからタブ幅を算出
				var nextTabItem: USGScrollingTabItem? = nil
				if idx + 1 < tabItems.count {
					nextTabItem = tabItems[idx + 1]
					
					let nextTabWidth = USGScrollingTabCell.tabWidth(nextTabItem!.normalString, tabInset: tabInset)
					
					var tabInterval: CGFloat = 0
					
					
					// 選択タブを中心に配置するための、タブ間隔の調整
					// 累計タブ幅がビューの半分以上という条件が成り立つ最初のタブなら、タブ間隔を調整する
					// 累計タブ幅がビューの半分未満の場合、タブ間隔を0のままにする
					if (totalTabWidth + nextTabWidth >= viewWidth_half) {
						// タブ同士の間隔を算出
						tabInterval = (prevTabWidth + nextTabWidth) / 2.0 + tabSpacing
						
						// 累計タブ幅がビューの半分以上が成り立つ最初のタブ
						if (!tabIntervalAdjusted) {
							tabInterval = totalTabWidth - viewWidth_half + (nextTabWidth / 2.0)
							tabIntervalAdjusted = true
						}
					} // if
					
					tabIntervalArray.append(tabInterval)
				} // if
			} // if
		} // for
		
		
		// 要素数合わせで最後の要素を複製
		if tabIntervalArray.count > 0 {
			tabIntervalArray.append(tabIntervalArray.last!)
		}
		
		return (tabWidths: tabWidthArray, tabIntervals: tabIntervalArray)
	}
	
	
	// 一次関数
	private func linearFunction(x: CGFloat, a1: CGFloat, a2: CGFloat, index: Int) -> CGFloat {
		let a = a1 - a2
		let b = -a * CGFloat(index) + a2
		let y = a * x + b
		return y
	}
	
	internal func tabAction(sender: USGScrollingTabCell) {
		
		selectTabAtIndex(sender.index, animated: true)
		delegate?.didSelectTabAtIndexPath(self, index: sender.index)
	}
	
	
	// MARK: -
	
	func reloadTabs(items: Array<USGScrollingTabItem>) {
		
		guard let collectionView = collectionView else {
			return
		}
		
		tabItems = items
		
		let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
		layout.minimumInteritemSpacing = tabSpacing
		
		
		// タブ幅・タブ間隔を計算
		let info: (tabWidths: Array<CGFloat>, tabIntervals: Array<CGFloat>) = tabInfo(items)
		tabWidths = info.tabWidths
		tabIntervals = info.tabIntervals
		
		
		if let focusView = focusView {
			focusView.y = focusVerticalMargin
			focusView.height = height - focusVerticalMargin * 2.0
			
			if items.count > 0 {
				focusView.x = tabBarInset
				focusView.width = tabWidths[indexOfSelectedTab]
				focusView.hidden = false
			}
			else {
				focusView.hidden = true
			}
		}
		
		collectionView.reloadData()
		
		dispatch_async(dispatch_get_main_queue(), {
			self.selectTabAtIndex(self.indexOfSelectedTab, animated: false)
		})
		
	}
	
	func scrollToOffset(pageOffset: CGFloat) {
		
		guard let collectionView = collectionView else {
			return
		}
		
		let count = tabItems.count
		let pageWidth = self.pageWidth
		
		// ページレート
		let pageRate = pageOffset / pageWidth
		
		// インデックスがタブ項目数を超過しないよう調整
		let pageIndexRaw = Int(floor(pageRate))
		let pageIndex = Int(max(min(CGFloat(floor(pageRate)), CGFloat(count-1)), 0.0))
		let pageIndexRounded = Int(max(min(CGFloat(round(pageRate)), CGFloat(count-1)), 0.0))
		let selectionIndexPath = NSIndexPath(forRow: pageIndexRounded, inSection: 0)
		
		
		// 現在のタブ幅・タブページ幅
		let tabWidth: CGFloat = tabWidths[pageIndex] + tabSpacing;
		let tabInterval: CGFloat = tabIntervals[pageIndex]
		
		// 以前のタブ幅・タブページ幅の合計値
		var beforeFocusOffset: CGFloat = 0;
		var beforeTabBarOffset: CGFloat = 0;
		for i in 0..<pageIndex {
			beforeFocusOffset += tabWidths[i] + tabSpacing
			beforeTabBarOffset += tabIntervals[i]
		}
		
		// 次ページに移ったらページオフセットを0に戻す
		let currentPageOffset = (pageIndex > 0) ? pageOffset - pageWidth * CGFloat(pageIndex) : pageOffset
		
		// オフセット×レート+以前のタブ幅・タブページ幅の合計値
		var focusOffset = currentPageOffset * (tabWidth / pageWidth) + beforeFocusOffset + tabBarInset
		var tabBarOffset = currentPageOffset * (tabInterval / pageWidth) + beforeTabBarOffset
		
		// 最適なフォーカス幅を計算
		// -1番目のときは、幅0と0番目の幅を扱う
		let prev_a = (pageRate >= 0.0) ? tabWidths[pageIndex] : 0.0
		let next_a = pageIndexRaw+1 < tabWidths.count ? tabWidths[pageIndexRaw + 1] : 0.0
		let focusWidth = linearFunction(pageRate, a1: next_a, a2: prev_a, index: pageIndexRaw)
		
		// 範囲調整
		tabBarOffset = min(max(tabBarOffset, 0), collectionView.contentSize.width - collectionView.width)
		focusOffset = min(max(focusOffset, tabBarInset), collectionView.contentSize.width - focusWidth - tabBarInset)
		
		
		// オフセットとフォーカスのフレームを設定
		collectionView.contentOffset = CGPointMake(tabBarOffset, 0)
		collectionView.selectItemAtIndexPath(selectionIndexPath, animated: true, scrollPosition: .None)
		
		if let focusView = focusView {
			focusView.x = focusOffset
			focusView.width = max(focusWidth, focusView.height)
		}
	}
	
	func selectTabAtIndex(index: Int, animated: Bool) {
		if index >= tabItems.count {
			return
		}
		
		guard let collectionView = collectionView else {
			return
		}
		
		indexOfSelectedTab = index
		let indexPath = NSIndexPath(forRow: index, inSection: 0)
		
		collectionView.selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: .CenteredHorizontally)
		
		
		guard let focusView = focusView else {
			return
		}
		
		if let tab = collectionView.cellForItemAtIndexPath(indexPath) {
			var focusFrame = focusView.frame
			focusFrame.origin.x = tab.x
			focusFrame.size.width = tabWidths[index]
			
			UIView.animateWithDuration(animated ? 0.33 : 0.0,
			                           delay: 0.0,
			                           options: UIViewAnimationOptions.BeginFromCurrentState,
			                           animations: { 
										focusView.frame = focusFrame
				},
			                           completion: nil)
		}
		
	}
	
	func stopScrollDeceleration() {
		
		if let collectionView = collectionView {
			collectionView.setContentOffset(collectionView.contentOffset, animated: false)
		}
	}
	
}


extension USGScrollingTabBar: UICollectionViewDataSource {

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return tabItems.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let tabItem = tabItems[indexPath.row]
		let tab = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! USGScrollingTabCell
		
		tab.collectionView = collectionView
		tab.index = indexPath.row
		tab.target = self
		tab.buttonAction = #selector(tabAction(_:))
		
		tab.normalString = tabItem.normalString
		tab.highlightedString = tabItem.highlightedString
		tab.selectedString = tabItem.selectedString
		
		return tab
	}

}


extension USGScrollingTabBar: UICollectionViewDelegate {
	
	func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
		
		if let focusView = focusView {
			collectionView.insertSubview(focusView, atIndex: 0)
		}
	}
	
//	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//		selectTabAtIndex(indexPath.row, animated: true)
//		delegate?.didSelectTabAtIndexPath(self, index: indexPath.row)
//	}

}


extension USGScrollingTabBar: UICollectionViewDelegateFlowLayout {
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		let tabItem = tabItems[indexPath.row]
		let tabWidth = USGScrollingTabCell.tabWidth(tabItem.normalString, tabInset: tabInset)
		return CGSizeMake(tabWidth, collectionView.height)
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
		return UIEdgeInsetsMake(0, tabBarInset, 0, tabBarInset)
	}
}
