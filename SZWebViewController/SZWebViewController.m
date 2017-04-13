#import "SZWebViewController.h"

#define SZ_NAV_HEIGHT (self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height)

#define SZ_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SZ_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface SZWebViewController ()

@end

@implementation SZWebViewController
{
    NSURL *_url;
    
    NSMutableDictionary *_handleDict;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
        
        _handleDict = [NSMutableDictionary dictionary];
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
    
    NSURLRequest *req = [NSURLRequest requestWithURL:_url];
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
    UIButton *btn = (UIButton *)self.backBarButtonItem.customView;
    [btn setImage:image forState:UIControlStateNormal];
}

- (void)setBackBtnTitle:(NSString *)title
{
    UIButton *btn = (UIButton *)self.backBarButtonItem.customView;
    [btn setTitle:title forState:UIControlStateNormal];
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

- (void)setJavascriptObjectName:(NSString *)name
{
    
}

- (void)setJavascriptObjectProperty:(NSString *)property handle:(HandleBlock)block
{
    [_handleDict setObject:block forKey:property];
    [self.userContentController addScriptMessageHandler:self name:property];
}

- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))block
{
    [self.webView evaluateJavaScript:script completionHandler:block];
}

- (void)callFunction:(NSString *)funcName withArgs:(NSArray<NSString *> *)args
{
    __block NSString *argsMergeRes = @""; //[args componentsJoinedByString:@","];
    
    //组合参数
    [args enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        argsMergeRes = [argsMergeRes stringByAppendingString:[NSString stringWithFormat:@"'%@'", obj]];
        if (obj != args.lastObject) {
            argsMergeRes = [argsMergeRes stringByAppendingString:@","];
        }
    }];
    NSString *call = [NSString stringWithFormat:@"%@(%@);", funcName, argsMergeRes];
    
    NSLog(@"call js func: %@", call);
    
    [self evaluateJavaScript:call completionHandler:nil];
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

- (CGFloat)webViewHeight
{
    if (self.navigationController.navigationBar.translucent) {
        return SZ_SCREEN_HEIGHT;
    }
    return SZ_SCREEN_HEIGHT-SZ_NAV_HEIGHT;
}

- (void)setWebViewX:(CGFloat)x
{
    self.webView.frame = CGRectMake(x, 0, SZ_SCREEN_WIDTH, [self webViewHeight]);
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

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    HandleBlock block = [_handleDict objectForKey:message.name];
    if (block) {
        block(message.body);
    }
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
    
    //全局app对象初始化
    [self evaluateJavaScript:@"app={};" completionHandler:nil];
    for (NSString *key in _handleDict.allKeys) {
        NSString *js = [NSString stringWithFormat:
                        @"app.%@ = function(args) {                                 \
                            window.webkit.messageHandlers.%@.postMessage(args)      \
                        };"
                        , key, key];
        [self evaluateJavaScript:js completionHandler:nil];
    }
    
    //网页载入完成回调
    [self evaluateJavaScript:@"AppLoadFinished();" completionHandler:nil];
    
    [self resetLeftBarButtonItems];
}

#pragma mark - Setter, Getter

- (WKWebView *)webView
{
    if (!_webView) {
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SZ_SCREEN_WIDTH, [self webViewHeight]) configuration:self.webViewConfiguration];
        _webView.layer.shadowColor = [UIColor blackColor].CGColor;
        _webView.layer.shadowRadius = 3;
        _webView.layer.shadowOpacity = 0.8;
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _webView;
}

- (WKWebViewConfiguration *)webViewConfiguration
{
    if (!_webViewConfiguration) {
        _webViewConfiguration = [[WKWebViewConfiguration alloc]init];
        _webViewConfiguration.userContentController = self.userContentController;
    }
    return _webViewConfiguration;
}

- (WKUserContentController *)userContentController
{
    if (!_userContentController) {
        _userContentController = [[WKUserContentController alloc]init];
    }
    return _userContentController;
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
