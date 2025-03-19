//
//  PizzeriasController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/15/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import GoogleMaps
import RealmSwift

enum PizzeriasControllerMode
{
   case normal
   case select(onCompletion : (Pizzeria?) -> ())
}

class PizzeriasController: UIViewController, GMSMapViewDelegate, UITableViewDelegate, UITableViewDataSource
{
   @IBOutlet weak var mapContainerView: UIView!
   @IBOutlet weak var tableContainerView: UIView!
   @IBOutlet weak var tableView: UITableView!
   
   @IBOutlet weak var bottomButton: UIButton!
   
   @IBOutlet var pizzeriaPopupView: UIView!
   @IBOutlet weak var pizzeriaPopupNameLabel: UILabel!
   @IBOutlet weak var pizzeriaPopupSelectButton: UIButton!
   @IBOutlet weak var pizzeriaPopupPhoneButton: UIButton!
   @IBOutlet weak var pizzeriaPopupTimeLabel: UILabel!
   
   var refreshControl : UIRefreshControl!
   
   private var mapView : GMSMapView!
   private var pizzeriaPins : [GMSMarker] = []
   private var pizzeriaRegions : [GMSPolygon] = []
   private var centerCoordinate : CLLocationCoordinate2D { return mapView.camera.target }
   
   var selectedPizzeria : Pizzeria?
   private var showingPizzeriaPopup : Bool { return pizzeriaPopupView.superview != nil }
   
   let pizzeriaList = PizzeriaList.list
   var notificationToken: NotificationToken? = nil
   
   var mode : PizzeriasControllerMode = .normal
   {
      didSet
      {
         switch mode {
         case .normal: self.menuBarButton = true
         case .select: self.backNavTitle = ""
         }
      }
   }
   
   //MARK: - Lifecycle
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      
      tableContainerView.isHidden = User.current?.prefersPizzeriasMap ?? true
      updateBottomButton()
         
      tableView.estimatedRowHeight = 171 * WidthRatio
      tableView.rowHeight = UITableViewAutomaticDimension
      tableView.allowsMultipleSelection = false
      switch mode {
      case .normal: tableView.allowsSelection = false
      case .select: tableView.allowsSelection = true
      }
      
      refreshControl = UIRefreshControl()
      refreshControl.addTarget(self, action: #selector(refreshPizzerias), for: .valueChanged)
      tableView.addSubview(refreshControl)
      
      notificationToken = pizzeriaList.pizzerias.addNotificationBlock
      {
         [weak self]
         changes in
         
         if let pizzeria = self?.selectedPizzeria, pizzeria.isInvalidated {
            self?.deselectPizzeria()
         }
         
         guard let tableView = self?.tableView else { return }
         switch changes
         {
         case .initial:
            tableView.reloadData()
            
         case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}), with: .automatic)
            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
            tableView.endUpdates()
            
