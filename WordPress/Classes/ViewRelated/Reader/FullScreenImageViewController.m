#import "FullScreenImageViewController.h"
#import "ReaderZoomableImageView.h"

@interface FullScreenImageViewController () <ZoomableImageViewDelegate>

@property (nonatomic) ReaderZoomableImageView *imageView;
@property CGRect initialRect;

@end

@implementation FullScreenImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

- (ReaderZoomableImageView *)imageView {
    if (_imageView)
        return _imageView;
    
    _imageView = [[ReaderZoomableImageView alloc] init];
    _imageView.delegate = self;
    [self.view addSubview:_imageView];
    
    return _imageView;
}

- (void)animateImage:(UIImage *)image fromRect:(CGRect)rect
{
    self.imageView.image = image;
    self.imageView.frame = rect;
    self.initialRect = rect;
    
    [UIView animateWithDuration:0.33f animations:^{
        self.view.backgroundColor = [UIColor blackColor];
        self.imageView.frame = self.view.bounds;
    } completion:nil];
}

#pragma ZoomableImageViewDelegate

- (void)imageView:(ReaderZoomableImageView *)imageView didZoom:(CGFloat)scale
{
    
}

- (void)imageViewDidReset:(ReaderZoomableImageView *)imageView
{
    
}

- (void)dismissImageView:(ReaderZoomableImageView *)imageView
{
    [UIView animateWithDuration:0.33f animations:^{
        self.imageView.frame = self.initialRect;
        self.view.backgroundColor = [UIColor clearColor];
        
    } completion:^(BOOL finished) {
        
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self didMoveToParentViewController:nil];
    }];
}

@end
