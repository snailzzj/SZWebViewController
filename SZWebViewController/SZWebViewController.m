#import "SZWebViewController.h"

#define SZ_NAV_HEIGHT (self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height)

#define SZ_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SZ_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface SZWebViewController () <WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>

@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) WKUserContentController *userContentController;
@property (strong, nonatomic) WKWebViewConfiguration *webViewConfiguration;

@property (strong, nonatomic) UIView *progressView;

@end

@implementation SZWebViewController
{
    NSURL *_url;
    
    NSMutableString *_injectionJavascript;
    
    NSMutableDictionary *_handleDict;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
        
        _injectionJavascript = [NSMutableString stringWithString:@"window.app = { _callbacks: {} };"];
        
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
    
    [self.webView addSubview:self.progressView];
    [self setProgress:0.0];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:_url];
    [self.webView loadRequest:req];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - Public

- (void)registMethod:(NSString *)method useCallback:(BOOL)useCallback handle:(HandleBlock)handle
{
    if (useCallback) {
        [_injectionJavascript appendFormat:
         @"\
         window.app.%@ = function(params, callback) {\n\
            if (typeof window.app._callbacks['%@'] === 'undefined') {\n\
                window.app._callbacks['%@'] = [];\n\
            }\
            if (typeof callback === 'function') {\n\
                window.app._callbacks['%@'].push(callback);\n\
            }\n\
            window.webkit.messageHandlers.%@.postMessage(params);\n\
         };\
         "
         , method, method, method, method, method];
    } else {
        [_injectionJavascript appendFormat:
         @"\
         window.app.%@ = function(params) {\
            window.webkit.messageHandlers.%@.postMessage(params);\
         };\
         "
         , method, method];
    }
    
    [_handleDict setObject:handle forKey:method];
    [self.userContentController addScriptMessageHandler:self name:method];
}

// 调用回调方法
- (void)callJavascriptCallbacks:(NSString *)method withParams:(NSArray<NSString *> *)params
{
    // 遍历执行所有callback
    NSString *js = [NSString stringWithFormat:@"\
    var arrayEvent = window.app._callbacks['%@'];\
    if (arrayEvent instanceof Array) {\
        for (var i=0, length=arrayEvent.length; i<length; i+=1) {\
            if (typeof arrayEvent[i] === 'function') {\
                arrayEvent[i](%@);\
            }\
        }\
    }\
    ", method, [self paramsMerge:params]];
    
    // 执行并清除回调
    __weak typeof(self) weakSelf = self;
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable wtf, NSError * _Nullable error) {
        [weakSelf deleteJavascriptCallback:method];
    }];
}

// 删除某个方法的所有callback
- (void)deleteJavascriptCallback:(NSString *)method
{
    NSString *js = [NSString stringWithFormat:@"\
                    delete window.app._callbacks['%@']\
                    "
                    , method];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)callJavascriptFunction:(NSString *)func withParams:(NSArray<NSString *> *)params
{
    NSString *call = [NSString stringWithFormat:@"%@(%@);", func, [self paramsMerge:params]];
    
    NSLog(@"call js func: %@", call);
    
    [self.webView evaluateJavaScript:call completionHandler:nil];
}

#pragma mark - Private

// 组合参数，所有参数都是字符串
- (NSString *)paramsMerge:(NSArray<NSString *> *)params
{
    __block NSString *paramsMergeRes = @"";
    
    [params enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        paramsMergeRes = [paramsMergeRes stringByAppendingString:[NSString stringWithFormat:@"'%@'", obj]];
        if (obj != params.lastObject) {
            paramsMergeRes = [paramsMergeRes stringByAppendingString:@","];
        }
    }];
    
    return paramsMergeRes;
}

- (void)setProgress:(CGFloat)progress
{
    self.progressView.alpha = 1.0;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.progressView.frame = CGRectMake(0, 0, progress*SZ_SCREEN_WIDTH, 3);
    }];
    
    if (progress >= 1.0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.progressView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.progressView.frame = CGRectMake(0, 0, 0, 3);
            }
        }];
    }
}

#pragma mark - Event

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        [self setProgress:self.webView.estimatedProgress];
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
}

#pragma mark - Setter, Getter

- (WKWebView *)webView
{
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SZ_SCREEN_WIDTH, SZ_SCREEN_HEIGHT) configuration:self.webViewConfiguration];
        _webView.layer.shadowColor = [UIColor blackColor].CGColor;
        _webView.layer.shadowRadius = 3;
        _webView.layer.shadowOpacity = 0.8;
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
    }
    return _webView;
}

- (WKWebViewConfiguration *)webViewConfiguration
{
    if (!_webViewConfiguration) {
        _webViewConfiguration = [[WKWebViewConfiguration alloc] init];
        _webViewConfiguration.userContentController = self.userContentController;
    }
    return _webViewConfiguration;
}

- (WKUserContentController *)userContentController
{
    if (!_userContentController) {
        WKUserScript *script = [[WKUserScript alloc] initWithSource:_injectionJavascript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        
        _userContentController = [[WKUserContentController alloc]init];
        [_userContentController addUserScript:script];
    }
    return _userContentController;
}

- (UIView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIView alloc] init];
        _progressView.backgroundColor = [UIColor redColor];
    }
    return _progressView;
}

@end
