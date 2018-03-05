//
//  UIControl+Event.h
//  AddMethodDemo
//
//  Created by occ on 2018/3/5.
//  Copyright © 2018年 MO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControl (Event)
@property(nonatomic,assign) NSTimeInterval acceptEventInterval;
@property(nonatomic)BOOL ignoreEvent;

@end
