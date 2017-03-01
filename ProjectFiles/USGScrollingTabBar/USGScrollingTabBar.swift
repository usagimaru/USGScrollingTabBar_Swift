//
//  USGScrollingTabBar.h
//  ScrollingTabBar
//
//  Created by Satori Maru on 16.07.04.
//  Copyright © 2015-2017 usagimaru. All rights reserved.
//

import UIKit

protocol USGScrollingTabBarDelegate: class {
	func tabBar(_ tabBar: USGScrollingTabBar, didSelectTabAt index: Int)
}

class USGScrollingTabBar: UIView {
	
	/// Layout Debugging
	let kDebugMode: Bool = false
	
	fileprivate(set) var tabCount: Int = 0
	fileprivate(set) var indexOfSelectedTab: Int = 0
	
	fileprivate var collectionView: UICollectionView?
	fileprivate var focusView: UIView?
	
	fileprivate var tabItems = [USGScrollingTabItem]()
	fileprivate var tabWidths = [CGFloat]()
	fileprivate var tabIntervals = [CGFloat]()
	fileprivate var contentMargin: CGFloat = 0 // リロード時に左右のマージンを計算して入れておく
	
	private(set) var previousIndexOfSelectedTab: Int = 0
	
	
	weak var delegate: USGScrollingTabBarDelegate?
	/// ページ幅
	var pageWidth: CGFloat = 1.0
	/// タブバー左右余白
	var tabBarInset: CGFloat = 0.0
	/// タブ同士の間隔
	var tabSpacing: CGFloat = 0.0
	var focusVerticalMargin: CGFloat = 0.0
	/// 固定幅にする場合はここで指定
	var fixedTabWidth: CGFloat?
	var enabled: Bool {
		get {
			if let collectionView = collectionView {
				return collectionView.isScrollEnabled
			}
			else {
				return false
			}
		}
		set {
			collectionView?.isScrollEnabled = newValue
		}
	}
	var animateWhenTabSelection: Bool = true
	var centering: Bool = true
	var cellClass: USGScrollingTabCell.Type = USGScrollingTabCell.self
	
	
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
	
