//
//  NSObject+GDKVO.h
//  GDDKVO
//
//  Created by 龚丹丹 on 2018/5/29.
//  Copyright © 2018年 龚丹丹. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^GDObservingBlock) (id observedObject, NSString * observedKey, id oldValue, id newValue);


@interface NSObject (GDKVO)

- (void)GD_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(GDObservingBlock)block;
- (void)GD_removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end
