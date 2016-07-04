# USGScrollingTabBar_Swift

![animation](./sample.gif) ![screenshot](./screenshot.jpg)

USGScrollingTabBar は iOS 向けのスクロールタブバー部品の実装です。[Objective-C 版はこちらです。](https://github.com/usagimaru/USGScrollingTabBar)

他のスクロールビューと連動したタブのスクロールが可能です。その際、選択状態のタブは中心に留まるように調整されます。また、タブバー自体は独立してスクロールすることも可能です。タブ幅は文字列に合わせて可変的に調整されます。

次の項目がカスタマイズ可能です：

- タブバーの背景色
- タブバーの左右余白
- タブ間隔
- タブの内側余白
- フォーカスのビュー
- フォーカスの上下余白
- 減速度
- 通常、ハイライト、選択それぞれに属性付き文字列を設定可能

# 使い方

Interface Builder でカスタムビューを配置するか、プログラムコードで直接初期化してください。

```swift
var scrollingTabBar: USGScrollingTabBar(frame: CGRectMake(0,0,100,40)
view.addSubView:scrollingTabBar
```

## タブ項目を用意する

`USGScrollingTabItem` は NSAttributedString で表現されるタイトル、通常状態、ハイライト状態、選択状態の3種類を持ちます。

```swift
let font = UIFont.systemFontOfSize(13)
let color = UIColor.whiteColor()
let paragraph = NSMutableParagraphStyle()

let string = USGScrollingTabItem.normalAttributedString(str,
                                                        font: font,
                                                        color: color,
                                                        paragraphStyle: paragraph)

let tabItem = USGScrollingTabItem()
tabItem.normalString = string
```

用意したタブ項目で `USGScrollingTabBar` をリロードします。

```swift
var tabItems = Array<USGScrollingTabItem>()

scrollingTabBar.reloadTabs(tabItems)
```

## USGScrollingTabBarDelegate

タブを選択したときのイベントは `USGScrollingTabBarDelegate` で定義されるメソッドで受け取ることができます。

```swift
func didSelectTabAtIndexPath(tabBar: USGScrollingTabBar, index: Int) {
    
}
```

# License

This project is under the MIT license. See LICENSE for details.