	fileprivate func _init() {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		layout.sectionInset = UIEdgeInsets.zero
		
		collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
		if let collectionView = collectionView {
			collectionView.dataSource = self
			collectionView.delegate = self
			collectionView.backgroundColor = UIColor.clear
			collectionView.showsVerticalScrollIndicator = false
			collectionView.showsHorizontalScrollIndicator = false
			collectionView.scrollsToTop = false
			collectionView.isDirectionalLockEnabled = true
			collectionView.delaysContentTouches = true
			collectionView.isScrollEnabled = true
			
			// Disable Cell Prefetching
			if #available(iOS 10.0, *) {
				collectionView.isPrefetchingEnabled = false
			}
			
			addSubview(collectionView)
			
			collectionView.translatesAutoresizingMaskIntoConstraints = false
			addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|",
				options: NSLayoutFormatOptions(rawValue: 0),
				metrics: nil,
				views: ["view" : collectionView]))
			addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|",
				options: NSLayoutFormatOptions(rawValue: 0),
				metrics: nil,
				views: ["view" : collectionView]))
			
			collectionView.register(cellClass.nib(), forCellWithReuseIdentifier: "cell")
		}
		
		#if DEBUG
			if kDebugMode {
				layer.borderColor = UIColor.green.cgColor
				layer.borderWidth = 1.0
			}
		#endif
	}
	
	
	// MARK: -
	
	private func scanTabWidthsAndIntervals(tabItems: [USGScrollingTabItem],
	                                       viewWidth: CGFloat,
	                                       tabBarInset: CGFloat,
	                                       tabSpacing: CGFloat,
	                                       fixedTabWidth: CGFloat?,
	                                       reversed: Bool) -> (tabWidths: [CGFloat], tabIntervals: [CGFloat], adjustedPosition: Int?) {
		// Results
		var tabWidthArray = [CGFloat]()
		var tabIntervalArray = [CGFloat]()
		var adjustedPosition: Int? = nil
		
		// Params
		let viewWidth_half = viewWidth / 2.0
		var totalTabWidth = tabBarInset
		var tabIntervalAdjusted = false
		
		let collection = (reversed == false) ? tabItems.enumerated() : tabItems.reversed().enumerated()
		for (idx, prevTabItem) in collection {
			var prevTabWidth = CGFloat(0)
			
			if let fixedTabWidth = fixedTabWidth {
				// 固定幅の場合
				prevTabWidth = fixedTabWidth
				tabWidthArray.append(fixedTabWidth)
			}
			else {
				// テキストに合わせた可変幅の場合
				if let selectedString = prevTabItem.selectedString {
					let w_a = cellClass.tabWidth(prevTabItem.normalString)
					let w_b = cellClass.tabWidth(selectedString)
					prevTabWidth = max(w_a, w_b)
				}
				else {
					prevTabWidth = cellClass.tabWidth(prevTabItem.normalString)
				}
				
				tabWidthArray.append(prevTabWidth)
			}
			
			
			// タブ同士の間隔を計算
			if idx < tabItems.count - 1 {
				// 累計タブ幅
				totalTabWidth += prevTabWidth + CGFloat((fixedTabWidth == nil) ? tabSpacing : 0.0)
				
				// 次のタブ項目と、そこからタブ幅を算出
				var nextTabItem: USGScrollingTabItem? = nil
				if idx + 1 < tabItems.count {
					nextTabItem = tabItems[idx + 1]
					
					var nextTabWidth = CGFloat(0)
					
					if let fixedTabWidth = fixedTabWidth {
						// 固定幅の場合
						nextTabWidth = fixedTabWidth
					}
					else {
						// テキストに合わせた可変幅の場合
						if let selectedString = nextTabItem!.selectedString {
							let w_a = cellClass.tabWidth(nextTabItem!.normalString)
							let w_b = cellClass.tabWidth(selectedString)
							nextTabWidth = max(w_a, w_b)
						}
						else {
							nextTabWidth = cellClass.tabWidth(prevTabItem.normalString)
						}
					}
					
					var tabInterval: CGFloat = 0
					
					
					// 選択タブを中心に配置するための、タブ間隔の調整
					// 累計タブ幅がビューの半分以上という条件が成り立つ最初のタブなら、タブ間隔を調整する
					// 累計タブ幅がビューの半分未満の場合、タブ間隔を0のままにする
					if (totalTabWidth + nextTabWidth >= viewWidth_half) {
						// タブ同士の間隔を算出
						tabInterval = (prevTabWidth + nextTabWidth) / 2.0 + CGFloat((fixedTabWidth == nil) ? tabSpacing : 0.0)
						
						// 累計タブ幅がビューの半分以上が成り立つ最初のタブ
						if (!tabIntervalAdjusted) {
							tabInterval = totalTabWidth - viewWidth_half + (nextTabWidth / 2.0)
							tabIntervalAdjusted = true
							adjustedPosition = idx
						}
					} // if
					
					tabIntervalArray.append(tabInterval)
				} // if
			} // if
		} // for
		
		
		if reversed {
			return (tabWidths: tabWidthArray.reversed(), tabIntervals: tabIntervalArray.reversed(), adjustedPosition: adjustedPosition)
		}
		
		return (tabWidths: tabWidthArray, tabIntervals: tabIntervalArray, adjustedPosition: adjustedPosition)
	}
	
	fileprivate func calculateTabInfo(_ tabItems: [USGScrollingTabItem]) -> (tabWidths: [CGFloat], tabIntervals: [CGFloat]) {
		guard let collectionView = collectionView else {
			return (tabWidths: [CGFloat](), tabIntervals: [CGFloat]())
		}
		
		var tabWidthArray = [CGFloat]()
		var tabIntervalArray = [CGFloat]()
		
		// 正方向からのタブ幅・間隔を走査
		let tabInfo = scanTabWidthsAndIntervals(tabItems: tabItems,
		                                        viewWidth: collectionView.width,
		                                        tabBarInset: tabBarInset,
		                                        tabSpacing: tabSpacing,
		                                        fixedTabWidth: fixedTabWidth,
		                                        reversed: false)
		
		// FIXME: この部分なくてもまともに動くようにしたい =====
		guard let _ = fixedTabWidth else {
			tabWidthArray.append(contentsOf: tabInfo.tabWidths)
			tabIntervalArray.append(contentsOf: tabInfo.tabIntervals)
			
			// 要素数合わせで最後の要素を複製
			if tabIntervalArray.count > 0 {
				tabIntervalArray.append(tabIntervalArray.last!)
			}
			
			return (tabWidths: tabWidthArray, tabIntervals: tabIntervalArray)
		}
		// =====
		
		// 負方向からのタブ幅・間隔を走査
		let tabInfo_reversed = scanTabWidthsAndIntervals(tabItems: tabItems,
		                                                 viewWidth: collectionView.width,
		                                                 tabBarInset: tabBarInset,
		                                                 tabSpacing: tabSpacing,
		                                                 fixedTabWidth: fixedTabWidth,
		                                                 reversed: true)
		
		
		let tabInfoCount = tabInfo.tabWidths.count
		let adjustedPosition = tabInfo.adjustedPosition
		
		/*
		|>>|>>|--| …tabInfo
		|--|--|<<| …tabInfo_reversed
		|>>|>>|<<| …result
		*/
		
		for i in 0 ..< tabInfoCount {
			let tabWidth = tabInfo.tabWidths[i]
			let tabWidth_reversed = tabInfo_reversed.tabWidths[i]
			var tabInterval: CGFloat? = nil
			var tabInterval_reversed: CGFloat? = nil
			
			if i < tabInfoCount - 1 {
				tabInterval = tabInfo.tabIntervals[i]
				tabInterval_reversed = tabInfo_reversed.tabIntervals[i]
			}
			
			if let adjustedPosition = adjustedPosition {
				if i <= adjustedPosition {
					tabWidthArray.append(tabWidth)
					if let tabInterval = tabInterval {
						tabIntervalArray.append(tabInterval)
					}
				}
				else {
					tabWidthArray.append(tabWidth_reversed)
					if let tabInterval_reversed = tabInterval_reversed {
						tabIntervalArray.append(tabInterval_reversed)
					}
				}
			}
			else {
				tabWidthArray.append(tabWidth)
				if let tabInterval = tabInterval {
					tabIntervalArray.append(tabInterval)
				}
			}
		}
		
		
		
		// 要素数合わせで最後の要素を複製
		if tabIntervalArray.count > 0 {
			tabIntervalArray.append(tabIntervalArray.last!)
		}
		
		return (tabWidths: tabWidthArray, tabIntervals: tabIntervalArray)
	}
	
	
	// 一次関数
	fileprivate func linearFunction(_ x: CGFloat, a1: CGFloat, a2: CGFloat, index: Int) -> CGFloat {
		let a = a1 - a2
		let b = -a * CGFloat(index) + a2
		let y = a * x + b
		return y
	}
	
	func tabAction(_ sender: USGScrollingTabCell) {
		_selectTabAtIndex(sender.index, animated: animateWhenTabSelection)
		delegate?.tabBar(self, didSelectTabAt: sender.index)
	}
	
	
	// MARK: -
	
	/// Should layout with Auto Sizing
	func setFocusView(_ newFocusView: UIView?) {
		if let focusView = self.focusView {
			focusView.removeFromSuperview()
		}
		
		if let newFocusView = newFocusView {
			collectionView?.addSubview(newFocusView)
		}
		
		focusView = newFocusView
	}
	
	func reloadTabs(_ items: [USGScrollingTabItem], indexOf selectedTab: Int = 0) {
		guard let collectionView = collectionView else {
			return
		}
		
		// レイアウトを確定させる
		layoutIfNeeded()
		
		tabItems = items
		
		let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
		layout.minimumInteritemSpacing = tabSpacing
		
		
		// タブ幅・タブ間隔を計算
		let tabInfo: (tabWidths: [CGFloat], tabIntervals: [CGFloat]) = calculateTabInfo(items)
		tabWidths = tabInfo.tabWidths
		tabIntervals = tabInfo.tabIntervals
		
		if centering {
			// マージンを計算：コンテンツがビュー幅未満なら、中央配置になるようマージンを算出、スクローラブルなら tabBarInset を設定
			// (ビュー幅 - (タブ幅合計値 + タブ間隔合計値 - 指定マージン)) / 2
			let contentLength = tabWidths.reduce(0, +) + max(tabSpacing * CGFloat(tabWidths.count) - tabSpacing, 0)
			contentMargin = max((collectionView.width - contentLength) / 2.0, tabBarInset)
		}
		else {
			contentMargin = tabBarInset
		}
		
		indexOfSelectedTab = selectedTab
		if let focusView = focusView {
			focusView.y = focusVerticalMargin
			focusView.height = height - focusVerticalMargin * 2.0
			
			if items.count > 0 {
				focusView.x = contentMargin
				focusView.width = tabWidths[indexOfSelectedTab]
				focusView.isHidden = false
			}
			else {
				focusView.isHidden = true
			}
		}
		
		UIView.transition(with: collectionView,
		                          duration: 0.33,
		                          options: .transitionCrossDissolve,
		                          animations: {
									collectionView.reloadData()
			},
		                          completion: {_ in
									
		})
		
		collectionView.layoutIfNeeded()
		_selectTabAtIndex(indexOfSelectedTab, animated: false)
	}
	
	func scrollToOffset(_ pageOffset: CGFloat) {
		guard let collectionView = collectionView else {
			return
		}
		
		let count = tabItems.count
		let pageWidth = self.pageWidth
		
		if pageWidth == 0 {
			return
		}
		
		// ページレート
		let pageRate = pageOffset / pageWidth
		
		// インデックスがタブ項目数を超過しないよう調整
		let pageIndexRaw = Int(floor(pageRate))
		let pageIndex = Int(max(min(CGFloat(floor(pageRate)), CGFloat(count-1)), 0.0))
		let pageIndexRounded = Int(max(min(CGFloat(round(pageRate)), CGFloat(count-1)), 0.0))
		let selectionIndexPath = IndexPath(row: pageIndexRounded, section: 0)
		
		indexOfSelectedTab = pageIndexRounded
		
		// 現在のタブ幅・タブページ幅
		let tabWidth: CGFloat = tabWidths[pageIndex] + CGFloat((fixedTabWidth == nil) ? tabSpacing : 0.0)
		let tabInterval: CGFloat = tabIntervals[pageIndex]
		
		// 以前のタブ幅・タブページ幅の合計値
		var beforeFocusOffset: CGFloat = 0;
		var beforeTabBarOffset: CGFloat = 0;
		for i in 0..<pageIndex {
			beforeFocusOffset += tabWidths[i] + CGFloat((fixedTabWidth == nil) ? tabSpacing : 0.0)
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
		collectionView.contentOffset = CGPoint(x: tabBarOffset, y: 0)
		collectionView.selectItem(at: selectionIndexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
		
		if let focusView = focusView {
			focusView.x = focusOffset
			focusView.width = max(focusWidth, focusView.height)
		}
	}
	
	func selectTabAtIndex(_ index: Int, animated: Bool) {
		collectionView?.layoutIfNeeded()
		DispatchQueue.main.async(execute: {
			self._selectTabAtIndex(index, animated: animated)
		})
	}
	
	fileprivate func _selectTabAtIndex(_ index: Int, animated: Bool) {
		previousIndexOfSelectedTab = indexOfSelectedTab
		
		let index = max(min(index, tabItems.count - 1), 0)
		
		guard let collectionView = collectionView else {
			return
		}
		
		indexOfSelectedTab = index
		let indexPath = IndexPath(row: index, section: 0)
		
		collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: .centeredHorizontally)
		
		if let tab = collectionView.cellForItem(at: indexPath), let focusView = focusView {
			var targetFrame = focusView.frame
			targetFrame.origin.x = tab.x
			targetFrame.size.width = tabWidths[index]
			
			if animated {
				UIView.animate(withDuration: 0.3,
				               delay: 0.0,
				               options: [.beginFromCurrentState],
				               animations: {
								focusView.frame = targetFrame
				},
				               completion: nil)
			}
			else {
				focusView.frame = targetFrame
			}
		}
		
	}
	
	func stopScrollDeceleration() {
		if let collectionView = collectionView {
			collectionView.setContentOffset(collectionView.contentOffset, animated: false)
		}
	}
	
}


