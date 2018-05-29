//
//  NSObject+GDKVO.m
//  GDDKVO
//
//  Created by 龚丹丹 on 2018/5/29.
//  Copyright © 2018年 龚丹丹. All rights reserved.
//

#import "NSObject+GDKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface GDObservationInfo: NSObject
    
    @property (nonatomic, weak)NSObject * observer;
    @property (nonatomic, copy)NSString * key;
    @property (nonatomic, copy)GDObservingBlock block;
    
@end

@implementation GDObservationInfo
    
- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(GDObservingBlock)block
    {
        self = [super init];
        if (self) {
            _observer = observer;
            _key = key;
            _block = block;
        }
        return self;
    }
    
@end

NSString *const kGDDKVOClassPrefix = @"GDDKVOClassPrefix_";
NSString *const kGDDKVOAssociatedObservers = @"GDDKVOAssociatedObservers";

@implementation NSObject (GDKVO)
    
    - (void)GD_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(GDObservingBlock)block {
        SEL setterSelector = NSSelectorFromString(valueForSetter(key));
        Method setterMethod = class_getInstanceMethod([self class], setterSelector);
        if (!setterMethod) {
            NSString * reason = [NSString stringWithFormat:@"object %@ does not have a setter for key %@",self,key];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            return;
        }
        
        Class clazz = object_getClass(self);
        NSString * clazzName = NSStringFromClass(clazz);
        
        if (![clazzName hasPrefix:kGDDKVOClassPrefix]) {
            clazz = [self makeKVOClassWithOriginalClassName:clazzName];
            object_setClass(self, clazz);
        }
        if (![self hasSelector:setterSelector]) {
            const char * types = method_getTypeEncoding(setterMethod);
            class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
        }
        GDObservationInfo * info = [[GDObservationInfo alloc] initWithObserver:observer Key:key block:block];
        NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge const void *)kGDDKVOAssociatedObservers);
        if (!observers) {
            observers = [NSMutableArray array];
            objc_setAssociatedObject(self, (__bridge const void *)kGDDKVOAssociatedObservers, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }else {
            for(GDObservationInfo * info in observers) {
                if (info.observer == observer && [info.key isEqualToString:key]) {
                    return;
                }
            }
        }
        [observers addObject:info];
    }
    
    - (void)GD_removeObserver:(NSObject *)observer forKey:(NSString *)key {
        NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge const void *)kGDDKVOAssociatedObservers);
        GDObservationInfo * infoRemove;
        for (GDObservationInfo * info in observers) {
            if (info.observer == observer && [info.key isEqual:key]) {
                infoRemove = info;
                break;
            }
        }
        [observers removeObject:infoRemove];
    }
    
    - (BOOL)hasSelector:(SEL)selector {
        Class clazz = object_getClass(self);
        unsigned int methodCount = 0;
        Method * methodList = class_copyMethodList(clazz, &methodCount);
        for(unsigned int i = 0; i < methodCount; i++){
            SEL thisSelector = method_getName(methodList[i]);
            if (thisSelector == selector) {
                free(methodList);
                return YES;
            }
        }
        free(methodList);
        return NO;
    }
    
    //根据父类创建一个派生类，然后将父类的isa指针指向派生类
    - (Class)makeKVOClassWithOriginalClassName:(NSString *)originalClazzName {
        NSString * kvoClazzName = [kGDDKVOClassPrefix stringByAppendingString:originalClazzName];
        Class clazz = NSClassFromString(kvoClazzName);
        if (clazz) {
            return  clazz;
        }
        
        Class originalClazz = object_getClass(self);
        Class kvoClazz = objc_allocateClassPair(originalClazz, kvoClazzName.UTF8String, 0);
        Method clazzMethod = class_getInstanceMethod(originalClazz, @selector(class));
        const char * types = method_getTypeEncoding(clazzMethod);
        class_addMethod(kvoClazz, @selector(class), (IMP)kvo_class, types);
        objc_registerClassPair(kvoClazz);
        return kvoClazz;
    }
    
    static NSString * valueForSetter(NSString *key) {
        if (key.length == 0) {
            return @"";
        }
        
        NSString * firstLetter = [[key substringToIndex:1] uppercaseString];
        NSString * remainLetters = [key substringFromIndex:1];
        NSString * result = [NSString stringWithFormat:@"set%@%@:",firstLetter,remainLetters];
        return result;
    }
    
    static NSString * valueForGetter(NSString * key) {
        if (key.length <= 0 || ![key hasPrefix:@"set"] || ![key hasSuffix:@":"]) {
            return nil;
        }
        NSRange range = NSMakeRange(3, key.length - 4);
        NSString * value = [key substringWithRange:range];
        NSString * firstLetter = [[value substringToIndex:1] lowercaseString];
        NSString * remainLetters = [value substringFromIndex:1];
        return [NSString stringWithFormat:@"%@%@",firstLetter,remainLetters];
    }
    
    static Class kvo_class(id self, SEL _cmd) {
        return class_getSuperclass(object_getClass(self));
    }
    
    static void kvo_setter(id self, SEL _cmd, id newValue) {
        NSString * setterName = NSStringFromSelector(_cmd);
        NSString * getterName = valueForGetter(setterName);
        if (!getterName) {
            NSString * reason = [NSString stringWithFormat:@"Object %@ does not have setter %@",self,setterName];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            return;
        }
        id oldValue = [self valueForKey:getterName];
        struct objc_super superClazz = {
            .receiver = self,
            .super_class = class_getSuperclass(object_getClass(self))
        };
        void (*objc_msgSendSuperCasted)(void *,SEL, id) = (void *)objc_msgSendSuper;
        objc_msgSendSuperCasted(&superClazz, _cmd, newValue);
        
        NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge const void *)(kGDDKVOAssociatedObservers));
        for (GDObservationInfo * each in observers) {
            if([each.key isEqualToString:getterName]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    each.block(self, getterName, oldValue, newValue);
                });
            }
        }
        
        
        
        
    }
    
@end
