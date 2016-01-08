#import <UIKit/UIKit.h>

#import "Media.h"

@interface ReaderGalleryCell : UICollectionViewCell

@property (nonatomic) UIImageView *imageView;
@property (nonatomic, weak) Media *media;

@end
