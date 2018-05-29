# GDKVO
因为使用系统的KVO是在太头疼，一不小心就来个crash，特别是当我必须要经常对同一个属性进行监听和移除的时候，所以情急之下，写了个demo，用法如下，很简单（也是参考很多博客啦~）

	- (void)addObserver {
		  self.name = @"hello";
		  [self GD_addObserver:self forKey:NSStringFromSelector(@selector(name)) withBlock:^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
			  if ([observedKey isEqualToString:@"name"]) {
				  NSLog(@"oldvalue is %@, new value is %@",oldValue,newValue);
			  }
			}];
		  	self.name = @"world";
  	}
    
	- (void)removeObserver {
		[self GD_removeObserver:self forKey:@"name"];
	}
- 注意这里重复添加同一个对象的同一个属性的监听是会自动过滤的，不会让用户对同一个对象的同一个属性重复监听
- 移除监听不受影响，多次重复移除也不会有任何问题
