import Foundation
import WordPressShared


/**
 *  @class          DiscussionSettingsViewController
 *  @brief          The purpose of this class is to render the Discussion Settings associated to a site, and
 *                  allow the user to tune those settings, as required.
 */

public class DiscussionSettingsViewController : UITableViewController
{
    // MARK: - Private Properties
    private var settings : BlogSettings!

    
    
    // MARK: - Initializers
    public convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.settings = blog.settings
    }
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettingsIfNeeded()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupNavBar() {
        title = NSLocalizedString("Discussion", comment: "Title for the Discussion Settings Screen")
    }
    
    private func setupTableView() {
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        tableView.cellLayoutMarginsFollowReadableWidth = false
    }

    

    // MARK: - Persistance!
    private func saveSettingsIfNeeded() {
        if !settings.hasChanges {
            return
        }
        
        let service = BlogService(managedObjectContext: settings.managedObjectContext)
        service.updateSettingsForBlog(settings.blog,
            success: nil,
            failure: { (error: NSError!) -> Void in
                DDLogSwift.logError("Error while persisting settings: \(error)")
        })
    }
    
    
    
    // MARK: - UITableViewDataSoutce Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = cellForRow(row, tableView: tableView)
        
        switch row.style {
        case .Switch:
            configureSwitchCell(cell as! SwitchTableViewCell, row: row)
        default:
            configureTextCell(cell as! WPTableViewCell, row: row)
        }
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerText = sections[section].headerText else {
            return CGFloat.min
        }
        
        return WPTableViewSectionHeaderFooterView.heightForHeader(headerText, width: tableView.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerText = sections[section].headerText else {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        footerView.title = headerText
        return footerView
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footerText = sections[section].footerText else {
            return 0
        }
        
        return WPTableViewSectionHeaderFooterView.heightForFooter(footerText, width: tableView.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerText = sections[section].footerText else {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title = footerText
        return footerView
    }
    
    
    
    // MARK: - UITableViewDelegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        
        rowAtIndexPath(indexPath).handler?(tableView)
    }
    
    
    
    // MARK: - Cell Setup Helpers
    private func rowAtIndexPath(indexPath: NSIndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
    
    private func cellForRow(row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier(row.style.rawValue) {
            return cell
        }
        
        switch row.style {
        case .Value1:
            return WPTableViewCell(style: .Default, reuseIdentifier: row.style.rawValue)
        case .Switch:
            return SwitchTableViewCell(style: .Default, reuseIdentifier: row.style.rawValue)
        }
    }
    
    private func configureTextCell(cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text        = row.title ?? String()
        cell.detailTextLabel?.text  = row.details ?? String()
        cell.accessoryType          = .DisclosureIndicator
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func configureSwitchCell(cell: SwitchTableViewCell, row: Row) {
        cell.name       = row.title ?? String()
        cell.on         = row.boolValue ?? true
        cell.onChange = { (newValue: Bool) in
            row.handler?(newValue)
        }
    }
    
    
    
    // MARK: - Computed Properties
    private var sections : [Section] {
        return [postsSection, commentsSection, otherSection]
    }
    
    private var postsSection : Section {
        let headerText = NSLocalizedString("Defaults for New Posts", comment: "Discussion Settings: Posts Section")
        let footerText = NSLocalizedString("You can override these settings for individual posts. Learn more...", comment: "Discussion Settings: Footer Text")
        let rows = [
            Row(style:      .Switch,
                title:      NSLocalizedString("Allow Comments", comment: "Settings: Comments Enabled"),
                boolValue:  self.settings.commentsAllowed,
                handler:    {   [weak self] in
                                self?.pressedCommentsAllowed($0)
                            }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Send Pingbacks", comment: "Settings: Sending Pingbacks"),
                boolValue:  self.settings.pingbackOutboundEnabled,
                handler:    {   [weak self] in
                                self?.pressedPingbacksOutbound($0)
                            }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Receive Pingbacks", comment: "Settings: Receiving Pingbacks"),
                boolValue:  self.settings.pingbackInboundEnabled,
                handler:    {   [weak self] in
                                self?.pressedPingbacksInbound($0)
                            })
        ]
        
        return Section(headerText: headerText, footerText: footerText, rows: rows)
    }
    
    private var commentsSection : Section {
        let headerText = NSLocalizedString("Comments", comment: "Settings: Comment Sections")
        let rows = [
            Row(style:      .Switch,
                title:      NSLocalizedString("Require name & email", comment: "Settings: Comments Approval settings"),
                boolValue:  self.settings.commentsRequireNameAndEmail,
                handler:    {   [weak self] in
                                self?.pressedRequireNameAndEmail($0)
                            }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Require users to sign in", comment: "Settings: Comments Approval settings"),
                boolValue:  self.settings.commentsRequireRegistration,
                handler:    {   [weak self] in
                                self?.pressedRequireRegistration($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Close After", comment: "Settings: Close comments after X period"),
                handler:    {   [weak self] in
                                self?.pressedCloseAfter($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Sort By", comment: "Settings: Comments Sort Order"),
                handler:    {   [weak self] in
                                self?.pressedSortBy($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Threading", comment: "Settings: Comments Threading preferences"),
                handler:    {   [weak self] in
                                self?.pressedThreading($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Paging", comment: "Settings: Comments Paging preferences"),
                handler:    {   [weak self] in
                                self?.pressedPaging($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Automatically Approve", comment: "Settings: Comments Approval settings"),
                handler:    {   [weak self] in
                                self?.pressedAutomaticallyApprove($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Links in comments", comment: "Settings: Comments Approval settings"),
                handler:    {   [weak self] in
                                self?.pressedLinksInComments($0)
                            }),
        ]

        return Section(headerText: headerText, rows: rows)
    }
    
    private var otherSection : Section {
        let rows = [
            Row(style:      .Value1,
                title:      NSLocalizedString("Hold for Moderation", comment: "Settings: Comments Moderation"),
                handler:    self.pressedModeration),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Blacklist", comment: "Settings: Comments Blacklist"),
                handler:    self.pressedBlacklist)
        ]
        
        return Section(rows: rows)
    }
    
    
    // MARK: - Row Handlers
    private func pressedCommentsAllowed(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.commentsAllowed = enabled
    }

    private func pressedPingbacksInbound(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.pingbackInboundEnabled = enabled
    }
    
    private func pressedPingbacksOutbound(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.pingbackOutboundEnabled = enabled
    }

    private func pressedRequireNameAndEmail(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.commentsRequireNameAndEmail = enabled
    }
    
    private func pressedRequireRegistration(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.commentsRequireRegistration = enabled
    }
    
    private func pressedCloseAfter(payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Close After", comment: "")
        settingsViewController.currentValue     = "30"
        settingsViewController.defaultValue     = "30"
        settingsViewController.titles           = ["Never", "One day", "One week", "One month"]
        settingsViewController.values           = ["0", "1", "7", "30"]
        settingsViewController.onItemSelected   = { (selected: AnyObject!) in
        
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func pressedSortBy(payload: AnyObject?) {
        typealias SortOrder                     = BlogSettings.SortOrder

        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Sort By", comment: "")
        settingsViewController.currentValue     = settings.commentsSortOrder
        settingsViewController.titles           = SortOrder.SortTitles
        settingsViewController.values           = SortOrder.SortValues
        settingsViewController.onItemSelected   = { [weak self] (selected: AnyObject!) in
            guard let newSortOrder = selected as? Int else {
                return
            }
            
            self?.settings.commentsSortOrder = newSortOrder
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func pressedThreading(payload: AnyObject?) {
        typealias Threading                     = BlogSettings.Threading
        
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Threading", comment: "")
        settingsViewController.currentValue     = settings.commentsThreadingEnabled ? settings.commentsThreadingDepth : Threading.DepthDisabled
        settingsViewController.titles           = Threading.DepthTitles
        settingsViewController.values           = Threading.DepthValues
        settingsViewController.onItemSelected   = { [weak self] (selected: AnyObject!) in
            guard let newThreadingDepth = selected as? Int else {
                return
            }
            
            self?.settings.commentsThreadingEnabled  = newThreadingDepth != Threading.DepthDisabled
            self?.settings.commentsThreadingDepth    = newThreadingDepth
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func pressedPaging(payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Paging", comment: "")
        settingsViewController.currentValue     = "50"
        settingsViewController.defaultValue     = "50"
        settingsViewController.titles           = ["None", "50 comments per page", "100 comments per page", "200 comments per page"]
        settingsViewController.values           = ["0", "50", "100", "200"]
        settingsViewController.onItemSelected   = { (selected: AnyObject!) in }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func pressedAutomaticallyApprove(payload: AnyObject?) {
        
    }

    private func pressedLinksInComments(payload: AnyObject?) {
        
    }
    
    private func pressedModeration(payload: AnyObject?) {
        
    }
    
    private func pressedBlacklist(payload: AnyObject?) {
        
    }
    
    
    
    // MARK: - Private Nested Classes
    private class Section {
        let headerText      : String?
        let footerText      : String?
        let rows            : [Row]
        
        init(headerText: String? = nil, footerText: String? = nil, rows : [Row]) {
            self.headerText = headerText
            self.footerText = footerText
            self.rows       = rows
        }
    }
    
    private class Row {
        let style           : Style
        let title           : String?
        let details         : String?
        let handler         : Handler?
        var boolValue       : Bool?
        
        init(style: Style, title: String? = nil, details: String? = nil, boolValue: Bool? = nil, handler: Handler? = nil) {
            self.style      = style
            self.title      = title
            self.details    = details
            self.boolValue  = boolValue
            self.handler    = handler
        }
        
        typealias Handler = (AnyObject? -> Void)
        
        enum Style : String {
            case Value1     = "Value1"
            case Switch     = "SwitchCell"
        }
    }
}