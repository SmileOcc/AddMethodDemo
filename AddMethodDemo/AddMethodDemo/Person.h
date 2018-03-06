//
//  Person.h
//  AddMethodDemo
//
//  Created by occ on 2018/3/2.
//  Copyright © 2018年 MO. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RuntimeBaseProtocol <NSObject>
@optional
- (void)doBaseAction;

@end

@protocol RuntimeProtocol <NSObject,RuntimeBaseProtocol>

@optional
- (void)doOptionalAction;

@end


@interface Person : NSObject<RuntimeProtocol>

@property(nonatomic,copy,nullable)NSString *age;

- (void)name:(NSString *)name sex:(NSString *)sex;
- (void)name;
- (void)sex;


+ (void)personTest;
@end
