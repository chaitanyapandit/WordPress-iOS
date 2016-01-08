#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderGalleryViewController : UICollectionViewController
@property (nonatomic, strong,  readonly) ReaderPost *post;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)controllerWithPost:(ReaderPost *)post;
+ (instancetype)controllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

@end
