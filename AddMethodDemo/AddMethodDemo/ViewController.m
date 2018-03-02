//
//  ViewController.m
//  AddMethodDemo
//
//  Created by occ on 2018/3/2.
//  Copyright © 2018年 MO. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "Boy.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"----------- 添加方法 -----------");

    [self addMethod];
    
    NSLog(@"----------- 替换方法 -----------");
    [self exchangeChildMethod];
    [self exchangeMethod];
    
    [self printPerson];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
/**
 *  添加方法
 */

- (void)addMethod {
    
    Person *p = [[Person alloc]init];
    class_addMethod([Person class], @selector(testParam:), class_getMethodImplementation([ViewController class], @selector(addParam:)), "v@:@");
    [p performSelector:@selector(testParam:) withObject:@"传入参数"];
    
    class_addMethod([Person class], @selector(test), class_getMethodImplementation([ViewController class], @selector(add)), "v@:");
    [p performSelector:@selector(test)];
    
    class_addMethod([Person class], @selector(testParamBack:), class_getMethodImplementation([ViewController class], @selector(addParamBack:)), "s@:@");
    NSString *back = [p performSelector:@selector(testParamBack:) withObject:@33];
    NSLog(@"--back: %@",back);
    
    class_addMethod([Person class], @selector(testCC:), (IMP)addCC, "v@:@");
    [p performSelector:@selector(testCC:) withObject:@"123"];
    
    
    //严谨
    swizzleMethod([self class], @selector(testAction), @selector(addAction));
    [self performSelector:@selector(testAction)];
}

/**
 *  方法交换
 */
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    NSLog(@"viewWillAppear");
}

- (void)occ_viewWillAppear {
    NSLog(@"occ_viewWillAppear");
}


- (void)exchangeMethod{
    
    Method old = class_getInstanceMethod([ViewController class], @selector(viewWillAppear:));
    Method new = class_getInstanceMethod([ViewController class], @selector(occ_viewWillAppear));
    
    BOOL didAddMethod = class_addMethod([self class], @selector(viewWillAppear:), method_getImplementation(new), method_getTypeEncoding(new));
    
    // the method doesn’t exist and we just added one
    if (didAddMethod) {
        class_replaceMethod([self class],  @selector(occ_viewWillAppear), method_getImplementation(old), method_getTypeEncoding(old));
    }
    else {
        method_exchangeImplementations(old, new);
    }
}

/**
 * 替换子类方法
 */
- (void)exchangeChildMethod {
    
    /**
     * ⚠️⚠️⚠️❌❌❌
     * 如果Boy类里没有复写父类的name方法，
     * 此时直接用交换方法，会把父类的name方法替换
     */
    Person *p = [[Person alloc]init];
    Boy *s = [[Boy alloc]init];
    
    [p name]; //name is Person
    [p sex];  //sex is X
    
    Method origMethod = class_getInstanceMethod([Boy class], @selector(name));
    Method overrideMethod = class_getInstanceMethod([self class], @selector(sonName));
    
    method_exchangeImplementations(origMethod,overrideMethod);
    [s name];//--- son name
    [p name];//--- son name
    
    /**✅✅✅
     * 如果Boy类里没有复写父类的name方法，
     * 用class_addMethod判断Boy类中是否有这个方法，
     * didAddMethod： yes 表示Boy类中原先没有，现在添加成功，在class_replaceMethod一下，
     * didAddMethod： no 表示Boy类中有，直接交换
     */
    
    Method origMethod2 = class_getInstanceMethod([Boy class], @selector(sex));
    Method overrideMethod2 = class_getInstanceMethod([self class], @selector(sonSex));
    
    BOOL didAddMethod = class_addMethod([Boy class], @selector(sex), method_getImplementation(overrideMethod2), method_getTypeEncoding(overrideMethod2));
    
    if (didAddMethod) {
        class_replaceMethod([Boy class], @selector(sonSex), method_getImplementation(origMethod2), method_getTypeEncoding(origMethod2));
    }
    else {
        method_exchangeImplementations(origMethod2, overrideMethod2);
    }
    
    [s sex];//--- son sex
    [p sex];//sex is X
}

- (void)sonName {
    NSLog(@"--- son name");
}

- (void)sonSex {
    NSLog(@"--- son sex");
}


/**
 *  输出一些person的属性
 */
- (void)printPerson{
    
    NSLog(@"\n\n\n---------------ivar list-----------------");
    unsigned int count;
    //ivar
    Ivar *ivars = class_copyIvarList([Person class], &count);
    for (int i = 0; i < count; i ++) {
        Ivar ivar = ivars[i];
        NSLog(@"ivar === %s",ivar_getName(ivar));
    }
    NSLog(@"\n\n\n--------------method list------------------");
    Method *methods = class_copyMethodList([Person class], &count);
    for (int i = 0; i < count; i ++) {
        Method method  = methods[i];
        NSLog(@"method == %s",method_getName(method));
    }
    NSLog(@"\n\n\n--------------property list------------------");
    objc_property_t *propertys = class_copyPropertyList([Person class], &count);
    for (int i = 0; i < count; i ++) {
        objc_property_t property = propertys[i];
        NSLog(@"property === %s",property_getName(property));
    }
}
- (void)addParam:(NSString *)str{
    NSLog(@"----- %@",str);
}

- (void)add{
    NSLog(@"----- test");
}

- (NSString *)addParamBack:(NSInteger)a{
    NSLog(@"----- paramBack: %li",(long)a);
    return @"occ_";
}

- (void)addAction {
    NSLog(@"occ_addAction");
}


//C 写法
void addCC(id self, SEL _cmd, NSString *name) {
    NSLog(@"occ_ add name %@", name);
}


void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector)
{
    // the method might not exist in the class, but in its superclass
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // class_addMethod will fail if original method already exists
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    // the method doesn’t exist and we just added one
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}

@end
