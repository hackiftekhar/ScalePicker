//
//  ScalePicker.swift
//  Dmitry Klimkin
//
//  Created by Dmitry Klimkin on 12/11/15.
//  Copyright © 2016 Dmitry Klimkin. All rights reserved.
//
import Foundation
import UIKit

public typealias ValueFormatter = (CGFloat) -> NSAttributedString
public typealias ValueChangeHandler = (CGFloat) -> Void

public enum ScalePickerValuePosition {
    case Top
    case Left
}

public protocol ScalePickerDelegate {
    func didChangeScaleValue(picker: ScalePicker, value: CGFloat)
}

@IBDesignable
public class ScalePicker: UIView, SlidePickerDelegate {
    
    public var delegate: ScalePickerDelegate?
    
    public var valueChangeHandler: ValueChangeHandler = {(value: CGFloat) in
    
    }
    
    public var valuePosition = ScalePickerValuePosition.Top {
        didSet {
            layoutSubviews()
        }
    }
    
    @IBInspectable
    public var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBInspectable
    public var gradientMaskEnabled: Bool = false {
        didSet {
            picker.gradientMaskEnabled = gradientMaskEnabled
        }
    }
    
    @IBInspectable
    public var invertValues: Bool = false {
        didSet {
            picker.invertValues = invertValues
        }
    }
    
    @IBInspectable
    public var trackProgress: Bool = false {
        didSet {
            progressView.alpha = trackProgress ? 1.0 : 0.0
        }
    }
    
    @IBInspectable
    public var invertProgress: Bool = false {
        didSet {
            layoutProgressView(progress: currentProgress)
        }
    }
    
    @IBInspectable
    public var fillSides: Bool = false {
        didSet {
            picker.fillSides = fillSides
        }
    }
    
    @IBInspectable
    public var elasticCurrentValue: Bool = false

    @IBInspectable
    public var highlightCenterTick: Bool = true {
        didSet {
            picker.highlightCenterTick = highlightCenterTick
        }
    }

    @IBInspectable
    public var allTicksWithSameSize: Bool = false {
        didSet {
            picker.allTicksWithSameSize = allTicksWithSameSize
        }
    }
    
    @IBInspectable
    public var showCurrentValue: Bool = false {
        didSet {
            valueLabel.alpha = showCurrentValue ? 1.0 : 0.0
            
            showTickLabels = !showTickLabels
            showTickLabels = !showTickLabels
        }
    }
    
    @IBInspectable
    public var blockedUI: Bool = false {
        didSet {
            picker.blockedUI = blockedUI
        }
    }
    
    @IBInspectable
    public var numberOfTicksBetweenValues: UInt = 4 {
        didSet {
            picker.numberOfTicksBetweenValues = numberOfTicksBetweenValues
            reset()
        }
    }
    
    @IBInspectable
    public var minValue: CGFloat = -3.0 {
        didSet {
            picker.minValue = minValue
            reset()
        }
    }
    
    @IBInspectable
    public var maxValue: CGFloat = 3.0 {
        didSet {
            picker.maxValue = maxValue
            reset()
        }
    }
    
    @IBInspectable
    public var spaceBetweenTicks: CGFloat = 10.0 {
        didSet {
            picker.spaceBetweenTicks = spaceBetweenTicks
            reset()
        }
    }
    
    @IBInspectable
    public var centerViewWithLabelsYOffset: CGFloat = 15.0 {
        didSet {
            updateCenterViewOffset()
        }
    }

    @IBInspectable
    public var centerViewWithoutLabelsYOffset: CGFloat = 15.0 {
        didSet {
            updateCenterViewOffset()
        }
    }
    
