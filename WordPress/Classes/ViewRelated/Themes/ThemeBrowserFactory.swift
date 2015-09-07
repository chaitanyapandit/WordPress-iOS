import Foundation

class ThemeBrowserFactory : NSObject {
    
    private var storyboard : UIStoryboard!
    
    override init() {
        super.init()
        
        storyboard = UIStoryboard(name: "ThemeBrowser", bundle: nil)
    }
    
    func instantiateThemeBrowserViewControllerWithBlog(blog: Blog) -> ThemeBrowserViewController {
        
        let viewController : ThemeBrowserViewController = storyboard.instantiateInitialViewController() as! ThemeBrowserViewController
        
        viewController.configureWithBlog(blog)
        
        return viewController
    }
}