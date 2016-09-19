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
	
	private var tabItems = [USGScrollingTabItem]()
	private var tabWidths = [CGFloat]()
	private var tabIntervals = [CGFloat]()
	private var contentMargin: CGFloat = 0 // リロード時に左右のマージンを計算して入れておく
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		_init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		_init()
	}
	
	private func _init() {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .Horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		layout.sectionInset = UIEdgeInsetsZero
		
		collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
		if let collectionView = collectionView {
			collectionView.dataSource = self
			collectionView.delegate = self
			collectionView.backgroundColor = UIColor.clearColor()
			collectionView.showsVerticalScrollIndicator = false
			collectionView.showsHorizontalScrollIndicator = false
			collectionView.scrollsToTop = false
			collectionView.directionalLockEnabled = true
			collectionView.delaysContentTouches = true
			collectionView.scrollEnabled = true
			
			// Disable Cell Prefetching
			if #available(iOS 10.0, *) {
				collectionView.prefetchingEnabled = false
			}
			
			addSubview(collectionView)
			
			collectionView.translatesAutoresizingMaskIntoConstraints = false
			addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]-0-|",
				options: NSLayoutFormatOptions(rawValue: 0),
				metrics: nil,
				views: ["view" : collectionView]))
			addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|",
				options: NSLayoutFormatOptions(rawValue: 0),
				metrics: nil,
				views: ["view" : collectionView]))
			
			collectionView.registerNib(USGScrollingTabCell.nib(), forCellWithReuseIdentifier: "cell")
		}
	}
	
	
	// MARK: -
	
	private func tabInfo(tabItems: [USGScrollingTabItem]) -> (tabWidths: [CGFloat], tabIntervals: [CGFloat]) {
		guard let collectionView = collectionView else {
			return (tabWidths: [CGFloat](), tabIntervals: [CGFloat]())
		}
		
		var tabWidthArray = [CGFloat]()
		var tabIntervalArray = [CGFloat]()
		
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
	
	func tabAction(sender: USGScrollingTabCell) {
		_selectTabAtIndex(sender.index, animated: true)
		delegate?.didSelectTabAtIndexPath(self, index: sender.index)
	}
	
	
	// MARK: -
	
	private var focusView: UIView?
	
	/// Should use Auto Sizing
	func setFocusView(newFocusView: UIView?) {
		if let focusView = self.focusView {
			focusView.removeFromSuperview()
		}
		
		if let newFocusView = newFocusView {
			collectionView?.addSubview(newFocusView)
		}
		
		focusView = newFocusView
	}
	
	func reloadTabs(items: [USGScrollingTabItem]) {
		guard let collectionView = collectionView else {
			return
		}
		
		tabItems = items
		
		let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
		layout.minimumInteritemSpacing = tabSpacing
		
		
		// タブ幅・タブ間隔を計算
		let info: (tabWidths: [CGFloat], tabIntervals: [CGFloat]) = tabInfo(items)
		tabWidths = info.tabWidths
		tabIntervals = info.tabIntervals
		
		// マージンを計算：コンテンツがビュー幅未満なら、中央配置になるようマージンを算出、スクローラブルなら tabBarInset を設定
		// (ビュー幅 - (タブ幅合計値 + タブ間隔合計値 - 指定マージン)) / 2
		let contentLength = tabWidths.reduce(0, combine: +) + max(tabSpacing * CGFloat(tabWidths.count) - tabSpacing, 0)
		contentMargin = max((collectionView.width - contentLength) / 2.0, tabBarInset)
		
		indexOfSelectedTab = 0
		if let focusView = focusView {
			focusView.y = focusVerticalMargin
			focusView.height = height - focusVerticalMargin * 2.0
			
			if items.count > 0 {
				focusView.x = contentMargin
				focusView.width = tabWidths[indexOfSelectedTab]
				focusView.hidden = false
			}
			else {
				focusView.hidden = true
			}
		}
		
		UIView.transitionWithView(collectionView,
		                          duration: 0.33,
		                          options: .TransitionCrossDissolve,
		                          animations: {
									collectionView.reloadData()
			},
		                          completion: {(finished) in
									collectionView.layoutIfNeeded()
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
		
		indexOfSelectedTab = pageIndexRounded
		
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
		let roundedPageOffset = max(pageOffset, 0)
		let currentPageOffset = (pageIndex > 0) ? roundedPageOffset - pageWidth * CGFloat(pageIndex) : roundedPageOffset
		
		// オフセット×レート+以前のタブ幅・タブページ幅の合計値
		var focusOffset = currentPageOffset * (tabWidth / pageWidth) + beforeFocusOffset + contentMargin
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
		collectionView?.layoutIfNeeded()
		dispatch_async(dispatch_get_main_queue(), {
			self._selectTabAtIndex(index, animated: animated)
		})
	}
	
	private func _selectTabAtIndex(index: Int, animated: Bool) {
		let index = max(min(index, tabItems.count - 1), 0)
		
		guard let collectionView = collectionView else {
			return
		}
		
		indexOfSelectedTab = index
		let indexPath = NSIndexPath(forRow: index, inSection: 0)
		
		collectionView.selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: .CenteredHorizontally)
		
		if let tab = collectionView.cellForItemAtIndexPath(indexPath), let focusView = focusView {
			var targetFrame = focusView.frame
			targetFrame.origin.x = tab.x
			targetFrame.size.width = tabWidths[index]
			
			UIView.animateWithDuration(animated ? 0.3 : 0.0,
			                           delay: 0.0,
			                           options: [.BeginFromCurrentState],
			                           animations: {
										focusView.frame = targetFrame
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
		
		tab.setNormalStringWithoutAnimation(tabItem.normalString)
		tab.highlightedString = tabItem.highlightedString
		tab.selectedString = tabItem.selectedString
		tab.layer.borderColor = UIColor.redColor().CGColor
		tab.layer.borderWidth = 0.5
		
		return tab
	}
	
}


extension USGScrollingTabBar: UICollectionViewDelegate {
	
	func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
		
		if let tab = cell as? USGScrollingTabCell {
			tab.layoutSubviews()
		}
		
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
		// コンテンツが少なければ（スクローラブルでなければ）中央配置になる想定
		return UIEdgeInsetsMake(0, contentMargin, 0, contentMargin)
	}
}
