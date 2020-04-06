//
//  ViewController.swift
//  MapKitSample
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var map: MKMapView!
    
    var locationManager = CLLocationManager()
    var points = [CLLocationCoordinate2D]()
    var selectedRow = Set<Int>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showUserLocation() {
        map.showsUserLocation = !map.isUserLocationVisible
    }
    
    func requestUserAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func localSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant"
        request.region = map.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                if let res = response {
                    for local in res.mapItems {
                        print(local.name ?? "")
                        self.map.addAnnotation(local.placemark)
                    }
                }
            }
        }
    }
    
    func centerMap() {
        
        if let location = locationManager.location {
            var region = MKCoordinateRegion()
            region.center.latitude = location.coordinate.latitude
            region.center.longitude = location.coordinate.longitude
            region.span.longitudeDelta = 0.005
            
            map.region = region
        }
    }
    
    func requestDirectionsTo(source : CLLocationCoordinate2D, destination : CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                if let routes = response?.routes {
                    for route in routes {
                        print(route.distance)
                        self.map.addOverlays([route.polyline])
                    }
                }
            }
        }
    }
    
    func mapCamera(userCoordinate: CLLocationCoordinate2D, eyeCoordinate : CLLocationCoordinate2D) {
        let mapCamera = MKMapCamera(lookingAtCenter: userCoordinate, fromEyeCoordinate: eyeCoordinate, eyeAltitude: 800.0)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = userCoordinate
        map.addAnnotation(annotation)
        map.setCamera(mapCamera, animated: true)
    }
    
    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())

        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.denied {
            print("Autorize a localização para usar o App")
        } else if status == CLAuthorizationStatus.authorizedWhenInUse {
            print("Autorizado!")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            let position :CGPoint = touch.location(in: view)
            let coord = map.convert(position, toCoordinateFrom: self.view)
            points.append(coord)

            if selectedRow.contains(3) {
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                ann.title = "Meu Pin"
                map.addAnnotation(ann)
            }
            
            if selectedRow.contains(4) {
                map.addOverlays([MKCircle(center: coord, radius: CLLocationDistance(integerLiteral: 50))])
            }
            
            if selectedRow.contains(5) {
                if points.count == 3 {
                    let pol = MKPolygon(coordinates: points, count: 3)
                    map.addOverlays([pol])
                }
            }
            
            if selectedRow.contains(6) {
                if points.count == 4 {
                    let poline = MKPolyline(coordinates: points, count: 4)
                    map.addOverlays([poline])
                }
            }

//            map.addOverlays([MKTileOverlay(urlTemplate: "https://www.apple.com/ac/structured-data/images/knowledge_graph_logo.png")])
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.green
            circleRenderer.alpha = 0.3
            circleRenderer.strokeColor = UIColor.black
            circleRenderer.lineWidth = 2
            return circleRenderer
        }
        
        if let overlay = overlay as? MKPolygon {
            let poly = MKPolygonRenderer(overlay: overlay)
            poly.fillColor = UIColor.brown
            poly.alpha = 0.2
            return poly
        }

        if let overlay = overlay as? MKPolyline {
            let poly = MKPolylineRenderer(overlay: overlay)
            poly.strokeColor = getRandomColor()
            poly.lineWidth = 3
            return poly
        }

        if let overlay = overlay as? MKTileOverlay {
            let poly = MKTileOverlayRenderer(overlay: overlay)
            poly.alpha = 0.5
            return poly
        }
        
        return MKCircleRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Pin"

        if !(annotation is MKUserLocation) {
        
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true

                let btn = UIButton(type: .detailDisclosure)
                annotationView!.rightCalloutAccessoryView = btn
            } else {
                annotationView!.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let ac = UIAlertController(title: "Aviso", message: "Você tocou no Pin!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            requestUserAuthorization()
        case 1:
            showUserLocation()
        case 2:
            centerMap()
        case 3, 4, 5, 6:
            if selectedRow.contains(indexPath.row) {
                selectedRow.remove(indexPath.row)
            } else {
                selectedRow.insert(indexPath.row)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case 7:
            if points.count >= 2 {
                requestDirectionsTo(source: points[0], destination: points[1])
            }
        case 8 :
            localSearch()
        case 9:
            if points.count >= 2 {
                mapCamera(userCoordinate: points[0], eyeCoordinate: points[1])
            }
        case 10:
            map.removeAnnotations(map.annotations)
            map.removeOverlays(map.overlays)
            points.removeAll()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item\(indexPath.row)")

        if selectedRow.contains(indexPath.row) {
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 11
    }
}

