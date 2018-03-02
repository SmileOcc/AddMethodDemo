//
//  SignatureModel.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/2.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "SignatureModel.h"

@implementation SignatureModel

- (int)myLog:(int)a param:(int)b parm:(int)c
{
    NSLog(@"MyLog:%d,%d,%d", a, b, c);
    return a+b+c;
}

- (void)myLog
{
    NSLog(@"你好,");
}

@end
