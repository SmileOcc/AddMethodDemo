//
//  Person.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/2.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "Person.h"

@implementation Person

- (void)name{
    NSLog(@"name is Person ");
}

- (void)sex{
    NSLog(@"sex is X ");
}

- (void)name:(NSString *)name sex:(NSString *)sex {
    NSLog(@"name is %@, sex is %@ ",name,sex);
}
+ (void)personTest {
    NSLog(@"---类方法");
}
@end
