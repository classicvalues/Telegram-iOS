import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ComponentFlow
import SwiftSignalKit
import AnimationUI
import TelegramPresentationData

public final class MultilineText: Component {
    public let text: String
    public let font: UIFont
    public let color: UIColor

    public init(
        text: String,
        font: UIFont,
        color: UIColor
    ) {
        self.text = text
        self.font = font
        self.color = color
    }

    public static func ==(lhs: MultilineText, rhs: MultilineText) -> Bool {
        if lhs.text != rhs.text {
            return false
        }
        if lhs.font != rhs.font {
            return false
        }
        if lhs.color != rhs.color {
            return false
        }
        return true
    }

    public final class View: UIView {
        private let text: ImmediateTextNode

        init() {
            self.text = ImmediateTextNode()
            self.text.maximumNumberOfLines = 0

            super.init(frame: CGRect())

            self.addSubnode(self.text)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: MultilineText, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            self.text.attributedText = NSAttributedString(string: component.text, font: component.font, textColor: component.color, paragraphAlignment: nil)
            let textSize = self.text.updateLayout(availableSize)
            transition.setFrame(view: self.text.view, frame: CGRect(origin: CGPoint(), size: textSize))

            return textSize
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

public final class LottieAnimationComponent: Component {
    public let name: String

    public init(
        name: String
    ) {
        self.name = name
    }

    public static func ==(lhs: LottieAnimationComponent, rhs: LottieAnimationComponent) -> Bool {
        if lhs.name != rhs.name {
            return false
        }
        return true
    }

    public final class View: UIView {
        private var animationNode: AnimationNode?
        private var currentName: String?

        init() {
            super.init(frame: CGRect())
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: LottieAnimationComponent, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            if self.currentName != component.name {
                self.currentName = component.name

                if let animationNode = self.animationNode {
                    animationNode.removeFromSupernode()
                    self.animationNode = nil
                }

                let animationNode = AnimationNode(animation: component.name, colors: [:], scale: 1.0)
                self.animationNode = animationNode
                self.addSubnode(animationNode)

                animationNode.play()
            }

            if let animationNode = self.animationNode {
                let preferredSize = animationNode.preferredSize()
                return preferredSize ?? CGSize(width: 32.0, height: 32.0)
            } else {
                return CGSize()
            }
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class ScrollingTooltipAnimationComponent: Component {
    public init() {
    }

    public static func ==(lhs: ScrollingTooltipAnimationComponent, rhs: ScrollingTooltipAnimationComponent) -> Bool {
        return true
    }

    public final class View: UIView {
        private var progress: CGFloat = 0.0
        private var previousTarget: CGFloat = 0.0

        private var animator: DisplayLinkAnimator?

        init() {
            super.init(frame: CGRect())

            self.isOpaque = false
            self.backgroundColor = nil

            self.previousTarget = CGFloat.random(in: 0.0 ... 1.0)
            self.startNextAnimation()
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func startNextAnimation() {
            self.animator?.invalidate()

            let previous = self.previousTarget
            let target = CGFloat.random(in: 0.0 ... 1.0)
            self.previousTarget = target
            let animator = DisplayLinkAnimator(duration: 1.0, from: previous, to: target, update: { [weak self] value in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.progress = listViewAnimationCurveEaseInOut(value)
                strongSelf.setNeedsDisplay()
            }, completion: { [weak self] in
                Queue.mainQueue().after(0.3, {
                    guard let strongSelf = self else {
                        return
                    }

                    strongSelf.startNextAnimation()
                })
            })
            self.animator = animator
        }

        func update(component: ScrollingTooltipAnimationComponent, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            return CGSize(width: 32.0, height: 32.0)
        }

        override func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }

            let progressValue = self.progress

            let itemSize: CGFloat = 12.0
            let itemSpacing: CGFloat = 1.0
            let listItemCount: CGFloat = 100.0
            let listHeight: CGFloat = itemSize * listItemCount + itemSpacing * (listItemCount - 1)

            context.setFillColor(UIColor(white: 1.0, alpha: 0.3).cgColor)

            let offset: CGFloat = progressValue * listHeight

            var minVisibleItemIndex: Int = Int(floor(offset / (itemSize + itemSpacing)))
            while true {
                let itemY: CGFloat = CGFloat(minVisibleItemIndex) * (itemSize + itemSpacing) - offset
                if itemY >= self.bounds.height {
                    break
                }
                for i in 0 ..< 2 {
                    UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: CGFloat(i) * (itemSize + itemSpacing), y: itemY), size: CGSize(width: itemSize, height: itemSize)), cornerRadius: 2.0).fill()
                }
                minVisibleItemIndex += 1
            }

            let gradientFraction: CGFloat = 10.0 / self.bounds.height

            let colorsArray: [CGColor] = ([
                UIColor(white: 1.0, alpha: 1.0),
                UIColor(white: 1.0, alpha: 0.0),
                UIColor(white: 1.0, alpha: 0.0),
                UIColor(white: 1.0, alpha: 1.0)
            ] as [UIColor]).map(\.cgColor)
            var locations: [CGFloat] = [0.0, gradientFraction, 1.0 - gradientFraction, 1.0]
            let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: colorsArray as CFArray, locations: &locations)!
            context.setBlendMode(.destinationOut)

            context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: self.bounds.height), options: [])

