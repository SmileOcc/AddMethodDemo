//
//  Person.h
//  AddMethodDemo
//
//  Created by occ on 2018/3/2.
//  Copyright © 2018年 MO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property(nonatomic,copy,nullable)NSString *age;

- (void)name:(NSString *)name sex:(NSString *)sex;
- (void)name;
- (void)sex;


+ (void)personTest;
@end
