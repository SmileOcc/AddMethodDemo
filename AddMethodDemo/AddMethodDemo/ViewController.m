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
#import "SignatureModel.h"
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
    
    NSLog(@"----------- NSInvocation用法 -----------");
    [self signatureInvocation];

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

- (void)signatureInvocation {
    
    SignatureModel *signatureModel =  [[SignatureModel alloc] init];
    SEL myMethod = @selector(myLog);
    SEL myMethod2 = @selector(myLog:param:parm:);
    
    // 创建一个函数签名，这个签名可以是任意的，但需要注意，签名函数的参数数量要和调用的一致。
    NSMethodSignature *sig = [[SignatureModel class] instanceMethodSignatureForSelector:myMethod];
    NSMethodSignature *sig2 = [[SignatureModel class] instanceMethodSignatureForSelector:myMethod2];
    
    // 通过签名初始化
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    NSInvocation *invocation2 = [NSInvocation invocationWithMethodSignature:sig2];
    //注意：target不要设置成局部变量
    invocation.target = signatureModel;
    invocation2.target = signatureModel;
    
    // 设置selector
    [invocation setSelector:myMethod];
    [invocation2 setSelector:myMethod2];
    
    int a = 1, b = 2, c = 3;
    // 注意：1、这里设置参数的Index 需要从2开始，因为前两个被selector和target占用。
    [invocation2 setArgument:&a atIndex:2];
    [invocation2 setArgument:&b atIndex:3];
    [invocation2 setArgument:&c atIndex:4];
    
    //将c的值设置为返回值
    [invocation2 setReturnValue:&c];
    int d;
    // 取这个返回值
    [invocation2 getReturnValue:&d];
    NSLog(@"d:%d", d);
    
    //调用方法
    [invocation invoke];
    //[invocation2 invoke];
    [invocation2 invokeWithTarget:signatureModel];
    
    // 获取参数个数
    NSInteger count = sig2.numberOfArguments;
    
    // 打印所有参数类型，
    // 这里打印的结果是  @ : i i i  它们是Objective-C类型编码
    // @ 表示 NSObject* 或 id 类型
    // : 表示 SEL 类型
    // i 表示 int 类型
    for (int i = 0; i < (int)count; i++) {
        const char *argTybe = [sig2 getArgumentTypeAtIndex:i];
        NSLog(@"参数类型 %s",argTybe);
    }
    
    // 获取返回值的类型
    const char *returnType = [sig2 methodReturnType];
    NSLog(@"返回值的类型 %s",returnType);
}



@end
