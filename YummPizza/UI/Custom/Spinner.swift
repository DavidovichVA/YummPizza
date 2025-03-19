//
//  Spinner.swift
//  YummPizza
//

import MBProgressHUD

@discardableResult
func showAppSpinner(addedTo view: UIView = AppWindow, animated: Bool = true, dimBackground: Bool = true, shadow: Bool = true) -> MBProgressHUD
{
   if let hud = MBProgressHUD(for: view)
   {
      hud.show(animated: animated)
      return hud
   }
   
   let hud = MBProgressHUD(view: view)
   let spinnerView = SpinnerView()
   hud.customView = spinnerView
   hud.mode = .customView
   
   hud.removeFromSuperViewOnHide = true
   hud.margin = 0
   hud.backgroundView.style = .solidColor
   hud.backgroundView.color = dimBackground ? UIColor.gray.withAlphaComponent(0.25) : UIColor.clear
   hud.bezelView.style = .solidColor
   hud.bezelView.color = UIColor.clear
   hud.bezelView.backgroundColor = UIColor.clear
   hud.bezelView.clipsToBounds = false
   
   if shadow
   {
      hud.bezelView.layer.shadowColor = UIColor.black.cgColor
      hud.bezelView.layer.shadowRadius = 12
      hud.bezelView.layer.shadowOpacity = 0.75
      hud.bezelView.layer.shadowOffset = .zero
   }
   
   view.addSubview(hud)
   hud.show(animated: animated)
   spinnerView.startAnimating()
   return hud
}

func hideAppSpinner(for view: UIView = AppWindow, animated: Bool = true)
{
   MBProgressHUD.hide(for: view, animated: animated)
}


fileprivate class SpinnerView : UIView
{
   var spinnerSize : CGSize = CGSize.square(60 * WidthRatio)
   var spinnerThickness : CGFloat = 2.5 * WidthRatio
   
   let outerColor : UIColor = rgb(0, 87, 164)
   let middleColor : UIColor = rgb(222, 16, 29)
   let innerColor : UIColor = rgb(17, 25, 48)
   
   var outerView : SpinnerHalfCircle!
   var middleView : SpinnerHalfCircle!
   var innerView : SpinnerHalfCircle!
   
   private(set) var isAnimating : Bool = false
   
   init()
   {
      super.init(frame: CGRect(origin: .zero, size: spinnerSize))
      setup()
   }
   
   required override init(frame: CGRect)
   {
      super.init(frame: frame)
      setup()
   }
   
   required init?(coder aDecoder: NSCoder)
   {
      super.init(coder: aDecoder)
      setup()
   }
   
   private func setup()
   {
      backgroundColor = UIColor.white
      
      outerView = SpinnerHalfCircle(outerColor, spinnerThickness, true)
      addSubview(outerView)
      
      middleView = SpinnerHalfCircle(middleColor, spinnerThickness, false)
      addSubview(middleView)
      
      innerView = SpinnerHalfCircle(innerColor, spinnerThickness, true)
      addSubview(innerView)
   }
   
   override func layoutSubviews()
   {
      let diameter = bounds.width
      let radius = diameter / 2
      let spinnerCenter: CGPoint = CGPoint(x: radius, y: radius)
      
      layer.cornerRadius = radius
      clipsToBounds = true
      
      let outerDiameter : CGFloat = diameter
      outerView.size = CGSize.square(outerDiameter)
      outerView.center = spinnerCenter
      
      let middleDiameter : CGFloat = diameter * 2.0/3.0
      middleView.size = CGSize.square(middleDiameter)
      middleView.center = spinnerCenter
      
      let innerDiameter : CGFloat = diameter / 3
      innerView.size = CGSize.square(innerDiameter)
      innerView.center = spinnerCenter
   }
   
   override var intrinsicContentSize: CGSize {
      return spinnerSize
   }
   
   func startAnimating()
   {
      guard !isAnimating else { return }
      
      outerView.transform = .identity
      middleView.transform = .identity
      innerView.transform = .identity
      
      let clockwiseRotation = CABasicAnimation(keyPath: "transform.rotation.z")
      clockwiseRotation.fromValue = CGFloat(0)
      clockwiseRotation.toValue = CGFloat.pi * 2
      clockwiseRotation.duration = 1
      clockwiseRotation.repeatCount = Float.greatestFiniteMagnitude
      
      let counterClockwiseRotation = CABasicAnimation(keyPath: "transform.rotation.z")
      counterClockwiseRotation.fromValue = CGFloat.pi * 2
      counterClockwiseRotation.toValue = CGFloat(0)
      counterClockwiseRotation.duration = 1
      counterClockwiseRotation.repeatCount = Float.greatestFiniteMagnitude
      
      outerView.layer.add(clockwiseRotation, forKey: "rotationAnimation")
      middleView.layer.add(counterClockwiseRotation, forKey: "rotationAnimation")
      innerView.layer.add(clockwiseRotation, forKey: "rotationAnimation")
      isAnimating = true
   }
   
   func stopAnimating()
   {
      guard isAnimating else { return }
      outerView.layer.removeAnimation(forKey: "rotationAnimation")
      middleView.layer.removeAnimation(forKey: "rotationAnimation")
      innerView.layer.removeAnimation(forKey: "rotationAnimation")
      isAnimating = false
   }
}

fileprivate class SpinnerHalfCircle : UIView
{
   var color : UIColor!
   var thickness : CGFloat!
   var isTop : Bool!
   
   convenience init(_ color : UIColor, _ thickness : CGFloat, _ isTop : Bool)
   {
      self.init()
      self.color = color
      self.thickness = thickness
      self.isTop = isTop
      self.contentMode = .redraw
   }
   
   override func draw(_ rect: CGRect)
   {
      let radius = bounds.width / 2
      let spinnerCenter: CGPoint = CGPoint(x: radius, y: radius)
      
      let context = UIGraphicsGetCurrentContext()!
      UIColor.white.setFill()
      context.fill(rect)
      
      let path = UIBezierPath()
      path.lineWidth = thickness
      path.lineCapStyle = CGLineCap.round
      
      path.move(to: CGPoint(x: thickness / 2, y: radius))
      path.addArc(withCenter: spinnerCenter, radius: radius - thickness / 2, startAngle: CGFloat.pi, endAngle: 0, clockwise: isTop)

      color.setStroke()
      path.stroke()
   }
}
