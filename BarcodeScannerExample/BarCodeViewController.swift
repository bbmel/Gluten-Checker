import UIKit
import BarcodeScanner
import SwiftyJSON
import Alamofire
import PopupDialog



final class BarCodeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        globalHasGluten = false
    }
    @IBOutlet var pushScannerButton: UIButton!
    
    @IBAction func handleScannerPush(_ sender: Any, forEvent event: UIEvent) {
        let viewController = makeBarcodeScannerViewController()
        viewController.title = "Gluten Check"
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func makeBarcodeScannerViewController() -> BarcodeScannerViewController {
        let viewController = BarcodeScannerViewController()
        viewController.codeDelegate = self
        viewController.errorDelegate = self
        viewController.dismissalDelegate = self
        return viewController
    }
}

// MARK: - BarcodeScannerCodeDelegate

extension BarCodeViewController: BarcodeScannerCodeDelegate {
    
    func loadScannedNutritionData(code: String, callback: @escaping (Bool) -> ()) {
        
        // Edamam API Credentials
        //let upcCode = "041508800037"
        let appId = "38e65f02"
        let appKey = "257aa0a33d3f88c76d72e071b1736277"
        var hasGluten = false
        
        // API magic happens here
        let url = URL(string: "https://api.edamam.com/api/food-database/parser?upc=\(code)&app_id=\(appId)&app_key=\(appKey)")!
        Alamofire.request(url).responseJSON(completionHandler: { response in
            if let value = response.result.value {
                let json = JSON(value)
                // check if the ingredients key even exists
                if json["hints"][0]["food"]["foodContentsLabel"].exists() {
                    // read ingredients into string
                    let listOfIngredients = json["hints"][0]["food"]["foodContentsLabel"].stringValue.lowercased()
                    // read UPC scanned item label into string
                    let itemLabel = json["hints"][0]["food"]["label"].stringValue.lowercased()
                    // split strings by ';' delimiter and store alphabetically in array
                    let ingredientsArray: [String] = listOfIngredients.components(separatedBy: ";").sorted()
                    
                    // read gluten ingredients from file and compare to UPC scanned item ingredients
                    let fileURL = Bundle.main.url(forResource: "glutenIngredients", withExtension: "txt")
                    do {
                        let glutenIngredients = try String(contentsOf: fileURL!, encoding: .utf8)
                        let glutenIngredientsArray = glutenIngredients.components(separatedBy: NSCharacterSet.newlines)
                        var glutenCount = 0
                        for elem1 in glutenIngredientsArray {
                            for elem2 in ingredientsArray {
                                let elem2Trimmed = elem2.trimmingCharacters(in: .whitespaces)
                                if elem2Trimmed.contains(elem1) || itemLabel.contains(elem1)  {
                                    //print("***\(elem2Trimmed) contains \(elem1)***")
                                    //print("~~~\(itemLabel) contains \(elem1)~~~")
                                    glutenCount += 1
                                }
                                    
                                else {
                                    //glutenCount = 0
                                }
                            }
                        }
                        if glutenCount >= 1 {
                            print("This item has gluten")
                            hasGluten = true
                            callback(hasGluten)
                        } else {
                            print("This item is gluten free, baby!")
                            hasGluten = false
                            callback(hasGluten)
                        }
                    }
                    catch {
                        print("Oops")
                    }
                }
                else {
                    print("Item not found in database")
                }
            }
        })
    }
    
    func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
        
        
        print("Barcode Data: \(code)")
        print("Symbology Type: \(type)")
        
        loadScannedNutritionData(code: code) { result in
            controller.dismiss(animated: true, completion: nil)
            // if the item has gluten
            if result == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    controller.reset(animated: true)
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let glutenViewController = storyboard.instantiateViewController(withIdentifier :"GlutenViewController")
                    self.present(glutenViewController, animated: true)
                }
                // if the item doesn't have gluten
            } else if result == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    controller.reset(animated: true)
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let glutenFreeViewController = storyboard.instantiateViewController(withIdentifier :"GlutenFreeViewController")
                    self.present(glutenFreeViewController, animated: true)
                }
            }
        }
    }
}



// MARK: - BarcodeScannerErrorDelegate

extension BarCodeViewController: BarcodeScannerErrorDelegate {
    func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
        print(error)
    }
}

// MARK: - BarcodeScannerDismissalDelegate
// FIXME: Never gets called
extension BarCodeViewController: BarcodeScannerDismissalDelegate {
    func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
    // Code processing
    controller.reset(animated: true)
}
