
import UIKit
import ParseSwift
import CoreLocation

/*
 ParseSwift.initialize(applicationId: "qlVWxnDmNExWx03iUprYnZOPZaoB1mPw9wfYo6Rx",
                               clientKey: "6rLHT1l6MUGcuMdfGh2VrjsFKrizmALj8Sp1S56h",
                               serverURL: URL(string: "https://parseapi.back4app.com")!)

         print("✅ Parse SDK Initialized")
 */
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ParseSwift.initialize(applicationId: "qlVWxnDmNExWx03iUprYnZOPZaoB1mPw9wfYo6Rx", // <--- Replace
                              clientKey: "6rLHT1l6MUGcuMdfGh2VrjsFKrizmALj8Sp1S56h",    // <--- Replace
                              serverURL: URL(string: "https://parseapi.back4app.com")!)
        print("🚀 Parse SDK Initialized")

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}






