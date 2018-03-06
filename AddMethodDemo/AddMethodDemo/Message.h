//
//  Message.h
//  AddMethodDemo
//
//  Created by occ on 2018/3/6.
//  Copyright © 2018年 MO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

- (void)sendMessage:(NSString *)word;
- (void)sendMessage:(NSString *)word name:(NSString *)name;
- (void)sendMsg;
@end
