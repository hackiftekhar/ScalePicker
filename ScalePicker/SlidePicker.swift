//
//  SlidePicker.swift
//  Dmitry Klimkin
//
//  Created by Dmitry Klimkin on 12/11/15.
//  Copyright © 2016 Dmitry Klimkin. All rights reserved.
//

import Foundation
import UIKit

public protocol SlidePickerDelegate {
    func didSelectValue(value: CGFloat)
    func didChangeContentOffset(offset: CGFloat, progress: CGFloat)
}

public typealias CompleteHandler = (()->Void)

@IBDesignable
public class SlidePicker: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public var delegate: SlidePickerDelegate?
    
    @IBInspectable
    public var gradientMaskEnabled: Bool = false {
        didSet {
            layer.mask = gradientMaskEnabled ? maskLayer : nil
            
            layoutSubviews()
        }
    }
    
    @IBInspectable
    public var invertValues: Bool = false {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var fillSides: Bool = false {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var allTicksWithSameSize: Bool = false {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var blockedUI: Bool = false {
        didSet {
            uiBlockView.removeFromSuperview()
            
            if blockedUI {
                addSubview(uiBlockView)
            }
            
            layoutSubviews()
        }
    }
    
    @IBInspectable
    public var showPlusForPositiveValues: Bool = true {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var snapEnabled: Bool = true
    
    @IBInspectable
    public var fireValuesOnScrollEnabled: Bool = true
    
    @IBInspectable
    public var showTickLabels: Bool = true {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var highlightCenterTick: Bool = true {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var bounces: Bool = false {
        didSet {
            collectionView.bounces = bounces
        }
    }
    
    @IBInspectable
    public var spaceBetweenTicks: CGFloat = 20.0 {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var centerViewOffsetY: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }

    private let cellId = "collectionViewCellId"

    private var flowLayout = SlidePickerFlowLayout()
    private var collectionView: UICollectionView!
    private var tickValue: CGFloat = 1.0
    
    private var maskLayer: CALayer!
    private var maskLeftLayer: CAGradientLayer!
    private var maskRightLayer: CAGradientLayer!
    private var uiBlockView: UIView!
    private var reloadTimer: Timer?

    public var centerView: UIView? {
        didSet {
            if let centerView = centerView {
                centerViewOffsetY = 0.0
                
                addSubview(centerView)
            }
        }
    }
    
    public var values: [CGFloat]? {
        didSet {
            guard let values = values, values.count > 1 else { return; }
            
            updateSectionsCount()

            requestCollectionViewReloading()
        }
    }

    @IBInspectable
    public var tickColor: UIColor = UIColor.white {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    private var sectionsCount: Int = 0 {
        didSet {
            requestCollectionViewReloading()
        }
    }
    
    @IBInspectable
    public var minValue: CGFloat = 0.0 {
        didSet {
            updateSectionsCount()
        }
    }
    
    @IBInspectable
    public var maxValue: CGFloat = 0.0 {
        didSet {
            updateSectionsCount()
        }
    }
    
    private func updateSectionsCount() {
        guard minValue < maxValue else {
            return
        }
        
        if let values = values {
            var sections = (values.count / Int(numberOfTicksBetweenValues + 1)) + 2
            
            if values.count % Int(numberOfTicksBetweenValues + 1) > 0 {
                sections += 1
            }
            
            sectionsCount = sections
        } else {
            let items = maxValue - minValue + 1.0
            
            if items > 1 {
                sectionsCount = Int(items) + 2
            } else {
                sectionsCount = 0
            }
        }
    }
    
    @IBInspectable
    public var numberOfTicksBetweenValues: UInt = 2 {
        didSet {
            tickValue = 1.0 / CGFloat(numberOfTicksBetweenValues + 1)
            
            updateSectionsCount()
        }
    }
    
    public var currentTransform: CGAffineTransform = .identity {
        didSet {
            requestCollectionViewReloading()
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
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0

        collectionView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.allowsSelection = false
        collectionView.delaysContentTouches = true

        collectionView.register(SlidePickerCell.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(collectionView)
        
        maskLayer = CALayer()
        
        maskLayer.frame = .zero
        maskLayer.backgroundColor = UIColor.clear.cgColor
        
        maskLeftLayer = CAGradientLayer()

        maskLeftLayer.frame = maskLayer.bounds
        maskLeftLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.cgColor]
        maskLeftLayer.startPoint = CGPoint(x: 0.1, y: 0.0)
        maskLeftLayer.endPoint = CGPoint(x: 0.9, y: 0.0)

        maskRightLayer = CAGradientLayer()
        
        maskRightLayer.frame = maskLayer.bounds
        maskRightLayer.colors = [UIColor.black.cgColor, UIColor.black.withAlphaComponent(0.0).cgColor]
        maskRightLayer.startPoint = CGPoint(x: 0.1, y: 0.0)
        maskRightLayer.endPoint = CGPoint(x: 0.9, y: 0.0)

        maskLayer.addSublayer(maskLeftLayer)
        maskLayer.addSublayer(maskRightLayer)
        
        uiBlockView = UIView(frame: self.bounds)
    }
   
    private func requestCollectionViewReloading() {
        reloadTimer?.invalidate()
        
        reloadTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(SlidePicker.reloadCollectionView), userInfo: nil, repeats: false)
    }
    
    @objc func reloadCollectionView() {
        reloadTimer?.invalidate()

        collectionView.reloadData()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.frame = bounds
        
        centerView?.center = CGPoint(x: frame.size.width / 2,
                                     y: centerViewOffsetY + (frame.size.height / 2) - 2)
        if gradientMaskEnabled {
            let gradientMaskWidth = frame.size.width / 2
            
            maskLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            maskLeftLayer.frame = CGRect(x: 0, y: 0, width: gradientMaskWidth, height: frame.size.height)
            maskRightLayer.frame = CGRect(x: frame.size.width - gradientMaskWidth, y: 0, width: gradientMaskWidth, height: frame.size.height)
        } else {
            maskLayer.frame = .zero
            maskLeftLayer.frame = maskLayer.bounds
            maskRightLayer.frame = maskLayer.bounds
        }
        
        uiBlockView.frame = bounds
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        layoutSubviews()
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard sectionsCount > 2 else {
            return .zero
        }
        
        let regularCellSize = CGSize(width: spaceBetweenTicks, height: bounds.height)
        
        if (indexPath.section == 0) || (indexPath.section == (sectionsCount - 1)) {
            if fillSides {
                let sideItems = (Int(frame.size.width / spaceBetweenTicks) + 2) / 2

                if (indexPath.section == 0 && indexPath.row == 0) ||
                    (indexPath.section == sectionsCount - 1 && indexPath.row == sideItems - 1)  {
                    
                    return CGSize(width: (spaceBetweenTicks / 2) - SlidePickerCell.strokeWidth, height: bounds.height)
                } else {
                    return regularCellSize
                }
            } else {
                return CGSize(width: (bounds.width / 2) - (spaceBetweenTicks / 2), height: bounds.height)
            }
        }
        
        return regularCellSize
    }
    

    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard sectionsCount > 2 else {
            return 0
        }
        
        if (section == 0) || (section >= (sectionsCount - 1)) {
            let sideItems = Int(frame.size.width / spaceBetweenTicks) + 2
            
            return fillSides ? sideItems / 2 : 1
        } else {
            if let values = values {
                let elements = (section - 1) * Int(numberOfTicksBetweenValues + 1)
                let rows = values.count - elements
                
                if rows > 0 {
                    return min(rows, Int(numberOfTicksBetweenValues + 1))
                } else {
                    return 0
                }
            } else {
                if section >= (sectionsCount - 2) {
                    return 1
                } else {
                    return Int(numberOfTicksBetweenValues) + 1
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath as IndexPath) as! SlidePickerCell
           
           cell.indexPath = indexPath as NSIndexPath
           cell.tickColor = tickColor
           cell.showTickLabels = showTickLabels
           cell.highlightTick = false
           cell.currentTransform = currentTransform
           cell.showPlusForPositiveValues = showPlusForPositiveValues

           if indexPath.section == 0 {
               cell.updateValue(value: invertValues ? CGFloat.greatestFiniteMagnitude : CGFloat.leastNormalMagnitude, type: fillSides ? .BigStroke : .Empty)
           } else if indexPath.section == sectionsCount - 1 {
               cell.updateValue(value: invertValues ? CGFloat.leastNormalMagnitude : CGFloat.greatestFiniteMagnitude, type: fillSides ? .BigStroke : .Empty)
           } else {
               if let values = values {
                   cell.highlightTick = false
                   
                   let index = (indexPath.section - 1) * Int(numberOfTicksBetweenValues + 1) + indexPath.row
                   let currentValue = values[index]
                   
                   cell.updateValue(value: currentValue, type: allTicksWithSameSize || indexPath.row == 0 ? .BigStroke : .SmallStroke)
               } else {
                   let currentValue = invertValues ? maxValue - CGFloat(indexPath.section - 1) : minValue + CGFloat(indexPath.section - 1)

                   if indexPath.row == 0 {
                       if highlightCenterTick {
                           cell.highlightTick = (currentValue == ((maxValue - minValue) * 0.5 + minValue))
                       } else {
                           cell.highlightTick = false
                       }
                       
                       cell.updateValue(value: currentValue, type: .BigStroke)
                   } else {
                       let value = invertValues ? currentValue - tickValue * CGFloat(indexPath.row) : currentValue + tickValue * CGFloat(indexPath.row)
                       cell.showTickLabels = allTicksWithSameSize ? false : showTickLabels
                       cell.updateValue(value: value, type: allTicksWithSameSize ? .BigStroke : .SmallStroke)
                   }
               }
           }
           
           return cell
       }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return sectionsCount
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedValue(tryToSnap: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        updateSelectedValue(tryToSnap: true)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedValue(tryToSnap: false)
        updateCurrentProgress()
    }
    
    public func updateCurrentProgress() {
        let offset = collectionView.contentOffset.x
        let contentSize = collectionView.contentSize.width
        
        if offset <= 0 {
            delegate?.didChangeContentOffset(offset: offset, progress: 0)
        } else if offset >= contentSize - frame.size.width {
            delegate?.didChangeContentOffset(offset: offset - contentSize + frame.size.width, progress: 1)
        } else {
            delegate?.didChangeContentOffset(offset: 0, progress: offset / (collectionView.contentSize.width - frame.size.width))
        }
    }
    
    public func scrollToValue(value: CGFloat, animated: Bool, reload: Bool = true, complete: CompleteHandler? = nil) {
        var indexPath: IndexPath?
        
        guard sectionsCount > 0 else {
            return
        }
        
        if let values = values {
            var valueIndex = 0
            
            for index in 0..<values.count {
                if value == values[index] {
                    valueIndex = index
                    break
                }
            }
            
            let section = (valueIndex / Int(numberOfTicksBetweenValues + 1))
            let row = valueIndex - (section * Int(numberOfTicksBetweenValues + 1))

            indexPath = IndexPath(row: row, section: section + 1)
            
            let cell = self.collectionView(collectionView, cellForItemAt: indexPath! as IndexPath) as? SlidePickerCell
            
            if let cell = cell, cell.value == value {
                delegate?.didSelectValue(value: cell.value)
                collectionView.scrollToItem(at: indexPath! as IndexPath, at: .centeredHorizontally, animated: animated)
            }
        } else {
            if snapEnabled {
                for i in 1..<sectionsCount {
                    let itemsCount = self.collectionView(collectionView, numberOfItemsInSection: i)
                    
                    for j in 0..<itemsCount {
                        indexPath = IndexPath(row: j, section: i)
                        
                        let cell = self.collectionView(collectionView, cellForItemAt: indexPath! as IndexPath) as? SlidePickerCell
                        
                        if let cell = cell, cell.value == value {
                            delegate?.didSelectValue(value: cell.value)
                            collectionView.scrollToItem(at: indexPath! as IndexPath, at: .centeredHorizontally, animated: animated)
                            
                            break
                        }
                    }
                }
            } else {
                collectionView.reloadData()
                let popTime = DispatchTime.now() + .seconds(1)
                
                DispatchQueue.main.asyncAfter(deadline: popTime) {
                    let absoluteValue = value - self.minValue
                    let percent = absoluteValue / (self.maxValue - self.minValue)
                    let absolutePercent = self.invertValues ? (1.0 - percent) : percent
                    let offsetX = absolutePercent * (self.collectionView.contentSize.width - self.bounds.width)
                    
                    self.collectionView.contentOffset = CGPoint(x: offsetX, y: self.collectionView.contentOffset.y)
                }
            }
        }
    }
    
    public func increaseValue() {
        let point = CGPoint(x: collectionView.center.x + collectionView.contentOffset.x + spaceBetweenTicks * 2 / 3,
                            y: collectionView.center.y + collectionView.contentOffset.y)
        
        scrollToNearestCellAtPoint(point: point)
    }
    
    public func decreaseValue() {
        let point = CGPoint(x: collectionView.center.x + collectionView.contentOffset.x - spaceBetweenTicks * 2 / 3,
                            y: collectionView.center.y + collectionView.contentOffset.y)
        
        scrollToNearestCellAtPoint(point: point)
    }
    
    private func updateSelectedValue(tryToSnap: Bool) {
        if snapEnabled {
            let initialPinchPoint = CGPoint(x: collectionView.center.x + collectionView.contentOffset.x,
                                            y: collectionView.center.y + collectionView.contentOffset.y)
            
            scrollToNearestCellAtPoint(point: initialPinchPoint, skipScroll: fireValuesOnScrollEnabled && !tryToSnap)
        } else {
            let percent = collectionView.contentOffset.x / (collectionView.contentSize.width - bounds.width)
            let absoluteValue = percent * (maxValue - minValue)
            let currentValue = invertValues ? min(max(maxValue - absoluteValue, minValue), maxValue) : max(min(absoluteValue + minValue, maxValue), minValue)
            
            delegate?.didSelectValue(value: currentValue)
        }
    }
    
    private func scrollToNearestCellAtPoint(point: CGPoint, skipScroll: Bool = false) {
        var centerCell: SlidePickerCell?
        
        let indexPath = collectionView.indexPathForItem(at: point)
        
        if let iPath = indexPath {
            if (iPath.section == 0) || (iPath.section == (sectionsCount - 1)) {
                return
            }
            
            centerCell = self.collectionView(collectionView, cellForItemAt: iPath) as? SlidePickerCell
        }
        
        guard let cell = centerCell else {
            return
        }
        
        delegate?.didSelectValue(value: cell.value)
        
        if !skipScroll {
            collectionView.scrollToItem(at: indexPath!, at: .centeredHorizontally, animated: true)
        }
    }
}

public enum SlidePickerCellType {
    case Empty
    case BigStroke
    case SmallStroke
}

public class SlidePickerCell: UICollectionViewCell {
    public static var signWidth: CGFloat = {
        let sign = "-"
        let maximumTextSize = CGSize(width: 100, height: 100)
        let textString = sign as NSString
        let font = UIFont.systemFont(ofSize: 12.0)
        
        let rect = textString.boundingRect(with: maximumTextSize, options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedString.Key.font: font], context: nil)

        return (rect.width / 2) + 1
    }()
    
    public static let strokeWidth: CGFloat = 1.5
    
    public var showTickLabels = true
    public var showPlusForPositiveValues = true
    public var highlightTick = false

    private var type = SlidePickerCellType.Empty
    
    public var value: CGFloat = 0.0 {
        didSet {
            let strValue = String(format: "%0.0f", value)
            
            if value > 0.00001 && showPlusForPositiveValues {
                valueLabel.text = "+" + strValue
            } else {
                valueLabel.text = strValue
            }
        }
    }
    
    public var indexPath: NSIndexPath?
    
    private let strokeView = UIView()
    private let valueLabel = UILabel()
    private let strokeWidth: CGFloat = SlidePickerCell.strokeWidth
    private var bigStrokePaddind: CGFloat = 4.0
    private var smallStrokePaddind: CGFloat = 8.0
    
    public var currentTransform: CGAffineTransform = .identity {
        didSet {
            valueLabel.transform = currentTransform
        }
    }
    
    public var tickColor = UIColor.white {
        didSet {
            strokeView.backgroundColor = tickColor
            valueLabel.textColor = tickColor
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
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        strokeView.alpha = 0.0
        valueLabel.alpha = 0.0
        
        indexPath = nil
    }
    
    public func updateValue(value: CGFloat, type: SlidePickerCellType) {
        self.value = value
        self.type = type
        
        layoutSubviews()
    }
    
    private func commonInit() {
        strokeView.backgroundColor = UIColor.white
        strokeView.alpha = 0.0
        strokeView.layer.masksToBounds = true
        strokeView.layer.cornerRadius = strokeWidth / 2
        
        valueLabel.textAlignment = .center
        valueLabel.font = UIFont.systemFont(ofSize: 12.0)
        valueLabel.textColor = UIColor.white
        valueLabel.alpha = 0.0

        contentView.addSubview(strokeView)
        contentView.addSubview(valueLabel)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = frame.size.height
        let xShift: CGFloat = (showPlusForPositiveValues && value > 0.0001) || value < -0.0001 ? SlidePickerCell.signWidth : 0.0
        
        switch type {
            case .Empty:
                strokeView.alpha = 0.0
                valueLabel.alpha = 0.0
                break
                
            case .BigStroke:
                let widthAddition: CGFloat = highlightTick ? 0.5 : 0.0

                strokeView.alpha = 1.0
                valueLabel.alpha = showTickLabels ? 1.0 : 0.0
                
                if showTickLabels {
                    valueLabel.frame = CGRect(x: -5 - xShift, y: 0, width: frame.size.width + 10, height: height / 3)
                } else {
                    valueLabel.frame = .zero
                }
                
                strokeView.frame = CGRect(x: (frame.size.width / 2) - (strokeWidth / 2) - widthAddition,
                                          y: (height / 3) + bigStrokePaddind, width: strokeWidth + widthAddition * 2,
                                          height: (height / 2) - (bigStrokePaddind * 2))

                strokeView.layer.cornerRadius = strokeView.frame.width
                
                break

            case .SmallStroke:
                strokeView.alpha = 1.0
                valueLabel.alpha = 0.0
                
                if showTickLabels {
                    valueLabel.frame = CGRect(x: -xShift, y: 0, width: frame.size.width, height: height / 2)
                } else {
                    valueLabel.frame = .zero
                }
                
                strokeView.frame = CGRect(x: (frame.size.width / 2) - (strokeWidth / 2),
                                          y: (height / 3) + smallStrokePaddind, width: strokeWidth,
                                          height: (height / 2) - (smallStrokePaddind * 2))
                
                strokeView.layer.cornerRadius = strokeView.frame.width
                
                break
        }
    }
}

internal extension UIImage {
    func tintImage(color: UIColor) -> UIImage {
        let scale: CGFloat = 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        context.setBlendMode(.normal)
        draw(in: rect)
        
        context.setBlendMode(.sourceIn)
        color.setFill()
        context.fill(rect)
        
        if let coloredImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return coloredImage.withRenderingMode(.alwaysOriginal)
        }
        
        return self
    }
}
