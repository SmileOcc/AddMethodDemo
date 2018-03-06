//
//  TwoCtrl.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/6.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "TwoCtrl.h"
#import "Person.h"
#import <objc/runtime.h>

@interface TwoCtrl ()
@property (nonatomic, strong) Person      *person;

@end

@implementation TwoCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    _person = [[Person alloc] init];

    objc_property_t property2 = class_getProperty([_person class],"country");

    if (property2) {
        NSLog(@"%s %s",property_getName(property2) ,property_getAttributes(property2));

        objc_setAssociatedObject(_person,"country", @"123str", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        //取值
        id nameValue = objc_getAssociatedObject(_person, "country");
        NSLog(@"-- nameValue: %@",nameValue);

    }


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
