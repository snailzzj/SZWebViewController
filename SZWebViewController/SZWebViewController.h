#import <UIKit/UIKit.h>

@interface SZWebViewController : UIViewController

- (instancetype)initWithURL:(NSString *)url;

- (void)setBackBtnImage:(UIImage *)image;
- (void)setBackBtnTitle:(NSString *)title;
- (void)setBackBtnTintColor:(UIColor *)color;
- (void)setCloseBtnTintColor:(UIColor *)color;
- (void)setTitleColor:(UIColor *)color;

@end