            context.setBlendMode(.normal)
            context.setFillColor(UIColor.white.cgColor)

            let indicatorHeight: CGFloat = 10.0

            let indicatorMinY: CGFloat = 0.0
            let indicatorMaxY: CGFloat = self.bounds.height - indicatorHeight
            let indicatorX: CGFloat = (itemSize + itemSpacing) * 2.0
            let indicatorY = indicatorMinY * (1.0 - progress) + indicatorMaxY * progress
            UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: indicatorX, y: indicatorY), size: CGSize(width: 3.0, height: indicatorHeight)), cornerRadius: 1.5).fill()

            UIBezierPath(roundedRect: CGRect(x: indicatorX - 4.0 - 19.0, y: indicatorY + (indicatorHeight - 8.0) / 2.0, width: 19.0, height: 8.0), cornerRadius: 4.0).fill()
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

public final class TooltipComponent: Component {
    public let icon: AnyComponent<Empty>?
    public let content: AnyComponent<Empty>
    public let arrowLocation: CGRect

    public init(
        icon: AnyComponent<Empty>?,
        content: AnyComponent<Empty>,
        arrowLocation: CGRect
    ) {
        self.icon = icon
        self.content = content
        self.arrowLocation = arrowLocation
    }

    public static func ==(lhs: TooltipComponent, rhs: TooltipComponent) -> Bool {
        if lhs.icon != rhs.icon {
            return false
        }
        if lhs.content != rhs.content {
            return false
        }
        if lhs.arrowLocation != rhs.arrowLocation {
            return false
        }
        return true
    }

    public final class View: UIView {
        private let backgroundView: UIView
        private let backgroundViewMask: UIImageView
        private var icon: ComponentHostView<Empty>?
        private let content: ComponentHostView<Empty>

        private let regularMaskImage: UIImage
        private let invertedMaskImage: UIImage

        init() {
            self.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            self.backgroundViewMask = UIImageView()

            self.regularMaskImage = generateImage(CGSize(width: 42.0, height: 42.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))

                context.setFillColor(UIColor.black.cgColor)
                let _ = try? drawSvgPath(context, path: "M0,18.0252 C0,14.1279 0,12.1792 0.5358,10.609 C1.5362,7.6772 3.8388,5.3746 6.7706,4.3742 C8.3409,3.8384 10.2895,3.8384 14.1868,3.8384 L16.7927,3.8384 C18.2591,3.8384 18.9923,3.8384 19.7211,3.8207 C25.1911,3.6877 30.6172,2.8072 35.8485,1.2035 C36.5454,0.9899 37.241,0.758 38.6321,0.2943 C39.1202,0.1316 39.3643,0.0503 39.5299,0.0245 C40.8682,-0.184 42.0224,0.9702 41.8139,2.3085 C41.7881,2.4741 41.7067,2.7181 41.544,3.2062 C41.0803,4.5974 40.8485,5.293 40.6348,5.99 C39.0312,11.2213 38.1507,16.6473 38.0177,22.1173 C38,22.846 38,23.5793 38,25.0457 L38,27.6516 C38,31.5489 38,33.4975 37.4642,35.0677 C36.4638,37.9995 34.1612,40.3022 31.2294,41.3026 C29.6591,41.8384 27.7105,41.8384 23.8132,41.8384 L16,41.8384 C10.3995,41.8384 7.5992,41.8384 5.4601,40.7484 C3.5785,39.7897 2.0487,38.2599 1.0899,36.3783 C0,34.2392 0,31.4389 0,25.8384 L0,18.0252 Z ")
            })!.stretchableImage(withLeftCapWidth: 16, topCapHeight: 33)