extension USGScrollingTabBar: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return tabItems.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let tabItem = tabItems[(indexPath as IndexPath).row]
		let tab = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! USGScrollingTabCell
		
		tab.collectionView = collectionView
		tab.index = (indexPath as IndexPath).row
		tab.target = self
		tab.buttonAction = #selector(tabAction(_:))
		
		tab.setNormalStringWithoutAnimation(tabItem.normalString)
		tab.highlightedString = tabItem.highlightedString
		tab.selectedString = tabItem.selectedString
		
		#if DEBUG
			if kDebugMode {
				tab.layer.borderColor = UIColor.red.cgColor
				tab.layer.borderWidth = 1.0
			}
		#endif
		
		return tab
	}
	
}


extension USGScrollingTabBar: UICollectionViewDelegate {
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		
		if let tab = cell as? USGScrollingTabCell {
			tab.layoutSubviews()
		}
		
		if let focusView = focusView {
			collectionView.insertSubview(focusView, at: 0)
		}
	}
	
}


extension USGScrollingTabBar: UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let tabItem = tabItems[(indexPath as NSIndexPath).row]
		
		var tabWidth = CGFloat(1)
				
		if let fixedTabWidth = fixedTabWidth {
			tabWidth = fixedTabWidth
		}
		else {
			if let selectedString = tabItem.selectedString {
				let w_a = cellClass.tabWidth(tabItem.normalString)
				let w_b = cellClass.tabWidth(selectedString)
				tabWidth = max(w_a, w_b)
			}
			else {
				tabWidth = cellClass.tabWidth(tabItem.normalString)
			}
		}
		
		return CGSize(width: tabWidth, height: collectionView.height)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		// コンテンツが少なければ（スクローラブルでなければ）中央配置になる想定
		return UIEdgeInsetsMake(0, contentMargin, 0, contentMargin)
	}
}
