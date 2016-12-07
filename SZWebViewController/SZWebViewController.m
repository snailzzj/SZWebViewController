#import <WebKit/WebKit.h>

#import "SZWebViewController.h"

#define SZ_NAV_HEIGHT (self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height)

#define SZ_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SZ_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface SZWebViewController () <UIGestureRecognizerDelegate, WKNavigationDelegate>

@property (strong, nonatomic) UIBarButtonItem *backBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *closeBarButtonItem;
@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSMutableArray<UIImageView *> *snapshotViews;
@property (strong, nonatomic) UIView *progressView;

@property (strong, nonatomic) UIPanGestureRecognizer *backPan;

@end

@implementation SZWebViewController
{
    NSString *_url;
}

- (instancetype)initWithURL:(NSString *)url
{
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

#pragma mark - Override

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.webView];
    [self.webView addGestureRecognizer:self.backPan];
    [self.webView addSubview:self.progressView];
    [self resetLeftBarButtonItems];
    [self setProgress:0.0];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:_url]];
    [self.webView loadRequest:req];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
}

#pragma mark - Public

- (void)setBackBtnImage:(UIImage *)image
{
    self.backBarButtonItem.image = image;
}

- (void)setBackBtnTitle:(NSString *)title
{
    self.backBarButtonItem.title = title;
}

- (void)setBackBtnTintColor:(UIColor *)color
{
    [self.backBarButtonItem.customView setTintColor:color];
}

- (void)setCloseBtnTintColor:(UIColor *)color
{
    [self.closeBarButtonItem setTintColor:color];
}

- (void)setTitleColor:(UIColor *)color
{
    self.titleLabel.textColor = color;
}

#pragma mark - Private

- (void)resetLeftBarButtonItems
{
    UIBarButtonItem *leftSpaceFix = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    leftSpaceFix.width = -11;
    
    NSArray *backItems = @[leftSpaceFix, self.backBarButtonItem];
    NSArray *closeItems = @[leftSpaceFix, self.closeBarButtonItem];
    
    NSArray *resultItems = backItems;
    if ([self.webView canGoBack]) {
        resultItems = [resultItems arrayByAddingObjectsFromArray:closeItems];
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
        self.backPan.enabled = YES;
    }
    else {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
        self.backPan.enabled = NO;
    }
    
    self.navigationItem.leftBarButtonItems = resultItems;
}

- (void)setProgress:(CGFloat)progress
{
    self.progressView.alpha = 1.0;

    [UIView animateWithDuration:0.2 animations:^{
        self.progressView.frame = CGRectMake(0, [self progressViewY], progress*SZ_SCREEN_WIDTH, 3);
    }];
    
    if (progress >= 1.0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.progressView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.progressView.frame = CGRectMake(0, [self progressViewY], 0, 3);
            }
        }];
    }
}

- (CGFloat)progressViewY
{
    if (self.navigationController.navigationBar.translucent) {
        return SZ_NAV_HEIGHT;
    }
    return 0;
}

- (void)setWebViewX:(CGFloat)x
{
    self.webView.frame = CGRectMake(x, 0, SZ_SCREEN_WIDTH, SZ_SCREEN_HEIGHT);
}

#pragma mark - Event

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        [self setProgress:self.webView.estimatedProgress];
    }
}

- (void)onBackPan:(UIPanGestureRecognizer *)pan
{
    static BOOL isDragging = NO;
    
    CGPoint pt = [pan locationInView:[UIApplication sharedApplication].keyWindow];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        if (pt.x < 40) {
            isDragging = YES;
        }
    }
    else if (pan.state == UIGestureRecognizerStateChanged) {
        if (isDragging) {
            [self setWebViewX:pt.x];
        }
    }
    else if (pan.state == UIGestureRecognizerStateEnded) {
        isDragging = NO;
        
        if (pt.x > SZ_SCREEN_WIDTH/2) {
            [UIView animateWithDuration:0.2 animations:^{
                [self setWebViewX:SZ_SCREEN_WIDTH];
            } completion:^(BOOL finished) {
                if (finished) {
                    [self setWebViewX:0];
                    [self onBack];
                }
            }];
        }
        else {
            [UIView animateWithDuration:0.2 animations:^{
                [self setWebViewX:0];
            }];
        }
    }
}

- (void)onBack
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
    else {
        [self onClose];
    }
}

- (void)onClose
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    self.title = webView.title;
    
    [self resetLeftBarButtonItems];
}

#pragma mark - Setter, Getter

- (WKWebView *)webView
{
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SZ_SCREEN_WIDTH, SZ_SCREEN_HEIGHT)];
        _webView.layer.shadowColor = [UIColor blackColor].CGColor;
        _webView.layer.shadowRadius = 3;
        _webView.layer.shadowOpacity = 0.8;
        _webView.navigationDelegate = self;
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _webView;
}

- (UIView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIView alloc]init];
        _progressView.backgroundColor = [UIColor redColor];
    }
    return _progressView;
}

- (UIBarButtonItem *)backBarButtonItem
{
    if (!_backBarButtonItem) {
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [backBtn setFrame:CGRectMake(0, 0, 30, 40)];
        [backBtn setImage:[UIImage imageNamed:@"icon_back"] forState:UIControlStateNormal];
        [backBtn setTitle:@"" forState:UIControlStateNormal];
        [backBtn setTintColor:[UIColor redColor]];
        [backBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        [_backBarButtonItem setTintColor:[UIColor redColor]];
    }
    return _backBarButtonItem;
}

- (UIBarButtonItem *)closeBarButtonItem
{
    if (!_closeBarButtonItem) {
        _closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose)];
        [_closeBarButtonItem setTintColor:[UIColor redColor]];
    }
    return _closeBarButtonItem;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor redColor];
        self.navigationItem.titleView = _titleLabel;
    }
    return _titleLabel;
}

- (UIPanGestureRecognizer *)backPan
{
    if (!_backPan) {
        _backPan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(onBackPan:)];
    }
    return _backPan;
}

@end
