#import <UIKit/UIKit.h>

@class ReaderZoomableImageView;

@protocol ZoomableImageViewDelegate <NSObject>

- (void)imageView:(ReaderZoomableImageView *)imageView didZoom:(CGFloat)scale;
- (void)imageViewDidReset:(ReaderZoomableImageView *)imageView;
- (void)dismissImageView:(ReaderZoomableImageView *)imageView;

@end

@interface ReaderZoomableImageView : UIImageView

@property(nonatomic) BOOL isZoomable;
@property (nonatomic, weak) id <ZoomableImageViewDelegate> delegate;
@property (nonatomic, assign) CGFloat minimumScaleFactor;
@property (nonatomic, assign) CGFloat maximumScaleFactor;
@property (nonatomic, assign) CGFloat defaultScaleFactor;

- (BOOL)isEdited;
- (void)reset:(BOOL)animated;
- (CGFloat)scale;

@end
