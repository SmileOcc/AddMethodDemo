//
//  MessageForwarding.h
//  AddMethodDemo
//
//  Created by occ on 2018/3/6.
//  Copyright © 2018年 MO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageForwarding : NSObject
- (void)sendMessage:(NSString *)word;
- (void)sendMessage:(NSString *)word name:(NSString *)name;

@end
