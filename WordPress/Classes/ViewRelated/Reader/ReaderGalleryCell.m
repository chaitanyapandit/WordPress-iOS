#import <AFNetworking/UIImageView+AFNetworking.h>

#import "ReaderGalleryCell.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"

#define kNotification_ReaderGalleryCellDidLoadImage @"ReaderGalleryCellDidLoadImage"

@interface ReaderGalleryCell ()

@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation ReaderGalleryCell

#pragma mark Init & Dealloc

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadImageNotification:) name:kNotification_ReaderGalleryCellDidLoadImage object:nil];
}

#pragma mark Notification Listners

- (void)didLoadImageNotification:(NSNotification *)notification
{
    if ([self.media.mediaID isEqual:[notification.userInfo objectForKey:@"mediaID"]]) {
        self.imageView.image = notification.object;
        [_activityIndicator removeFromSuperview];
        _activityIndicator = nil;
    }
}

#pragma mark General Methods

- (UIImageView *)imageView
{
    if (_imageView)
        return _imageView;
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    [self.contentView addSubview:_imageView];
    _imageView.backgroundColor = [UIColor lightGrayColor];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:@{@"imageView":_imageView}]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:@{@"imageView":_imageView}]];
    
    return _imageView;
}

- (UIActivityIndicatorView *)activityIndicator {

    if (_activityIndicator)
        return _activityIndicator;
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.contentView insertSubview:_activityIndicator aboveSubview:self.imageView];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0f]];
    
    return _activityIndicator;
}

- (void)setMedia:(Media *)media
{
    _media = media;
    NSNumber *mediaID = media.mediaID;
    
    if (mediaID && media.remoteURL) {
        [self.activityIndicator startAnimating];
        
        [self.imageView setImageWithURLRequest:[self requestWithURL:[NSURL URLWithString:_media.remoteURL]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ReaderGalleryCellDidLoadImage object:image userInfo:@{@"mediaID":mediaID}];
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ReaderGalleryCellDidLoadImage object:nil userInfo:@{@"mediaID":mediaID}];
        }];
    }
}

- (NSURLRequest *)requestWithURL:(NSURL *)url {
    
    NSString *absoluteString = url.absoluteString;
    if (![absoluteString hasPrefix:@"https"]) {
        NSString *sslURL = [absoluteString stringByReplacingOccurrencesOfString:@"http" withString:@"https"];
        url = [[NSURL alloc] initWithString:sslURL];
    }
    
    AccountService *acctServ = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    NSString *token = [[acctServ defaultWordPressComAccount] authToken];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString *headerValue = [[NSString alloc] initWithFormat:@"Bearer %@", token];
    [request addValue:headerValue forHTTPHeaderField:@"Authorization"];
    
    return request;
}

@end
