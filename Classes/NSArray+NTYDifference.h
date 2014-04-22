//
//  NSArray+NTYDifference.h
//  Pods
//
//  Created by naoty on 2014/04/23.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (NTYDifference)
- (instancetype)minusArray:(NSArray *)another;
- (instancetype)intersectArray:(NSArray *)another;
@end
