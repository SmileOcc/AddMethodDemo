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
#import "UIControl+Event.h"
#import <objc/runtime.h>

#import <objc/message.h>

@interface ViewController ()
@property (nonatomic, strong) UIButton    *oneBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"\n\n----------- 添加方法 -----------");
    [self addMethod];
    NSLog(@"\n\n--------- 发送消息 ----------");
    [self objcMsgSend];
    
    NSLog(@"\n\n----------- 替换方法 -----------");
    [self exchangeChildMethod];
    [self exchangeMethod];
    
    NSLog(@"\n\n----------- person的属性 -----------");
    [self printPerson];
    
    NSLog(@"\n\n----------- NSInvocation用法 -----------");
    [self signatureInvocation];
    
    NSLog(@"\n\n----------- 点击时间延迟 -----------");
    [self addButtonTime];
    NSLog(@"\n\n----------- 动态类 -----------");
    [self allocClass];

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
 *
 * 发送消息
 */
- (void)objcMsgSend {
    
    Person *aObject = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
    
    [aObject name];
    
    // 实例方法调用
    ((void (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("testAction"));
    // 类方法调用
    ((void (*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("personTest"));
    
    // 多个参数
    void (*glt_msgsend)(id, SEL, NSString *, NSString *) = (void (*)(id, SEL, NSString *, NSString *))objc_msgSend;
    glt_msgsend(aObject, @selector(name:sex:), @"JK",@"M");

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


/**
 * 点击时间连续点击间隔处理
 *
 */
- (void)addButtonTime {
    
    _oneBtn =[[UIButton alloc]initWithFrame:CGRectMake(100,100,150,40)];
    [_oneBtn setTitle:@"点击时间间隔"forState:UIControlStateNormal];
    [_oneBtn setTitleColor:[UIColor redColor]forState:UIControlStateNormal];
    _oneBtn.acceptEventInterval =3;
    [self.view addSubview:_oneBtn];
    [_oneBtn addTarget:self action:@selector(btnEvent)forControlEvents:UIControlEventTouchUpInside];

}

- (void)btnEvent {
    NSLog(@"-- 测试间隔");
}


/**
 * 动态创建类
 * objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
 * 添加类 superclass 类是父类   name 类的名字  size_t 类占的空间
 * void objc_disposeClassPair(Class cls) 销毁类
 * void objc_registerClassPair(Class cls) 注册类
 */
- (void)allocClass{
    
    const char * className = "TestClass";
    //要保证全局唯一，key与关联的对象是一一对应关系。必须全局唯一
    static const char *TestClass_nameIvar = "nameIvar";

    Class kclass = objc_getClass(className);
    if (!kclass) {
        kclass = objc_allocateClassPair(NSClassFromString(@"UIViewController"), className, 0);
    }
    
    /**
     *  添加属性
     *
     *  class          类
     *  name           属性名
     *  attributes     参数
     *  attributeCount 参数数量
     */
    
    objc_property_attribute_t type = {"T", "@\"NSString\""};
    objc_property_attribute_t ownership = { "C", "" };
    objc_property_attribute_t backingivar = { "V", ""};
    objc_property_attribute_t attrs[] = {type, ownership, backingivar};
    
    bool success = class_addProperty(kclass, TestClass_nameIvar, attrs, 3);
    if (success) {
        NSLog(@"addIvar success");
        //这个判断不成功？？？
        if (class_isMetaClass(kclass)) {
            NSLog(@"是一个类");
        }
    }
    
    // 向这个类添加一个实例变量
    const char *height = "height";
    class_addIvar(kclass, height, sizeof(id), rint(log2(sizeof(id))), @encode(id));
    
    objc_registerClassPair(kclass);

    if (kclass)
    {        
        id instance = [[kclass alloc] init];
        //给变量赋值
        objc_setAssociatedObject(instance,TestClass_nameIvar, @"123str", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [instance setValue:@15 forKey:[NSString stringWithUTF8String:height]];

        //取值
        id nameValue = objc_getAssociatedObject(instance, TestClass_nameIvar);
        NSLog(@"-- nameValue: %@",nameValue);
        
        // @encode(type)返回的是type的类型（用C语言 char *的表示）
        NSLog(@"instance height = %@", [instance valueForKey:[NSString stringWithUTF8String:height]]);
    }
}

@end
