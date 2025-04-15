import UIKit
import Foundation

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        // Feed Tab
        let feedVC = FeedViewController()
        let feedNav = UINavigationController(rootViewController: feedVC)
        feedNav.tabBarItem = UITabBarItem(title: "Feed",
                                          image: UIImage(systemName: "house"),
                                          selectedImage: UIImage(systemName: "house.fill"))
         feedNav.navigationBar.prefersLargeTitles = false


       
        let postPlaceholderVC = UIViewController()
         postPlaceholderVC.tabBarItem = UITabBarItem(title: "Post",
                                          image: UIImage(systemName: "plus.app"),
                                          selectedImage: UIImage(systemName: "plus.app.fill"))


        // --- Profile Tab
        // let profileVC = ProfileViewController() // Create this VC if needed
        // let profileNav = UINavigationController(rootViewController: profileVC)
        // profileNav.tabBarItem = UITabBarItem(title: "Profile",
        //                                    image: UIImage(systemName: "person.circle"),
        //                                    selectedImage: UIImage(systemName: "person.circle.fill"))

        // Set the view controllers for the tab bar
        // Add profileNav here if you implement it
        viewControllers = [feedNav, postPlaceholderVC]

        self.delegate = self
    }

    private func setupAppearance() {
        // Customize Tab Bar Appearance (Optional)
        tabBar.tintColor = .label // Color for selected items
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.backgroundColor = .systemBackground

        // Customize Navigation Bar Appearance Globally (Optional)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    private func presentPostViewController() {
           // Ensure PostViewController is correctly defined and included in the target
           let postVC = PostViewController()
           let postNav = UINavigationController(rootViewController: postVC)

           // Explicitly state the type for the presentation style
           postNav.modalPresentationStyle = UIModalPresentationStyle.fullScreen // Or often just .fullScreen works if unambiguous, but explicit is safer

           // Present the navigation controller containing the PostViewController
           present(postNav, animated: true, completion: nil)
       }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is UINavigationController {
             return true
        } else if viewController == viewControllers?[1] {
            print("Post tab selected - presenting PostViewController modally.")
            presentPostViewController()
            return false
        }
        return true
    }
}
