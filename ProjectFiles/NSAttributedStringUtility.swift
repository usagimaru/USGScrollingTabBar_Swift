//
//  NSAttributedStringUtility.swift
//  USGScrollingTabBar
//
//  Created by M.Satori on 16.09.22.
//  Copyright © 2016年 usagimaru. All rights reserved.
//

import UIKit

extension NSAttributedString {
	
	class func attributedString(_ string: String, font: UIFont, color: UIColor, paragraphStyle: NSParagraphStyle, otherAttributes: [String : Any]?) -> NSAttributedString {
		var att: [String : Any] = [
			NSFontAttributeName : font,
			NSForegroundColorAttributeName : color,
			NSParagraphStyleAttributeName : paragraphStyle
		]
		
		if let otherAttributes = otherAttributes {
			for (key, value) in otherAttributes {
				if let _ = att[key] {continue}
				att[key] = value
			}
		}
		
		let astr = NSMutableAttributedString(string: string, attributes: att)
		return astr
	}
	
	func addAttributes(attributes: [String : Any]) -> NSAttributedString {
		let astr = self.mutableCopy() as! NSMutableAttributedString
		astr.addAttributes(attributes, range: NSMakeRange(0, length))
		return astr as NSAttributedString
	}
	
}
