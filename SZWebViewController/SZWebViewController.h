#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class SZWebViewController;

typedef void(^HandleBlock)(id);

@interface SZWebViewController : UIViewController <UIGestureRecognizerDelegate, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>

@property (strong, nonatomic) UIBarButtonItem *backBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *closeBarButtonItem;
@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) WKUserContentController *userContentController;
@property (strong, nonatomic) WKWebViewConfiguration *webViewConfiguration;

@property (strong, nonatomic) NSMutableArray<UIImageView *> *snapshotViews;
@property (strong, nonatomic) UIView *progressView;

@property (strong, nonatomic) UIPanGestureRecognizer *backPan;

- (instancetype)initWithURL:(NSURL *)url;

- (void)setBackBtnImage:(UIImage *)image;
- (void)setBackBtnTitle:(NSString *)title;
- (void)setBackBtnTintColor:(UIColor *)color;
- (void)setCloseBtnTintColor:(UIColor *)color;
- (void)setTitleColor:(UIColor *)color;

/* default is 'app'. */
- (void)setJavascriptObjectName:(NSString *)name;

- (void)setJavascriptObjectProperty:(NSString *)property handle:(HandleBlock)block;

- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))block;

- (void)callFunction:(NSString *)funcName withArgs:(NSArray<NSString *> *)args;

@end
