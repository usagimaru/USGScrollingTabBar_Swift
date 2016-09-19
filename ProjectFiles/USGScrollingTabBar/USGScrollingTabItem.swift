//
//  USGScrollingTabCell.swift
//  ScrollingTabBar
//
//  Created by Satori Maru on 16.07.04.
//  Copyright © 2015-2016 usagimaru. All rights reserved.
//

import UIKit

class USGScrollingTabItem: NSObject {
	
	var normalString: NSAttributedString = NSAttributedString(string: "")
	var highlightedString: NSAttributedString?
	var selectedString: NSAttributedString?
	
	class func normalAttributedString(string: String, font: UIFont, color: UIColor, paragraphStyle: NSParagraphStyle) -> NSAttributedString {
		let att = [
			NSFontAttributeName : font,
			NSForegroundColorAttributeName : color,
			NSParagraphStyleAttributeName : paragraphStyle
		]
		
		let astr = NSMutableAttributedString(string: string, attributes: att)
		return astr
	}
	
	class func replaceAttributesInString(string: NSAttributedString, attributes: [String : AnyObject]) -> NSAttributedString {
		let astr = string.mutableCopy() as! NSMutableAttributedString
		astr.addAttributes(attributes, range: NSMakeRange(0, string.length))
		return astr as NSAttributedString
	}
	
}
