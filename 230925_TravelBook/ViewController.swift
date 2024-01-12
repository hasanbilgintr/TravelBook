//
//  ViewController.swift
//  230925_TravelBook
//
//  Created by hasan bilgin on 26.09.2023.
//

import UIKit
//eklendi
import MapKit
//CoreLocation konum almak için
import CoreLocation
//eklendi
import CoreData

//MKMapViewDelegate map kit için eklendi
//CLLocationManagerDelegate location için eklendi
class ViewController: UIViewController ,MKMapViewDelegate,CLLocationManagerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var commentTextField: UITextField!
    
    var locationManager = CLLocationManager()
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //Storyboardda map kit view Seçtik
        //değerlerinide selften verdik
        mapView.delegate = self
        //location içinde aynısını yaptık
        locationManager.delegate = self
        
        //konum keskinliği için
        //kCLLocationAccuracyBest en iyi location almak için yalnız pilde ona göre tüketir
        //kCLLocationAccuracyKilometer buda kullanılabilir 1 km sapması olabilir
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //kullanıcdan izin istemek
        //reguestWhenInUseAuthorization() sadece uyuglayı kullanırken , ve önerilendir
        //reguestAlwaysAuthorization() herzaman
        locationManager.requestWhenInUseAuthorization()
        //kullanıcın yerini bunla almaya başlar
        locationManager.startUpdatingLocation()
        //info.plist e gidip Privacy - Location When In Use Usage Description ekledik
        //Allow while using App uygulamayı kullanırken izin vermek
        //Allow Once Bir kez izin ver
        
        //harita açıkken konum girebiliriz oda similatör açııken projede olup en üstte Debug->Simulate Location dan istediğin yere tıklanabilir haritada hemen değişir
        //yada
        //harita açıkken konum girebiliriz oda similatör açııken similatörde olup Features -> Location -> custom location derse istediğin location girip harita gider yada hazır yerlerde tıklanabilir
        //enlem boylam nasıl bulunur dersek nete yazalım eiffel tower mesela harita kısmına gelip direk üsste linkte çıkar yada işarete sağ tıklayıpta verir
        
        //haritadaki pinler (işaret,iğne) eklemek için // haritada uzun basmakda oluşçak olan ...
        //chooseLocation( gestureRecognizer:)  burda kendisini yolladık aynı isimle karşılamak zorunda
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation( gestureRecognizer:)))
        //dokunma süresi 3 ise 3 sndir genelde 2 yada 3 tür
        recognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(recognizer)
        
        if selectedTitle != ""{
            //get CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameTextField.text  =   annotationTitle
                                        commentTextField.text = annotationSubtitle
                                        
                                        //şimdi similayotde ne ise oraya zoomlucak tabiki olan yere ping atıcak ama herseferinde konum ne ise kamera oraya dönücek ondna dolayı
                                        //konumu bu şeklilde durdurduk ama durdukmakla kamera pine yine gelmiyo tekrar kod yazmak lazım
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("error")
            }
        }else{
            //new data
        }
        
        
    }
    
    //
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
        
        if nameTextField.text != "" && commentTextField.text != "" {
            //dokunma işlemi başlayıp 3sn sonrası için yapılcaklar
            if gestureRecognizer.state == .began {
                //noktayı bulmamıza yarar
                let touchedPoint = gestureRecognizer.location(in: self.mapView)
                //noktayı kordinata çevircez
                let touchedCoordinates = self.mapView.convert(touchedPoint,toCoordinateFrom: self.mapView)
                
                //latitude alındı
                chosenLatitude = touchedCoordinates.latitude
                //longitude alındı
                chosenLongitude = touchedCoordinates.longitude
                
                //pini oluşturalım
                let annotation = MKPointAnnotation()
                //kordinatları atadık
                annotation.coordinate = touchedCoordinates
                //işaretledik sonra işarete tıklanmadan önce yazan başlıktır
                annotation.title = nameTextField.text
                //işaretledik sonra işerete tıkladıktan sonra altında yazan yerdir
                annotation.subtitle = commentTextField.text
                //ekleyelim
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    //kullanıcının yerini aldıktan sonra çalışçak function
    //lokasyonları bir dizi içersinde veriyo
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            //locations[0].coordinate.latitude ilk verdiği lokasyon bilgisinin enlemidir
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //haritada gösterebilmek için zoom seviyesi yapmak lazım
            //0.1 biraz alanlı gösterrir 0.01 daha yakın ... gider
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    
    }
    
    //pin özelleştirme (sağına item gelip oraya gitme oluştuurlcak) kendisini özelleştirebilirizde
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //kullanıcının yerini gösteren annotation istemediğimiz için kapadık aslında
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        //pinView özelleştirmeye başlayalım
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //bir baloncukla birlikte ekstra bir bilgi göster
            pinView?.canShowCallout = true
            //Annotation normalde kırmızı çıkıyoya siyahta gösterebiliriz
            pinView?.tintColor = UIColor.black
            
            //detay göstereceğim bir button kesteddik
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            //sağ tarafımda göstericek yerde bu buton olarak bildirdik
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    //pinin sağına button koyduk üstteki metotda ona tıklandığında çalıştırılcak kodlar....
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
        //Navigasyonumu çalıştırmak için gerekli objeyi alabilmek için
        //CLGeocodeCompletionHandler gelip entere tıklanrısa [CLPlacemark]?, Error? in vericektir
        //bu yapıya closure deniyor
        //bu işlemde sonuçta vize birşey verilcek (callBackFunction denilebilir) ya hata yada placemarkların bulunduğu bir dizi veirlcek
        CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
            //placemarks nil değilse anlamına geliyor
            if let placemark = placemarks {
                if placemark.count > 0 {
                    let newPlacemark = MKPlacemark(placemark: placemark[0])
                    let item = MKMapItem(placemark: newPlacemark)
                    item.name = self.annotationTitle
                    //MKLaunchOptionsDirectionsModeKey hangi araçla göstereyim
                    //MKLaunchOptionsDirectionsModeDriving araba ile giidlceğini söledik ama çıkan programda değiştirilebiliyor otobüse tıklanabilir yani
                    let launchOptionsss = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    //navigasyon açma
                    item.openInMaps(launchOptions: launchOptionsss)
                    
                }
            }

            
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameTextField.text, forKey: "title")
        newPlace.setValue(commentTextField.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }


        
        //kısa yol commmand+* satır yorum yapar
        //kısa yol command+space net araması çubuğu gelir
        //newPlace post ettik 
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        //bi önceki ekrqna dönücek
        navigationController?.popViewController(animated: true)
        
        
    }
    
    
}