            self.invertedMaskImage = generateImage(CGSize(width: 42.0, height: 42.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))

                context.setFillColor(UIColor.black.cgColor)
                let _ = try? drawSvgPath(context, path: "M0,18.0252 C0,14.1279 0,12.1792 0.5358,10.609 C1.5362,7.6772 3.8388,5.3746 6.7706,4.3742 C8.3409,3.8384 10.2895,3.8384 14.1868,3.8384 L16.7927,3.8384 C18.2591,3.8384 18.9923,3.8384 19.7211,3.8207 C25.1911,3.6877 30.6172,2.8072 35.8485,1.2035 C36.5454,0.9899 37.241,0.758 38.6321,0.2943 C39.1202,0.1316 39.3643,0.0503 39.5299,0.0245 C40.8682,-0.184 42.0224,0.9702 41.8139,2.3085 C41.7881,2.4741 41.7067,2.7181 41.544,3.2062 C41.0803,4.5974 40.8485,5.293 40.6348,5.99 C39.0312,11.2213 38.1507,16.6473 38.0177,22.1173 C38,22.846 38,23.5793 38,25.0457 L38,27.6516 C38,31.5489 38,33.4975 37.4642,35.0677 C36.4638,37.9995 34.1612,40.3022 31.2294,41.3026 C29.6591,41.8384 27.7105,41.8384 23.8132,41.8384 L16,41.8384 C10.3995,41.8384 7.5992,41.8384 5.4601,40.7484 C3.5785,39.7897 2.0487,38.2599 1.0899,36.3783 C0,34.2392 0,31.4389 0,25.8384 L0,18.0252 Z ")
            })!.stretchableImage(withLeftCapWidth: 16, topCapHeight: 9)

            self.backgroundViewMask.image = self.regularMaskImage

            self.content = ComponentHostView<Empty>()

            super.init(frame: CGRect())

            self.addSubview(self.backgroundView)
            self.backgroundView.mask = self.backgroundViewMask
            self.addSubview(self.content)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: TooltipComponent, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let insets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            let spacing: CGFloat = 8.0

            var iconSize: CGSize?
            if let icon = component.icon {
                let iconView: ComponentHostView<Empty>
                if let current = self.icon {
                    iconView = current
                } else {
                    iconView = ComponentHostView<Empty>()
                    self.icon = iconView
                    self.addSubview(iconView)
                }
                iconSize = iconView.update(
                    transition: transition,
                    component: icon,
                    environment: {},
                    containerSize: availableSize
                )
            } else if let icon = self.icon {
                self.icon = nil
                icon.removeFromSuperview()
            }

            var contentLeftInset: CGFloat = 0.0
            if let iconSize = iconSize {
                contentLeftInset += iconSize.width + spacing
            }

            let contentSize = self.content.update(
                transition: transition,
                component: component.content,
                environment: {},
                containerSize: CGSize(width: min(200.0, availableSize.width - contentLeftInset), height: availableSize.height)
            )

            var innerContentHeight = contentSize.height
            if let iconSize = iconSize, iconSize.height > innerContentHeight {
                innerContentHeight = iconSize.height
            }

            let combinedContentSize = CGSize(width: insets.left + insets.right + contentLeftInset + contentSize.width, height: insets.top + insets.bottom + innerContentHeight)
            var contentRect = CGRect(origin: CGPoint(x: component.arrowLocation.minX - combinedContentSize.width, y: component.arrowLocation.maxY), size: combinedContentSize)
            if contentRect.minX < 0.0 {
                contentRect.origin.x = component.arrowLocation.maxX
            }

            let maskedBackgroundFrame: CGRect

            if contentRect.maxY > availableSize.height {
                self.backgroundViewMask.image = self.invertedMaskImage
                contentRect.origin.y = component.arrowLocation.minY - contentRect.height - 4.0
                maskedBackgroundFrame = CGRect(origin: CGPoint(x: contentRect.minX, y: contentRect.minY - 4.0 + 3.0), size: CGSize(width: contentRect.width + 4.0, height: contentRect.height + 8.0))
                self.backgroundViewMask.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: maskedBackgroundFrame.size)
            } else {
                self.backgroundViewMask.image = self.regularMaskImage
                maskedBackgroundFrame = CGRect(origin: CGPoint(x: contentRect.minX, y: contentRect.minY - 4.0), size: CGSize(width: contentRect.width + 4.0, height: contentRect.height + 4.0))
                self.backgroundViewMask.frame = CGRect(origin: CGPoint(), size: maskedBackgroundFrame.size)
            }

            self.backgroundView.frame = maskedBackgroundFrame

            if let iconSize = iconSize, let icon = self.icon {
                transition.setFrame(view: icon, frame: CGRect(origin: CGPoint(x: contentRect.minX + insets.left, y: contentRect.minY + insets.top + floor((contentRect.height - insets.top - insets.bottom - iconSize.height) / 2.0)), size: iconSize))
            }
            transition.setFrame(view: self.content, frame: CGRect(origin: CGPoint(x: contentRect.minX + insets.left + contentLeftInset, y: contentRect.minY + insets.top + floor((contentRect.height - insets.top - insets.bottom - contentSize.height) / 2.0)), size: contentSize))

            return availableSize
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class RoundedRectangle: Component {
    let color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    static func ==(lhs: RoundedRectangle, rhs: RoundedRectangle) -> Bool {
        if !lhs.color.isEqual(rhs.color) {
            return false
        }
        return true
    }

    final class View: UIView {
        private let backgroundView: UIImageView

        private var currentColor: UIColor?
        private var currentDiameter: CGFloat?

        init() {
            self.backgroundView = UIImageView()

            super.init(frame: CGRect())

            self.addSubview(self.backgroundView)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: RoundedRectangle, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let shadowInset: CGFloat = 0.0
            let diameter = min(availableSize.width, availableSize.height)

            var updated = false
            if let currentColor = self.currentColor {
                if !component.color.isEqual(currentColor) {
                    updated = true
                }
            } else {
                updated = true
            }

            let diameterUpdated = self.currentDiameter != diameter
            if self.currentDiameter != diameter || updated {
                self.currentDiameter = diameter
                self.currentColor = component.color

                self.backgroundView.image = generateImage(CGSize(width: diameter + shadowInset * 2.0, height: diameter + shadowInset * 2.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))

                    context.setFillColor(component.color.cgColor)

                    context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: CGSize(width: size.width - shadowInset * 2.0, height: size.height - shadowInset * 2.0)))
                })?.stretchableImage(withLeftCapWidth: Int(diameter + shadowInset * 2.0) / 2, topCapHeight: Int(diameter + shadowInset * 2.0) / 2)
            }

            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(x: -shadowInset, y: -shadowInset), size: CGSize(width: availableSize.width + shadowInset * 2.0, height: availableSize.height + shadowInset * 2.0)))

            let _ = diameterUpdated

            return availableSize
        }
    }

    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class ShadowRoundedRectangle: Component {
    let color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    static func ==(lhs: ShadowRoundedRectangle, rhs: ShadowRoundedRectangle) -> Bool {
        if !lhs.color.isEqual(rhs.color) {
            return false
        }
        return true
    }

    final class View: UIView {
        private let backgroundView: UIImageView

        private var currentColor: UIColor?
        private var currentDiameter: CGFloat?

        init() {
            self.backgroundView = UIImageView()

            super.init(frame: CGRect())

            self.addSubview(self.backgroundView)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: ShadowRoundedRectangle, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let shadowInset: CGFloat = 10.0
            let diameter = min(availableSize.width, availableSize.height)

            var updated = false
            if let currentColor = self.currentColor {
                if !component.color.isEqual(currentColor) {
                    updated = true
                }
            } else {
                updated = true
            }

            if self.currentDiameter != diameter || updated {
                self.currentDiameter = diameter
                self.currentColor = component.color

                self.backgroundView.image = generateImage(CGSize(width: diameter + shadowInset * 2.0, height: diameter + shadowInset * 2.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))

                    context.setFillColor(component.color.cgColor)
                    context.setShadow(offset: CGSize(width: 0.0, height: -1.0), blur: 4.0, color: UIColor(white: 0.0, alpha: 0.2).cgColor)

                    context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: CGSize(width: size.width - shadowInset * 2.0, height: size.height - shadowInset * 2.0)))
                })?.stretchableImage(withLeftCapWidth: Int(diameter + shadowInset * 2.0) / 2, topCapHeight: Int(diameter + shadowInset * 2.0) / 2)
            }

            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(x: -shadowInset, y: -shadowInset), size: CGSize(width: availableSize.width + shadowInset * 2.0, height: availableSize.height + shadowInset * 2.0)))

            return availableSize
        }
    }

    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class SparseItemGridScrollingIndicatorComponent: CombinedComponent {
    let backgroundColor: UIColor
    let shadowColor: UIColor
    let foregroundColor: UIColor
    let dateString: String

    init(
        backgroundColor: UIColor,
        shadowColor: UIColor,
        foregroundColor: UIColor,
        dateString: String
    ) {
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
        self.foregroundColor = foregroundColor
        self.dateString = dateString
    }

    static func ==(lhs: SparseItemGridScrollingIndicatorComponent, rhs: SparseItemGridScrollingIndicatorComponent) -> Bool {
        if lhs.backgroundColor != rhs.backgroundColor {
            return false
        }
        if lhs.shadowColor != rhs.shadowColor {
            return false
        }
        if lhs.foregroundColor != rhs.foregroundColor {
            return false
        }
        if lhs.dateString != rhs.dateString {
            return false
        }
        return true
    }

    static var body: Body {
        let rect = Child(ShadowRoundedRectangle.self)
        let text = Child(Text.self)

        return { context in
            let text = text.update(
                component: Text(
                    text: context.component.dateString,
                    font: Font.medium(13.0),
                    color: context.component.foregroundColor
                ),
                availableSize: CGSize(width: 200.0, height: 100.0),
                transition: .immediate
            )

            let rect = rect.update(
                component: ShadowRoundedRectangle(
                    color: context.component.backgroundColor
                ),
                availableSize: CGSize(width: text.size.width + 26.0, height: 32.0),
                transition: .immediate
            )

            let rectFrame = rect.size.centered(around: CGPoint(
                x: rect.size.width / 2.0,
                y: rect.size.height / 2.0
            ))

            context.add(rect
                .position(CGPoint(x: rectFrame.midX, y: rectFrame.midY))
            )

            let textFrame = text.size.centered(in: rectFrame)
            context.add(text
                .position(CGPoint(x: textFrame.midX, y: textFrame.midY))
            )

            return rect.size
        }
    }
}

