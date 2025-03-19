import UIKit

class YPUnderlinedButton: ExtendedButton
{
   @IBInspectable var lineDashed : Bool = false
   @IBInspectable var lineOffset : CGFloat = 0
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      
      let highlightLayer = CALayer()
      highlightLayer.name = "highlightLayer"
      highlightLayer.backgroundColor = UIColor.clear.cgColor
      highlightLayer.frame = layer.bounds
      layer.addSublayer(highlightLayer)
      
      titleLabel?.backgroundColor = UIColor.clear
   }
   
   override func layoutSubviews()
   {
      super.layoutSubviews()
      guard let label = titleLabel else { return }
      
      if let highlightLayer = layer.sublayers?.first(where: {$0.name == "highlightLayer"})
      {
         highlightLayer.frame = label.frame.insetBy(dx: -5, dy: -5)
         highlightLayer.cornerRadius = 5
      }
   }
   
   override func setTitle(_ title: String?, for state: UIControlState)
   {
      super.setTitle(title, for: state)
      setNeedsDisplay()
   }
   
   override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControlState)
   {
      super.setAttributedTitle(title, for: state)
      setNeedsDisplay()
   }
   
   override func draw(_ rect: CGRect)
   {
      super.draw(rect)
      
      guard let label = titleLabel else { return }
      let textRect = CGRect(origin: convert(label.bounds.origin, from: label), size: label.frame.size)
      
      let path = UIBezierPath()
      path.lineWidth = 1
      path.lineCapStyle = CGLineCap.butt
      
      if lineDashed
      {
         var dashCount = (textRect.width - 4) / 16
         dashCount = round(dashCount)
         let spaceWidth : Double = Double(textRect.width / (4 * dashCount - 1))
         let dashWidth = spaceWidth * 3.0
         
         let lineDashPattern : [CGFloat] = [CGFloat(dashWidth), CGFloat(spaceWidth)]
         path.setLineDash(lineDashPattern, count: lineDashPattern.count, phase: 0)
      }
      
      let y = textRect.maxY + lineOffset
      path.move(to: CGPoint(x: textRect.minX, y: y))
      path.addLine(to: CGPoint(x: textRect.maxX, y: y))

      (titleColor(for: state) ?? UIColor.black).setStroke()
      path.stroke()
   }
   
   override var isHighlighted: Bool
   {
      get { return super.isHighlighted }
      set {
         super.isHighlighted = newValue
         if let highlightLayer = layer.sublayers?.first(where: {$0.name == "highlightLayer"})
         {
            highlightLayer.backgroundColor = newValue ? titleColor(for: .normal)?.withAlphaComponent(0.1).cgColor : UIColor.clear.cgColor
         }
      }
   }
}