    @IBInspectable
    public var pickerOffset: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }
    
    @IBInspectable
    public var tickColor: UIColor = .white {
        didSet {
            picker.tickColor = tickColor
            centerImageView.image = centerArrowImage?.tintImage(color: tickColor)
            titleLabel.textColor = tickColor
        }
    }

    @IBInspectable
    public var progressColor: UIColor = .white {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }
    
    @IBInspectable
    public var progressViewSize: CGFloat = 3.0 {
        didSet {
            progressView.frame = CGRect(x: 0, y: 0, width: progressViewSize, height: progressViewSize)
            progressView.layer.cornerRadius = progressViewSize / 2
            
            layoutProgressView(progress: currentProgress)
        }
    }
    
    @IBInspectable
    public var centerArrowImage: UIImage? {
        didSet {
            centerImageView.image = centerArrowImage
            reset()
        }
    }
    
    @IBInspectable
    public var showTickLabels: Bool = true {
        didSet {
            picker.showTickLabels = showTickLabels
            
            updateCenterViewOffset()
            
            layoutSubviews()
        }
    }
    
    @IBInspectable
    public var snapEnabled: Bool = false {
        didSet {
            picker.snapEnabled = snapEnabled
        }
    }
    
    @IBInspectable
    public var showPlusForPositiveValues: Bool = true {
        didSet {
            picker.showPlusForPositiveValues = showPlusForPositiveValues
        }
    }
    
    @IBInspectable
    public var fireValuesOnScrollEnabled: Bool = true {
        didSet {
            picker.fireValuesOnScrollEnabled = fireValuesOnScrollEnabled
        }
    }
    
    @IBInspectable
    public var bounces: Bool = false {
        didSet {
            picker.bounces = bounces
        }
    }
    
    @IBInspectable
    public var sidePadding: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }
    
    public var currentTransform: CGAffineTransform = .identity {
        didSet {
            applyCurrentTransform()
        }
    }
    
    public func applyCurrentTransform() {
        picker.currentTransform = currentTransform
        
        if valuePosition == .Left {
            valueLabel.transform = currentTransform
        }
    }
    
    public var values: [CGFloat]? {
        didSet {
            guard let values = values, values.count > 1 else { return; }
            
            picker.values = values
            
            maxValue = values[values.count - 1]
            minValue = values[0]
            initialValue = values[0]
        }
    }
    
    public var valueFormatter: ValueFormatter = {(value: CGFloat) -> NSAttributedString in
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.white,
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
        
        return NSMutableAttributedString(string: value.format(f: ".2"), attributes: attrs)
    }
    
    public var rightView: UIView? {
        willSet(newRightView) {
            if let view = rightView {
                view.removeFromSuperview()
            }
        }
        
        didSet {
            if let view = rightView {
                addSubview(view)
            }

            layoutSubviews()
        }
    }

    public var leftView: UIView? {
        willSet(newLeftView) {
            if let view = leftView {
                view.removeFromSuperview()
            }
        }
        
        didSet {
            if let view = leftView {
                addSubview(view)
            }
            
            layoutSubviews()
        }
    }
    
    private let centerImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    private let centerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private var currentProgress: CGFloat = 0.5
    private var progressView = UIView()
    private var initialValue: CGFloat = 0.0
    private var picker: SlidePicker!
    private var shouldUpdatePicker: Bool = true
    private var notifyOnChanges: Bool = true
    private var timer: Timer?

    public var currentValue: CGFloat = 0.0 {
        didSet {
            if shouldUpdatePicker {
                picker.scrollToValue(value: currentValue, animated: true)                
            }
            
            valueLabel.attributedText = valueFormatter(currentValue)
            layoutValueLabel()
            updateProgressAsync()
        }
    }
    
    public func updateCurrentValue(value: CGFloat, animated: Bool, notify: Bool = false) {
        shouldUpdatePicker = false
        notifyOnChanges = false
        
        picker.scrollToValue(value: value, animated: animated, reload: false, complete: { [unowned self] in
            self.currentValue = value
            
            if notify {
                self.delegate?.didChangeScaleValue(picker: self, value: value)
                self.valueChangeHandler(value)
            }
            
            self.scheduleTimer()
        })
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ScalePicker.onTimer), userInfo: nil, repeats: false)
    }
    
    @objc func onTimer() {
        self.shouldUpdatePicker = true
        self.notifyOnChanges = true
    }
    
    private func updateProgressAsync() {
        let popTime = DispatchTime.now() + .seconds(1)
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            self.picker.updateCurrentProgress()
            
            if self.trackProgress {
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
                    
                    self.progressView.alpha = 1.0
                    }, completion: nil)
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    public func commonInit() {
        isUserInteractionEnabled = true
        
        titleLabel.textColor = tickColor
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 13.0)
        
        addSubview(titleLabel)
        
        valueLabel.textColor = tickColor
        valueLabel.textAlignment = .center
        valueLabel.font = UIFont.systemFont(ofSize: 13.0)
        
        addSubview(valueLabel)
        
        centerImageView.contentMode = .center
        centerImageView.center = CGPoint(x: centerView.frame.size.width / 2, y: centerView.frame.size.height / 2 + 5)
        
        centerView.addSubview(centerImageView)
        
        picker = SlidePicker(frame: CGRect(x: sidePadding, y: 0, width: frame.size.width - sidePadding * 2, height: frame.size.height))
        
        picker.numberOfTicksBetweenValues = numberOfTicksBetweenValues
        picker.minValue = minValue
        picker.maxValue = maxValue
        picker.delegate = self
        picker.snapEnabled = snapEnabled
        picker.showTickLabels = showTickLabels
        picker.highlightCenterTick = highlightCenterTick
        picker.bounces = bounces
        picker.tickColor = tickColor
        picker.centerView = centerView
        picker.spaceBetweenTicks = spaceBetweenTicks
        
        updateCenterViewOffset()
        
        addSubview(picker)
        
        progressView.frame = CGRect(x: 0, y: 0, width: progressViewSize, height: progressViewSize)
        progressView.backgroundColor = UIColor.white
        progressView.alpha = 0.0
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = progressViewSize / 2

        addSubview(progressView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        
        tapGesture.numberOfTapsRequired = 2
        
        addGestureRecognizer(tapGesture)
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        layoutSubviews()
        reset()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        picker.frame = CGRect(x: sidePadding, y: pickerOffset,
                              width: frame.size.width - sidePadding * 2, height: frame.size.height)
        picker.layoutSubviews()
        
        let xOffset = gradientMaskEnabled ? picker.frame.size.width * 0.05 : 0.0

        if let view = rightView {
            view.center = CGPoint(x: frame.size.width - xOffset - sidePadding / 2, y: picker.center.y + 5)
        }
        
        if let view = leftView {
            if valuePosition == .Left {
                view.center = CGPoint(x: xOffset + sidePadding / 2, y: ((frame.size.height / 2) - view.frame.height / 4) + 5)
            } else {
                view.center = CGPoint(x: xOffset + sidePadding / 2, y: picker.center.y + 5)
            }
        }

        titleLabel.frame = CGRect(x: xOffset, y: 5, width: sidePadding, height: frame.size.height)

        if valuePosition == .Top {
            valueLabel.frame = CGRect(x: sidePadding, y: 5,
                                      width: frame.width - sidePadding * 2, height: frame.size.height / 4.0)
        } else {
            layoutValueLabel()
        }
    }
    
    @objc func onDoubleTap(recognizer: UITapGestureRecognizer) {
        updateCurrentValue(value: initialValue, animated: true, notify: true)
    }
    
    public func reset(notify: Bool = false) {
        updateCurrentValue(value: initialValue, animated: false, notify: notify)
    }
    
    public func increaseValue() {
        picker.increaseValue()
    }
    
    public func decreaseValue() {
        picker.decreaseValue()
    }
    
    public func setInitialCurrentValue(value: CGFloat) {
        shouldUpdatePicker = false
        
        currentValue = value
        initialValue = value
        
        picker.scrollToValue(value: value, animated: false)

        shouldUpdatePicker = true
        
        progressView.alpha = 0.0
    }
    
    public func didSelectValue(value: CGFloat) {
        shouldUpdatePicker = false
        
        if notifyOnChanges && (value != currentValue) {
            currentValue = value
            delegate?.didChangeScaleValue(picker: self, value: value)
            valueChangeHandler(value)
        }
        
        shouldUpdatePicker = true
    }

    
    public func didChangeContentOffset(offset: CGFloat, progress: CGFloat) {
        layoutProgressView(progress: progress)

        guard elasticCurrentValue else { return }
        
        let minScale: CGFloat    = 0.0
        let maxScale: CGFloat    = 0.25
        let maxOffset: CGFloat   = 50.0
        var offsetShift: CGFloat = 0.0
        var scaleShift: CGFloat  = 1.0
        var offsetValue          = offset

        if offset < 0 {
            scaleShift = -maxScale
            offsetShift = 50.0
            offsetValue = offset + offsetShift
        }

        var value = min(maxScale, max(minScale, offsetValue * (maxScale / maxOffset)))
        
        value += scaleShift
        
        if offset < 0 {
            if value < 0 {
                if invertValues {
                    value = abs(value) + 1
                } else {
                    value += 1
                }
            }
        } else {
            if invertValues {
                value = 1 - (value - scaleShift)
            }
        }
                
        valueLabel.transform = currentTransform.scaledBy(x: value, y: value)
    }
    
    private func updateCenterViewOffset() {
        picker.centerViewOffsetY = showTickLabels ? centerViewWithLabelsYOffset : centerViewWithoutLabelsYOffset
    }
    
    private func layoutProgressView(progress: CGFloat) {
        currentProgress = progress
        
        let updatedProgress = invertProgress ? 1.0 - progress : progress
        let xOffset = gradientMaskEnabled ? picker.frame.origin.x + (picker.frame.size.width * 0.1) : picker.frame.origin.x
        let progressWidth = gradientMaskEnabled ? picker.frame.size.width * 0.8 : picker.frame.size.width
        let scaledValue = progressWidth * updatedProgress
        var yOffset = pickerOffset + 4 + frame.size.height / 3

        if title.isEmpty && valuePosition == .Left  {
            yOffset -= 6
        }
        
        progressView.center = CGPoint(x: xOffset + scaledValue, y: yOffset)
    }
    
    private func layoutValueLabel() {
        let text = valueLabel.attributedText
        
        guard let textValue = text else { return }

        let textWidth = valueWidth(text: textValue)
        var signOffset: CGFloat = 0
        
        if textValue.string.contains("+") || textValue.string.contains("-") {
            signOffset = 2
        }
        
        let xOffset = gradientMaskEnabled ? picker.frame.size.width * 0.05 : 0.0
        
        if valuePosition == .Left {
            if let view = leftView {
                valueLabel.frame = CGRect(x: view.center.x - signOffset - textWidth / 2, y: 5 + frame.size.height / 2, width: textWidth, height: 16)
            } else {
                valueLabel.frame = CGRect(x: sidePadding, y: 5, width: textWidth, height: frame.size.height)
                valueLabel.center = CGPoint(x: xOffset + sidePadding / 2, y: frame.size.height / 2 + 5)
            }
        } else {
            valueLabel.frame = CGRect(x: 0, y: 5, width: textWidth, height: frame.size.height - 10)
            valueLabel.center = CGPoint(x: xOffset + sidePadding / 2, y: frame.size.height / 2 - 5)
        }
    }
    
    private func valueWidth(text: NSAttributedString) -> CGFloat {
        let rect = text.boundingRect(with: CGSize(width: 1024, height: frame.size.width), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return rect.width + 10
    }
}

private extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

private extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

private extension CGFloat {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