public final class SparseItemGridScrollingArea: ASDisplayNode {
    private final class DragGesture: UIGestureRecognizer {
        private let shouldBegin: (CGPoint) -> Bool
        private let began: () -> Void
        private let ended: () -> Void
        private let moved: (CGFloat) -> Void

        private var initialLocation: CGPoint?

        public init(
            shouldBegin: @escaping (CGPoint) -> Bool,
            began: @escaping () -> Void,
            ended: @escaping () -> Void,
            moved: @escaping (CGFloat) -> Void
        ) {
            self.shouldBegin = shouldBegin
            self.began = began
            self.ended = ended
            self.moved = moved

            super.init(target: nil, action: nil)
        }

        deinit {
        }

        override public func reset() {
            super.reset()

            self.initialLocation = nil
            self.initialLocation = nil
        }

        override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesBegan(touches, with: event)

            if self.numberOfTouches > 1 {
                self.state = .failed
                self.ended()
                return
            }

            if self.state == .possible {
                if let location = touches.first?.location(in: self.view) {
                    if self.shouldBegin(location) {
                        self.initialLocation = location
                        self.state = .began
                        self.began()
                    } else {
                        self.state = .failed
                    }
                } else {
                    self.state = .failed
                }
            }
        }

        override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesEnded(touches, with: event)

