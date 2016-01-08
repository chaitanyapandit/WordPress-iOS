#import "ReaderZoomableImageView.h"

@interface ReaderZoomableImageView() <UIGestureRecognizerDelegate>

@property (nonatomic) CGRect defaultFrame;
@property (nonatomic) CGPoint initialPinchLocation;
@property (nonatomic) UIPanGestureRecognizer *panRecogniser;
@property (nonatomic) UIPinchGestureRecognizer *pinchRecogniser;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

@end

@implementation ReaderZoomableImageView

#pragma mark Init & Dealloc

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.pinchRecogniser = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        self.pinchRecogniser.delegate = self;
        [self addGestureRecognizer:self.pinchRecogniser];
        
        self.panRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.panRecogniser.delegate = self;
        [self addGestureRecognizer:self.panRecogniser];
        
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.tapRecognizer.delegate = self;
        [self addGestureRecognizer:self.tapRecognizer];

        self.defaultFrame = CGRectZero;
        
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

#pragma mark Gestures

- (void)handlePinch:(UIPinchGestureRecognizer*)recogniser
{
    if (CGRectIsEmpty(self.defaultFrame))
        self.defaultFrame = self.frame;
    
    if (!self.isFirstResponder)
    {
        if (recogniser.state == UIGestureRecognizerStateBegan)
        {
            self.initialPinchLocation = [recogniser locationInView:self];
            
            UIView *piece = self;
            CGPoint locationInView = [recogniser locationInView:piece];
            CGPoint locationInSuperview = [recogniser locationInView:piece.superview];
            
            piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
            piece.center = locationInSuperview;
        }
        else if (recogniser.state == UIGestureRecognizerStateChanged)
        {
            self.transform = CGAffineTransformScale(self.transform, recogniser.scale, recogniser.scale);
            recogniser.scale = 1;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(imageView:didZoom:)])
            {
                [self.delegate imageView:self didZoom:[self scale]];
            }
        }
        else if (recogniser.state == UIGestureRecognizerStateEnded)
        {
            if (self.scale < 1.0f)
            {
                [self reset:YES];
            }
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)recogniser
{
    if (CGRectIsEmpty(self.defaultFrame))
        self.defaultFrame = self.frame;
    
    if (!self.isFirstResponder)
    {
        if (recogniser.state == UIGestureRecognizerStateBegan || recogniser.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [recogniser translationInView:self.superview];
            CGPoint translatedCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
            [self setCenter:translatedCenter];
            [recogniser setTranslation:CGPointZero inView:self];
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGFloat scale = self.scale;
        if (scale > 1.0f) {
            [self reset:YES];
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(dismissImageView:)]) {
                [self.delegate dismissImageView:self];
            }
        }
    }
}

#pragma mark General Methods

- (void)reset:(BOOL)animated
{
    if ([self isEdited])
    {
        typedef void(^Block)();
        Block block = ^{
            self.transform = CGAffineTransformIdentity;
            self.frame = self.defaultFrame;
        };
        
        typedef void(^FinishBlock)();
        FinishBlock finishBlock = ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(imageViewDidReset:)])
            {
                [self.delegate imageViewDidReset:self];
            }
            
            self.defaultFrame = CGRectZero;
        };
        
        if (animated)
        {
            [UIView animateWithDuration:.25 animations:^{
                block();
            } completion:^(BOOL finished) {
                finishBlock();
            }];
        }
        else
        {
            block();
            finishBlock();
        }
    }
}

- (BOOL)isEdited
{
    BOOL retVal = YES;
    
    if (CGRectEqualToRect(self.frame, self.defaultFrame) || CGRectIsEmpty(self.defaultFrame))
        retVal = NO;
    
    return retVal;
}

- (CGFloat)xscale
{
    CGAffineTransform t = self.transform;
    return sqrt(t.a * t.a + t.c * t.c);
}

- (CGFloat)yscale
{
    CGAffineTransform t = self.transform;
    return sqrt(t.b * t.b + t.d * t.d);
}

- (CGFloat)scale
{
    return MAX(self.xscale, self.yscale);
}

#pragma mark - UIGestureRecognizer Delegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    
    BOOL retVal = YES;
    
    if (gestureRecognizer == self.panRecogniser &&
        (CGRectEqualToRect(self.frame, self.defaultFrame) || CGRectIsEmpty(self.defaultFrame)))
    {
        retVal = NO;
    }
    
    return retVal;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end