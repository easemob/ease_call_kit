//
//  UIStoryboard+Category.h
//  EaseCallDemo
//
//  Created by 杜洁鹏 on 2021/2/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStoryboard (Category)
+ (UIViewController *)loadViewControllerWithClassName:(NSString *)aClassName;
@end

NS_ASSUME_NONNULL_END