            self.initialLocation = nil

            if self.state == .began || self.state == .changed {
                self.ended()
                self.state = .failed
            }
        }

        override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesCancelled(touches, with: event)

            self.initialLocation = nil

            if self.state == .began || self.state == .changed {
                self.ended()
                self.state = .failed
            }
        }

        override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesMoved(touches, with: event)

            if (self.state == .began || self.state == .changed), let initialLocation = self.initialLocation, let location = touches.first?.location(in: self.view) {
                self.state = .changed
                let offset = location.y - initialLocation.y
                self.moved(offset)
            }
        }
    }

    private let dateIndicator: ComponentHostView<Empty>

    private let lineIndicator: ComponentHostView<Empty>

    private var displayedTooltip: Bool = false
    private var lineTooltip: ComponentHostView<Empty>?

    private var containerSize: CGSize?
    private var indicatorPosition: CGFloat?
    private var scrollIndicatorHeight: CGFloat?

    private var dragGesture: DragGesture?
    public private(set) var isDragging: Bool = false

    private weak var draggingScrollView: UIScrollView?
    private var scrollingInitialOffset: CGFloat?

    private var activityTimer: SwiftSignalKit.Timer?

    public var beginScrolling: (() -> UIScrollView?)?
    public var setContentOffset: ((CGPoint) -> Void)?
    public var openCurrentDate: (() -> Void)?

    private var offsetBarTimer: SwiftSignalKit.Timer?
    private var beganAtDateIndicator = false
    private let hapticFeedback = HapticFeedback()

    private struct ProjectionData {
        var minY: CGFloat
        var maxY: CGFloat
        var indicatorHeight: CGFloat
        var scrollableHeight: CGFloat
    }
    private var projectionData: ProjectionData?

    public struct DisplayTooltip {
        public var animation: String?
        public var text: String
        public var completed: () -> Void

        public init(animation: String?, text: String, completed: @escaping () -> Void) {
            self.animation = animation
            self.text = text
            self.completed = completed
        }
    }

    public var displayTooltip: DisplayTooltip?

    private var theme: PresentationTheme?

    override public init() {
        self.dateIndicator = ComponentHostView<Empty>()
        self.lineIndicator = ComponentHostView<Empty>()

        self.dateIndicator.alpha = 0.0
        self.lineIndicator.alpha = 0.0

        super.init()

        self.dateIndicator.isUserInteractionEnabled = false
        self.lineIndicator.isUserInteractionEnabled = false

        self.view.addSubview(self.dateIndicator)
        self.view.addSubview(self.lineIndicator)

        let dragGesture = DragGesture(
            shouldBegin: { [weak self] point in
                guard let strongSelf = self else {
                    return false
                }

                if strongSelf.dateIndicator.frame.contains(point) {
                    strongSelf.beganAtDateIndicator = true
                } else {
                    strongSelf.beganAtDateIndicator = false
                }

                return true
            },
            began: { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                let offsetBarTimer = SwiftSignalKit.Timer(timeout: 0.2, repeat: false, completion: {
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.performOffsetBarTimerEvent()
                }, queue: .mainQueue())
                strongSelf.offsetBarTimer?.invalidate()
                strongSelf.offsetBarTimer = offsetBarTimer
                offsetBarTimer.start()

                strongSelf.isDragging = true

                if let scrollView = strongSelf.beginScrolling?() {
                    strongSelf.draggingScrollView = scrollView
                    strongSelf.scrollingInitialOffset = scrollView.contentOffset.y
                    strongSelf.setContentOffset?(scrollView.contentOffset)
                }

                strongSelf.updateActivityTimer(isScrolling: false)
                strongSelf.dismissLineTooltip()
            },
            ended: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.draggingScrollView = nil

                if strongSelf.offsetBarTimer != nil {
                    strongSelf.offsetBarTimer?.invalidate()
                    strongSelf.offsetBarTimer = nil

                    strongSelf.openCurrentDate?()
                }

                let transition: ContainedViewLayoutTransition = .animated(duration: 0.2, curve: .easeInOut)
                transition.updateSublayerTransformOffset(layer: strongSelf.dateIndicator.layer, offset: CGPoint(x: 0.0, y: 0.0))

                strongSelf.isDragging = false

                strongSelf.updateLineIndicator(transition: transition)

                strongSelf.updateActivityTimer(isScrolling: false)
            },
            moved: { [weak self] relativeOffset in
                guard let strongSelf = self else {
                    return
                }
                guard let scrollView = strongSelf.draggingScrollView, let scrollingInitialOffset = strongSelf.scrollingInitialOffset else {
                    return
                }
                guard let projectionData = strongSelf.projectionData else {
                    return
                }

                if strongSelf.offsetBarTimer != nil {
                    strongSelf.offsetBarTimer?.invalidate()
                    strongSelf.offsetBarTimer = nil
                    strongSelf.performOffsetBarTimerEvent()
                }

                let indicatorArea = projectionData.maxY - projectionData.minY
                let scrollFraction = projectionData.scrollableHeight / indicatorArea

                var offset = scrollingInitialOffset + scrollFraction * relativeOffset
                if offset < 0.0 {
                    offset = 0.0
                }
                if offset > scrollView.contentSize.height - scrollView.bounds.height {
                    offset = scrollView.contentSize.height - scrollView.bounds.height
                }

                strongSelf.setContentOffset?(CGPoint(x: 0.0, y: offset))
                let _ = scrollView
                let _ = projectionData
            }
        )
        self.dragGesture = dragGesture

        self.view.addGestureRecognizer(dragGesture)
    }

    private func performOffsetBarTimerEvent() {
        self.hapticFeedback.impact()
        self.offsetBarTimer = nil

        let transition: ContainedViewLayoutTransition = .animated(duration: 0.1, curve: .easeInOut)
        transition.updateSublayerTransformOffset(layer: self.dateIndicator.layer, offset: CGPoint(x: -80.0, y: 0.0))
        self.updateLineIndicator(transition: transition)
    }

    func feedbackTap() {
        self.hapticFeedback.tap()
    }

    public func update(
        containerSize: CGSize,
        containerInsets: UIEdgeInsets,
        contentHeight: CGFloat,
        contentOffset: CGFloat,
        isScrolling: Bool,
        dateString: String,
        theme: PresentationTheme,
        transition: ContainedViewLayoutTransition
    ) {
        self.containerSize = containerSize
        self.theme = theme

        if self.dateIndicator.alpha.isZero {
            let transition: ContainedViewLayoutTransition = .immediate
            transition.updateSublayerTransformOffset(layer: self.dateIndicator.layer, offset: CGPoint())
        }

        if isScrolling {
            self.updateActivityTimer(isScrolling: true)
        }

        let indicatorSize = self.dateIndicator.update(
            transition: .immediate,
            component: AnyComponent(SparseItemGridScrollingIndicatorComponent(
                backgroundColor: theme.list.itemBlocksBackgroundColor,
                shadowColor: .black,
                foregroundColor: theme.list.itemPrimaryTextColor,
                dateString: dateString
            )),
            environment: {},
            containerSize: containerSize
        )

        let scrollIndicatorHeightFraction = min(1.0, max(0.0, (containerSize.height - containerInsets.top - containerInsets.bottom) / contentHeight))
        if scrollIndicatorHeightFraction >= 1.0 - .ulpOfOne {
            self.dateIndicator.isHidden = true
            self.lineIndicator.isHidden = true
        } else {
            self.dateIndicator.isHidden = false
            self.lineIndicator.isHidden = false
        }

        let indicatorVerticalInset: CGFloat = 3.0
        let topIndicatorInset: CGFloat = indicatorVerticalInset + containerInsets.top
        let bottomIndicatorInset: CGFloat = indicatorVerticalInset + containerInsets.bottom

        let scrollIndicatorHeight: CGFloat = 44.0

        let indicatorPositionFraction = min(1.0, max(0.0, contentOffset / (contentHeight - containerSize.height)))

        let indicatorTopPosition = topIndicatorInset
        let indicatorBottomPosition = containerSize.height - bottomIndicatorInset - scrollIndicatorHeight

        let dateIndicatorTopPosition = topIndicatorInset + floor(scrollIndicatorHeight - indicatorSize.height) / 2.0
        let dateIndicatorBottomPosition = containerSize.height - bottomIndicatorInset - floor(scrollIndicatorHeight - indicatorSize.height) / 2.0 - indicatorSize.height

        self.indicatorPosition = indicatorTopPosition * (1.0 - indicatorPositionFraction) + indicatorBottomPosition * indicatorPositionFraction
        self.scrollIndicatorHeight = scrollIndicatorHeight

        let dateIndicatorPosition = dateIndicatorTopPosition * (1.0 - indicatorPositionFraction) + dateIndicatorBottomPosition * indicatorPositionFraction - UIScreenPixel

        self.projectionData = ProjectionData(
            minY: dateIndicatorTopPosition,
            maxY: dateIndicatorBottomPosition,
            indicatorHeight: indicatorSize.height,
            scrollableHeight: contentHeight - containerSize.height
        )

        transition.updateFrame(view: self.dateIndicator, frame: CGRect(origin: CGPoint(x: containerSize.width - 12.0 - indicatorSize.width, y: dateIndicatorPosition), size: indicatorSize))
        if isScrolling {
            let transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .easeInOut)
            transition.updateAlpha(layer: self.dateIndicator.layer, alpha: 1.0)
            transition.updateAlpha(layer: self.lineIndicator.layer, alpha: 1.0)
        }

        self.updateLineTooltip(containerSize: containerSize)

        self.updateLineIndicator(transition: transition)

        if isScrolling {
            self.displayTooltipOnFirstScroll()
        }
    }

    private func updateLineIndicator(transition: ContainedViewLayoutTransition) {
        guard let indicatorPosition = self.indicatorPosition, let scrollIndicatorHeight = self.scrollIndicatorHeight, let theme = self.theme else {
            return
        }

        let lineIndicatorSize = CGSize(width: (self.isDragging || self.lineTooltip != nil) ? 6.0 : 3.0, height: scrollIndicatorHeight)
        let mappedTransition: Transition
        switch transition {
        case .immediate:
            mappedTransition = .immediate
        case let .animated(duration, _):
            mappedTransition = Transition(animation: .curve(duration: duration, curve: .easeInOut))
        }
        let _ = self.lineIndicator.update(
            transition: mappedTransition,
            component: AnyComponent(RoundedRectangle(
                color: theme.list.scrollIndicatorColor
            )),
            environment: {},
            containerSize: lineIndicatorSize
        )

        transition.updateFrame(view: self.lineIndicator, frame: CGRect(origin: CGPoint(x: self.bounds.size.width - 3.0 - lineIndicatorSize.width, y: indicatorPosition), size: lineIndicatorSize))
    }

    private func updateActivityTimer(isScrolling: Bool) {
        self.activityTimer?.invalidate()

        if self.isDragging {
            let transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .easeInOut)
            transition.updateAlpha(layer: self.dateIndicator.layer, alpha: 1.0)
            transition.updateAlpha(layer: self.lineIndicator.layer, alpha: 1.0)
        } else {
            self.activityTimer = SwiftSignalKit.Timer(timeout: 2.0, repeat: false, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                let transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .easeInOut)
                transition.updateAlpha(layer: strongSelf.dateIndicator.layer, alpha: 0.0)
                transition.updateAlpha(layer: strongSelf.lineIndicator.layer, alpha: 0.0)

                strongSelf.dismissLineTooltip()
            }, queue: .mainQueue())
            self.activityTimer?.start()
        }
    }

    private func dismissLineTooltip() {
        if let lineTooltip = self.lineTooltip {
            self.lineTooltip = nil
            lineTooltip.layer.animateAlpha(from: lineTooltip.alpha, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak lineTooltip] _ in
                lineTooltip?.removeFromSuperview()
            })
        }
    }

    private func displayTooltipOnFirstScroll() {
        guard let displayTooltip = self.displayTooltip else {
            return
        }
        if self.displayedTooltip {
            return
        }
        self.displayedTooltip = true

        let lineTooltip = ComponentHostView<Empty>()
        self.lineTooltip = lineTooltip
        self.view.addSubview(lineTooltip)

        if let containerSize = self.containerSize {
            self.updateLineTooltip(containerSize: containerSize)
        }

        lineTooltip.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)

        let transition: ContainedViewLayoutTransition = .immediate
        transition.updateSublayerTransformOffset(layer: self.dateIndicator.layer, offset: CGPoint(x: -3.0, y: 0.0))

        displayTooltip.completed()

        //#if DEBUG
        //#else
        Queue.mainQueue().after(5.0, { [weak self] in
            self?.dismissLineTooltip()
        })
        //#endif
    }

    private func updateLineTooltip(containerSize: CGSize) {
        guard let displayTooltip = self.displayTooltip else {
            return
        }
        guard let lineTooltip = self.lineTooltip else {
            return
        }
        let lineTooltipSize = lineTooltip.update(
            transition: .immediate,
            component: AnyComponent(TooltipComponent(
                icon: displayTooltip.animation.flatMap { animation in
                    AnyComponent(ScrollingTooltipAnimationComponent())
                },
                content: AnyComponent(MultilineText(
                    text: displayTooltip.text,
                    font: Font.regular(13.0),
                    color: .white
                )),
                arrowLocation: self.lineIndicator.frame.insetBy(dx: -3.0, dy: -8.0)
            )),
            environment: {},
            containerSize: containerSize
        )
        lineTooltip.frame = CGRect(origin: CGPoint(), size: lineTooltipSize)
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.dateIndicator.alpha <= 0.01 {
            return nil
        }
        if self.dateIndicator.frame.contains(point) {
            return super.hitTest(point, with: event)
        }

        if self.lineIndicator.alpha <= 0.01 {
            return nil
        }
        if self.lineIndicator.frame.insetBy(dx: -4.0, dy: -2.0).contains(point) {
            return super.hitTest(point, with: event)
        }

        return nil
    }

    public func hideScroller() {
        let transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .easeInOut)
        transition.updateAlpha(layer: self.dateIndicator.layer, alpha: 0.0)
        transition.updateAlpha(layer: self.lineIndicator.layer, alpha: 0.0)

        self.dismissLineTooltip()
    }
}
