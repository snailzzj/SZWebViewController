#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class SZWebViewController;

NS_ASSUME_NONNULL_BEGIN

typedef void(^HandleBlock)(id);

@interface SZWebViewController : UIViewController 

- (instancetype)initWithURL:(NSURL *)url;

- (void)registMethod:(NSString *)method useCallback:(BOOL)useCallback handle:(HandleBlock)handle;

- (void)callJavascriptCallbacks:(NSString *)method withParams:(NSArray<NSString *> *)params;

- (void)callJavascriptFunction:(NSString *)func withParams:(NSArray<NSString *> *)params;

@end

NS_ASSUME_NONNULL_END
