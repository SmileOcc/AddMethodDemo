//
//  UIControl+Event.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/5.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "UIControl+Event.h"
#import <objc/runtime.h>

static const char *UIControl_acceptEventInterval = "UIControl_acceptEventInterval";
static const char *UIControl_ignoreEvent = "UIControl_ignoreEvent";


@implementation UIControl (Event)

/**
 * 动态添加两个属性
 * 
 */
- (void)setAcceptEventInterval:(NSTimeInterval)acceptEventInterval
{
    objc_setAssociatedObject(self,UIControl_acceptEventInterval, @(acceptEventInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSTimeInterval)acceptEventInterval {
    return[objc_getAssociatedObject(self,UIControl_acceptEventInterval) doubleValue];
}
-(void)setIgnoreEvent:(BOOL)ignoreEvent{
    objc_setAssociatedObject(self,UIControl_ignoreEvent, @(ignoreEvent), OBJC_ASSOCIATION_ASSIGN);
}
-(BOOL)ignoreEvent{
    return[objc_getAssociatedObject(self,UIControl_ignoreEvent) boolValue];
}

/**
 * 交换点击事件的方法
 */
+(void)load {
    Method old = class_getInstanceMethod(self,@selector(sendAction:to:forEvent:));
    Method new = class_getInstanceMethod(self,@selector(_sendAction:to:forEvent:));
    
    BOOL didAddMethod = class_addMethod(self, @selector(sendAction:to:forEvent:), method_getImplementation(new), method_getTypeEncoding(new));
    
    if (didAddMethod) {
        class_replaceMethod(self,  @selector(_sendAction:to:forEvent:), method_getImplementation(old), method_getTypeEncoding(old));
    }
    else {
        method_exchangeImplementations(old, new);
    }

    
}
- (void)_sendAction:(SEL)action to:(id)target forEvent:(UIEvent*)event
{
    if(self.ignoreEvent)return;
    if(self.acceptEventInterval>0)
    {
        self.ignoreEvent=YES;
        [self performSelector:@selector(setIgnoreEventWithNo) withObject:nil afterDelay:self.acceptEventInterval];
    }
    [self _sendAction:action to:target forEvent:event];
}
-(void)setIgnoreEventWithNo{
    self.ignoreEvent=NO;
}

@end
