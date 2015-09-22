//
//  JMTextFeiltAutoLayout.m
//  JMTest
//
//  Created by JM on 15-4-16.
//  Copyright (c) 2015年 admin. All rights reserved.
//

#import "JMTextFeiltAutoLayout.h"
#import <objc/runtime.h>
char *const JMScrollViewKeyboardSupport_OldEdgeInset;
@interface UIScrollView (JMScrollViewKeyboardSupport)

@property (nonatomic, assign) UIEdgeInsets oldEdgeInset;

@end

@implementation UIScrollView (JMScrollViewKeyboardSupport)

- (UIEdgeInsets)oldEdgeInset
{
    NSValue *value = objc_getAssociatedObject(self, &JMScrollViewKeyboardSupport_OldEdgeInset);
    
    if (!value) {
        return UIEdgeInsetsZero;
    } else {
        return [value UIEdgeInsetsValue];
    }
}

- (void)setOldEdgeInset:(UIEdgeInsets)SLScrollViewKeyboardSupport_keyboardSupportScrollIndicatorInsets
{
    objc_setAssociatedObject(self, &JMScrollViewKeyboardSupport_OldEdgeInset, [NSValue valueWithUIEdgeInsets:SLScrollViewKeyboardSupport_keyboardSupportScrollIndicatorInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

//-----------------------------------------------------
//static UIEdgeInsets UIEdgeInsetsByAddingInsets(UIEdgeInsets edgeInsets, UIEdgeInsets additionalEdgeInsets)
//{
//    edgeInsets.top += additionalEdgeInsets.top;
//    edgeInsets.left += additionalEdgeInsets.left;
//    edgeInsets.bottom += additionalEdgeInsets.bottom;
//    edgeInsets.right += additionalEdgeInsets.right;
//    
//    return edgeInsets;
//}

static UIView *findFirstResponderInView(UIView *view)
{
    if (view.isFirstResponder) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *firstResponder = findFirstResponderInView(subview);
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    
    return nil;
}

@implementation JMTextFeiltAutoLayout
#pragma mark -
- (id)initWithScrollView:(UIScrollView *)scrollView
{
    if (self = [super init]) {
        _scrollView = scrollView;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHideCallback:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShowCallback:) name:UIKeyboardWillShowNotification object:nil];
//            [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    return self;
}
- (void)_keyboardWillHideCallback:(NSNotification *)notification
{
    NSLog(@"_keyboardWillHideCallback");
//    UIScrollView *scrollView = self.scrollView;
    
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions options = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] | UIViewAnimationOptionBeginFromCurrentState;
    
    [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
        self.scrollView.contentInset = self.scrollView.oldEdgeInset;
    } completion:NULL];
}

- (void)_keyboardWillShowCallback:(NSNotification *)notification
{
    NSLog(@"_keyboardWillShowCallback");
    UIView *firstResponder = findFirstResponderInView([[UIApplication sharedApplication] keyWindow]);
    UIScrollView *scrollView = self.scrollView;
    
    if (![firstResponder isDescendantOfView:scrollView]) {
        return;
    }
    self.scrollView.oldEdgeInset = self.scrollView.contentInset;
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect keyboardFrame = [[UIApplication sharedApplication].keyWindow convertRect:endFrame toView:scrollView];
    
//scrollView 和 键盘 重叠的部分是hiddenFrame（相对于scrollView）//当scrollView的底部在键盘的底部下方，则会出现bug
//    CGRect hiddenFrame = CGRectIntersection(keyboardFrame, scrollView.bounds);

    CGFloat scrollMaxY = CGRectGetMaxY(scrollView.bounds);
    CGFloat keyboardMinY = CGRectGetMinY(keyboardFrame);
    CGFloat hideY = scrollMaxY - keyboardMinY;
    
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions options = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] | UIViewAnimationOptionBeginFromCurrentState;
    
//    CGRect responderFrame = [firstResponder convertRect:firstResponder.bounds toView:scrollView];
//    NSLog(@"oldEdgeInset:%@",NSStringFromUIEdgeInsets(self.scrollView.contentInset));
//    NSLog(@"endFrame:%@",NSStringFromCGRect(endFrame));
//    NSLog(@"keyboardFrame:%@",NSStringFromCGRect(keyboardFrame));
//    NSLog(@"hiddenFrame:%@",NSStringFromCGRect(hiddenFrame));
    [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
        //hiddenFrame 的高度 是应该插入的Insert，以应对弹出后的滑动
        UIEdgeInsets additionsEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, hideY, 0.0f);
//        NSLog(@"additionsEdgeInsets:%@",NSStringFromUIEdgeInsets(additionsEdgeInsets));
        self.scrollView.contentInset = additionsEdgeInsets;//
    } completion:NULL];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
