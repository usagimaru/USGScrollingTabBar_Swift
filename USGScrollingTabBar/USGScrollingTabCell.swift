//
//  USGScrollingTabCell.swift
//  ScrollingTabBar
//
//  Created by Satori Maru on 16.07.04.
//  Copyright © 2015-2016 usagimaru. All rights reserved.
//

import UIKit

class USGScrollingTabCell: UICollectionViewCell {
	
	var index: Int = 0
	
	var normalString: NSAttributedString?
	var highlightedString: NSAttributedString?
	var selectedString: NSAttributedString?
	
	weak var collectionView: UICollectionView?
	weak var target: AnyObject?
	var buttonAction: Selector?
	
	override var highlighted: Bool {
		didSet {
			setNeedsLayout()
		}
	}
	
	override var selected: Bool {
		didSet {
			setNeedsLayout()
		}
	}
	
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var leftConstraint: NSLayoutConstraint!
	@IBOutlet weak var rightConstraint: NSLayoutConstraint!
	@IBOutlet weak var button: UIButton!
	
	private static var padding: UIEdgeInsets = UIEdgeInsetsZero
	
	
	override class func initialize() {
		super.initialize()
		
		let nib = self.nib()
		let cell = nib.instantiateWithOwner(nil, options: nil).first as! USGScrollingTabCell
		padding = UIEdgeInsetsMake(0, cell.leftConstraint.constant, 0, cell.rightConstraint.constant)
	}
	
	
	class func nib() -> UINib {
		return UINib(nibName: "USGScrollingTabCell", bundle: nil)
	}
	
	class func tabWidth(string: NSAttributedString, tabInset: CGFloat) -> CGFloat {
		// 文字列の必要な幅を計算
		let bounds = string.boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max),
		                                         options: [.UsesLineFragmentOrigin, .UsesFontLeading, .TruncatesLastVisibleLine],
		                                         context: nil)
		
		// 余白をたす。繰上げしないと収まりきらない
		let w = max(ceil(bounds.size.width + padding.left + padding.right) + tabInset * 2.0, 1.0)
		
		return w
	}
	
	
	func setNormalStringWithoutAnimation(string: NSAttributedString) {
		normalString = string
		label.attributedText = string
	}
	
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		guard let collectionView = collectionView else {
			return
		}
		
		guard let indexPath = collectionView.indexPathsForSelectedItems()!.first else {
			return
		}
		
		var str: NSAttributedString? = nil
		var duration: NSTimeInterval = 0.2
		
		if highlighted {
			str = highlightedString
			duration = 0.0
		}
		else if selected == true && index == indexPath.row {
			str = selectedString
		}
		else if indexPath.row != index {
			str = normalString
		}
		
		if let str = str {
			UIView.transitionWithView(label,
			                          duration: duration,
			                          options: [.TransitionCrossDissolve, .BeginFromCurrentState],
			                          animations: { 
										self.label.attributedText = str },
			                          completion: nil)
		}
	}
	
	
	@IBAction private func buttonAction(sender: AnyObject) {
		if let buttonAction = buttonAction {
			target?.performSelector(buttonAction, withObject: self)
		}
	}
}
