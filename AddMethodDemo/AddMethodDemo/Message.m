//
//  Message.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/6.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "Message.h"
#import "MessageForwarding.h"
#import <objc/runtime.h>

@implementation Message

//- (void)sendMessage:(NSString *)word
//{
//    NSLog(@"normal way : send message = %@", word);
//}

#pragma mark - Method Resolution
/// override resolveInstanceMethod or resolveClassMethod for changing sendMessage method implementation
//+ (BOOL)resolveInstanceMethod:(SEL)sel
//{
//    if (sel == @selector(sendMessage:)) {
//        class_addMethod([self class], sel, imp_implementationWithBlock(^(id self, NSString *word) {
//            NSLog(@"method resolution way : send message = %@", word);
//        }), "v@*");
//    }
//
//    return YES;
//}

#pragma mark - Fast Forwarding
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector == @selector(sendMessage:) || aSelector == @selector(sendMessage:name:)) {
        return [MessageForwarding new];
    }
    
    return nil;
}


#pragma mark - Normal Forwarding
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *methodSignature = [super methodSignatureForSelector:aSelector];
    
    if (!methodSignature) {
        methodSignature = [NSMethodSignature signatureWithObjCTypes:"v@:*"];
    }
    
    return methodSignature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    MessageForwarding *messageForwarding = [MessageForwarding new];
    
    if ([messageForwarding respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:messageForwarding];
    }
}

@end
