import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        if UserDefaults.standard.object(forKey: "AppLanguage") == nil {
            UserDefaults.standard.set("en", forKey: "AppLanguage")
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarNavController = storyboard.instantiateViewController(withIdentifier: "TabBarNavController") as? TabBarNavController else {
            fatalError("TabBarNavController not found in storyboard")
        }
        let navVC = UINavigationController(rootViewController: tabBarNavController)
        navVC.navigationBar.isHidden = true
        navVC.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = navVC
        setAppearance()
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
    
    private func setAppearance() {
        switch App.appearance {
        case .System:
          window?.overrideUserInterfaceStyle = .unspecified
        case .Light:
          window?.overrideUserInterfaceStyle = .light
        case .Dark:
          window?.overrideUserInterfaceStyle = .dark
        }
      }
}
