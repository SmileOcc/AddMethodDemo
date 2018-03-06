//
//  MessageForwarding.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/6.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "MessageForwarding.h"

@implementation MessageForwarding

- (void)sendMessage:(NSString *)word
{
    NSLog(@"fast forwarding way : send message = %@", word);
}

- (void)sendMessage:(NSString *)word name:(NSString *)name {
    NSLog(@"fast forwarding way : %@ - %@",word,name);
}

@end
