#import "ReaderGalleryViewController.h"

#import <WordPress-iOS-Shared/UIImage+Util.h>

#import "ContextManager.h"
#import "FullScreenImageViewController.h"
#import "ReaderGalleryCell.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"

@interface ReaderGalleryViewController ()

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) NSNumber *postSiteID;
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ReaderGalleryViewController

#pragma mark - Static Helpers

+ (instancetype)controllerWithPost:(ReaderPost *)post
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    ReaderGalleryViewController *controller = [[self alloc] initWithCollectionViewLayout:layout];
    controller.post = post;
    return controller;
}

+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    ReaderGalleryViewController *controller = [[self alloc] init];
    [controller setupWithPostID:postID siteID:siteID];
    return controller;
}

#pragma mark - LifeCycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerClass:[ReaderGalleryCell class] forCellWithReuseIdentifier:@"ReaderGalleryCell"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self configureNavbar];
}

#pragma mark - Configuration

- (void)configureNavbar
{
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.title = NSLocalizedString(@"Gallery", @"Title of the reader's gallery screen");
}

#pragma mark - Actions

- (void)done:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Refresh Helpers

- (void)refreshAndSync
{
    
}

#pragma mark - Async Loading Helpers

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service      = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    __weak __typeof(self) weakSelf  = self;
    
    self.postSiteID = siteID;
    
    [service fetchPost:postID.integerValue forSite:siteID.integerValue success:^(ReaderPost *post) {
        
        [weakSelf setPost:post];
        [weakSelf refreshAndSync];
        
    } failure:^(NSError *error) {
        DDLogError(@"[RestAPI] %@", error);
    }];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController)
        return _fetchedResultsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Media" inManagedObjectContext:[ContextManager sharedInstance].mainContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY readerPosts.globalID like [c] %@", self.post.globalID];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[ContextManager sharedInstance].mainContext sectionNameKeyPath:nil cacheName:nil];
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        DDLogError(@"[Reader Gallery] Error fetching remote post attachments %@", error.description);
        abort();
    }
    
    return _fetchedResultsController;
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    NSInteger retVal = [sectionInfo numberOfObjects];
    return retVal;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderGalleryCell *cell = (ReaderGalleryCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"ReaderGalleryCell"  forIndexPath:indexPath];
    Media *media = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.media = media;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ReaderGalleryCell *cell = (ReaderGalleryCell *) [collectionView cellForItemAtIndexPath:indexPath];
    
    UIViewController *parentViewController = self.navigationController;
    
    FullScreenImageViewController *viewCon = [[FullScreenImageViewController alloc] init];
    [viewCon willMoveToParentViewController:parentViewController];
    viewCon.view.frame = parentViewController.view.bounds;
    [parentViewController.view addSubview:viewCon.view];
    [parentViewController addChildViewController:viewCon];
    [viewCon didMoveToParentViewController:parentViewController];
    
    [viewCon animateImage:cell.imageView.image fromRect:[cell convertRect:cell.bounds toView:parentViewController.view]];
}

#pragma mark - UICollectionViewDelegateFlowLayout

#define kInterSpacing 2.0f // Spacing between cells
#define kEdgeSpacing 4.0f // Spacing between cell and collection view
#define kGridSize 4.0f // Number of columns

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat width = MIN(collectionView.bounds.size.width, collectionView.bounds.size.height); // Total width/height available
    width -= (kEdgeSpacing * 2.0f); // Minus size taken by edge spacings on both sides
    width -= (kGridSize -1)*kInterSpacing; // Minus the total size taken by separators
    CGFloat sz = width/kGridSize; // Size available for each individual cell
    
    return CGSizeMake(sz, sz);
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(kEdgeSpacing, kEdgeSpacing, kEdgeSpacing, kEdgeSpacing);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return kInterSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return kInterSpacing;
}

@end