         case .error(let error):
            dlog(error)
         }
      }
      
      pizzeriaPopupView.frame = CGRect(x: 0, y: 0, width: 270 * WidthRatio, height: 160 * WidthRatio)
      pizzeriaPopupPhoneButton.titleLabel?.textAlignment = .center
      pizzeriaPopupPhoneButton.titleLabel?.lineBreakMode = .byWordWrapping
      pizzeriaPopupPhoneButton.titleLabel?.numberOfLines = 0
      pizzeriaPopupView.layer.masksToBounds = false
      pizzeriaPopupView.layer.shadowOpacity = 0.4
      pizzeriaPopupView.layer.shadowOffset =  CGSize(width: 0, height: 7 * WidthRatio)
      pizzeriaPopupView.layer.shadowRadius = 5 * WidthRatio
      pizzeriaPopupView.layer.shadowColor = UIColor.black.cgColor
      
      let camera = GMSCameraPosition.camera(withLatitude: 59.93863, longitude: 30.31413, zoom: 9.5)
      mapView = GMSMapView.map(withFrame: mapContainerView.bounds, camera: camera)
      mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      mapView.delegate = self
      mapView.isMyLocationEnabled = true
      mapContainerView.insertSubview(mapView, at: 0)
      
      updateDisplayedData()
   }
   
   @objc func refreshPizzerias()
   {
      pizzeriaList.update(onlyIfNeeded: false,
      success:
      {
         [weak self] in
         self?.refreshControl.endRefreshing()
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         self?.refreshControl.endRefreshing()
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      
      pizzeriaList.update(
      success:
      {
         [weak self] in
         self?.refreshControl.endRefreshing()
      },
      failure:
      {
         [weak self]
         errorDescription in
         dlog(errorDescription)
         self?.refreshControl.endRefreshing()
         AlertManager.showAlert(errorDescription, buttonTitle: "Закрыть")
      })
      
      mapView?.addObserver(self, forKeyPath: "myLocation", context: nil)
      updateSelectedRegion()
   }
   
   override func viewDidDisappear(_ animated: Bool)
   {
      super.viewDidDisappear(animated)
      mapView?.removeObserver(self, forKeyPath: "myLocation")
   }
   
   deinit {
      notificationToken?.stop()
   }

   //MARK: - Methods
   
   func updateDisplayedData()
   {
      for pin in pizzeriaPins { pin.map = nil }
      for region in pizzeriaRegions { region.map = nil }
      pizzeriaPins.removeAll()
      pizzeriaRegions.removeAll()
      
      for pizzeria in pizzeriaList.pizzerias
      {
         let marker = GMSMarker()
         marker.position = pizzeria.coordinate.coordinate2D
         marker.icon = mapPinPizzeriaImage
         marker.groundAnchor = CGPoint(x: 0.5, y: 1)
         marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0)
         marker.title = pizzeria.addressString
         marker.isTappable = true
         marker.userData = pizzeria
         marker.map = mapView
         pizzeriaPins.append(marker)
      }
      for area in pizzeriaList.pizzeriasAreas
      {
         guard area.points.count >= 3 else { continue }
         let path = GMSMutablePath()
         for coord in area.points {
            path.addLatitude(coord.latitude, longitude: coord.longitude)
         }
         let polygon = GMSPolygon(path: path)
         polygon.fillColor = pizzeriaRegionNormalColor
         polygon.strokeColor = pizzeriaRegionBorderColor
         polygon.strokeWidth = 2
         polygon.isTappable = false
         polygon.map = mapView
         pizzeriaRegions.append(polygon)
      }
   }
   
   override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
   {
      updateSelectedRegion()
   }
   
   func updateSelectedRegion()
   {
      if let coordinate = mapView?.myLocation?.coordinate
      {
         for region in pizzeriaRegions
         {
            if let path = region.path, GMSGeometryContainsLocation(coordinate, path, region.geodesic) {
               region.fillColor = pizzeriaRegionSelectedColor
            }
            else {
               region.fillColor = pizzeriaRegionNormalColor
            }
         }
      }
      else
      {
         for region in pizzeriaRegions
         {
            region.fillColor = pizzeriaRegionNormalColor
         }
      }
   }
   
   func selectPizzeria(_ pizzeria : Pizzeria)
   {
      selectedPizzeria = pizzeria
      
      UIView.performWithoutAnimation
      {
         pizzeriaPopupNameLabel.text = pizzeria.addressString.uppercased()
         pizzeriaPopupPhoneButton.setTitle(pizzeria.phoneLongString, for: .normal)
         pizzeriaPopupTimeLabel.setTextKeepingAttributes(pizzeria.workingTime)
         
         switch mode {
         case .normal: pizzeriaPopupSelectButton.isEnabled = false
         case .select: pizzeriaPopupSelectButton.isEnabled = true
         }
         
         pizzeriaPopupView.frame = CGRect(x: 0, y: 0, width: 270 * WidthRatio, height: ScreenHeight - 100)
         pizzeriaPopupView.layoutIfNeeded()
         let neededHeight = ceil(pizzeriaPopupTimeLabel.bottom + 24 * WidthRatio)
         pizzeriaPopupView.frame = CGRect(x: 0, y: 0, width: 270 * WidthRatio, height: neededHeight)
         pizzeriaPopupView.center = mapView.center
      }
      
      mapContainerView.addSubview(pizzeriaPopupView)
      mapView.isMyLocationEnabled = false
      updateSelectedRegion()
   }
   
   func deselectPizzeria()
   {
      selectedPizzeria = nil
      pizzeriaPopupView.removeFromSuperview()
      mapView.isMyLocationEnabled = true
      updateSelectedRegion()
   }
   
   override func navigationBackTap()
   {
      if case .select(let onCompletion) = mode {
         onCompletion(selectedPizzeria)
      }
      navigationController?.popViewController(animated: true)
   }
   
   func updateBottomButton()
   {
      let buttonTitle : String = tableContainerView.isHidden ? "ПОКАЗАТЬ СПИСКОМ" : "ПОКАЗАТЬ НА КАРТЕ"
      UIView.performWithoutAnimation {
         bottomButton.setTitle(buttonTitle, for: .normal)
      }
   }
   
   //MARK: - GMSMapViewDelegate
   
   func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
   {
      updateSelectedRegion()
   }
   
   func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
   {
      guard let pizzeria = marker.userData as? Pizzeria, !pizzeria.isInvalidated else { return false }
      selectPizzeria(pizzeria)
      return true
   }
   
   func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
   {
      deselectPizzeria()
   }
   
   //MARK: - TableView
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return pizzeriaList.pizzerias.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
   {
      let cell = tableView.dequeueReusableCell(withIdentifier: "PizzeriaListCell", for: indexPath) as! PizzeriaListCell
      cell.pizzeria = pizzeriaList.pizzerias[indexPath.row]
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
   {
      if case .select(let onCompletion) = mode
      {
         let pizzeria = pizzeriaList.pizzerias[indexPath.row]
         onCompletion(pizzeria)
         navigationController?.popViewController(animated: true)
      }
   }
   
   func scrollViewDidScroll(_ scrollView: UIScrollView)
   {
      if let scrollIndicator = scrollView.subviews.last as? UIImageView, scrollIndicator.image !== scrollIndicatorImage
      {
         scrollIndicator.image = scrollIndicatorImage
         scrollIndicator.cornerRadius = 1
         scrollIndicator.clipsToBounds = true
         scrollIndicator.backgroundColor = UIColor.clear
      }
   }
   
   //MARK: - Actions
   
   @IBAction func pizzeriaPhoneTap() {
      selectedPizzeria?.call()
   }
   
   @IBAction func pizzeriaSelectTap()
   {
      if case .select(let onCompletion) = mode
      {
         onCompletion(selectedPizzeria)
         navigationController?.popViewController(animated: true)
      }
   }
   
   @IBAction func pizzeriaPopupCloseTap() {
      deselectPizzeria()
   }
   
   @IBAction func changeMapTableMode()
   {
      tableContainerView.isHidden = !tableContainerView.isHidden
      updateBottomButton()
      
      User.current?.modifyWithTransactionIfNeeded {
         User.current?.prefersPizzeriasMap = tableContainerView.isHidden
      }
   }
}



class PizzeriaListCell: UITableViewCell
{
   @IBOutlet weak var containerView: UIView!
   @IBOutlet weak var addressLabel: UILabel!
   @IBOutlet weak var timeLabel: UILabel!
   @IBOutlet weak var phoneLabel: UILabel!
   
   var pizzeria : Pizzeria!
   {
      didSet
      {
         addressLabel.setTextKeepingAttributes(pizzeria.addressString.isEmpty ? " " : pizzeria.addressString)
         timeLabel.setTextKeepingAttributes(pizzeria.workingTime.isEmpty ? " " : pizzeria.workingTime)
         let phoneString = pizzeria.phoneShortString
         phoneLabel.setTextKeepingAttributes(phoneString.isEmpty ? " " : phoneString)
      }
   }
   
   override func awakeFromNib()
   {
      super.awakeFromNib()
      containerView.layer.masksToBounds = false
      containerView.layer.shadowOpacity = 0.15
      containerView.layer.shadowOffset = CGSize(width: 0, height: 4 * WidthRatio)
      containerView.layer.shadowRadius = 8 * WidthRatio
      containerView.layer.shadowColor = UIColor.black.cgColor
   }
   
   private var _isSelected = false
   override func setSelected(_ selected: Bool, animated: Bool)
   {
      _isSelected = selected
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.updateColor()
      }
   }
   
   private var _isHighlighted = false
   override func setHighlighted(_ highlighted: Bool, animated: Bool)
   {
      _isHighlighted = highlighted
      UIView.animate(withDuration: (animated ? 0.3 : 0)) {
         self.updateColor()
      }
   }
   
   override var isSelected: Bool
   {
      get { return _isSelected }
      set {
         _isSelected = newValue
         updateColor()
      }
   }
   
   override var isHighlighted: Bool
   {
      get { return _isHighlighted }
      set {
         _isHighlighted = newValue
         updateColor()
      }
   }
   
   func updateColor()
   {
      if isSelected { containerView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5) }
      else if isHighlighted { containerView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25) }
      else { containerView.backgroundColor = UIColor.white }
   }
}
