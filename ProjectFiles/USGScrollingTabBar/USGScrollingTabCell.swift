//
//  USGScrollingTabCell.swift
//  ScrollingTabBar
//
//  Created by Satori Maru on 16.07.04.
//  Copyright © 2015-2017 usagimaru. All rights reserved.
//

import UIKit

class USGScrollingTabCell: UICollectionViewCell {
	
	var index: Int = 0
	
	var normalString: NSAttributedString?
	var highlightedString: NSAttributedString?
	var selectedString: NSAttributedString?
	
	weak var collectionView: UICollectionView?
	weak var target: NSObjectProtocol?
	var buttonAction: Selector?
	
	override var isHighlighted: Bool {
		didSet {
			setNeedsLayout()
		}
	}
	
	override var isSelected: Bool {
		didSet {
			setNeedsLayout()
		}
	}
	
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var leftConstraint: NSLayoutConstraint!
	@IBOutlet weak var rightConstraint: NSLayoutConstraint!
	@IBOutlet weak var button: UIButton!
	
	fileprivate static var padding: UIEdgeInsets = UIEdgeInsets.zero
	
	
	override class func initialize() {
		super.initialize()
		
		if let cell = self.nib().instantiate(withOwner: nil, options: nil).first as? USGScrollingTabCell {
			padding = UIEdgeInsetsMake(0, cell.leftConstraint.constant, 0, cell.rightConstraint.constant)
		}
	}
	
	
	class func nib() -> UINib {
		return UINib(nibName: "\(self)", bundle: nil)
	}
	
	class func tabWidth(_ string: NSAttributedString) -> CGFloat {
		// 文字列の必要な幅を計算
		let bounds = string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
		                                         options: [.usesLineFragmentOrigin],
		                                         context: nil)
		
		// 余白をたす。繰上げしないと収まりきらない
		let w = max(ceil(bounds.size.width + padding.left + padding.right), 1.0)
		
		return w
	}
	
	
	func setNormalStringWithoutAnimation(_ string: NSAttributedString) {
		normalString = string
		label.attributedText = string
	}
	
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		guard let collectionView = collectionView else {
			return
		}
		
		guard let indexPath = collectionView.indexPathsForSelectedItems!.first else {
			return
		}
		
		// TODO: fix animation
		setAttributedText(false, indexPath: indexPath)
	}
	
	fileprivate func setAttributedText(_ animated: Bool, indexPath: IndexPath) {
		var str: NSAttributedString? = nil
		
		if isHighlighted {
			str = highlightedString
		}
		else if isSelected == true && index == (indexPath as IndexPath).row {
			str = selectedString
		}
		else if (indexPath as IndexPath).row != index {
			str = normalString
		}
		
		if let str = str {
			label.attributedText = str
			let duration: TimeInterval = isHighlighted == true && animated == true ? 0.2 : 0.0
			UIView.transition(with: label,
			                          duration: duration,
			                          options: [.transitionCrossDissolve, .beginFromCurrentState],
			                          animations: {
										self.label.attributedText = str },
			                          completion: nil)
		}
	}
	
	
	@IBAction fileprivate func buttonAction(_ sender: AnyObject) {
		if let buttonAction = buttonAction {
			let _ = target?.perform(buttonAction, with: self)
		}
	}
}
