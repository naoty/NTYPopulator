//
//  NSArray+NTYDifference.m
//  Pods
//
//  Created by naoty on 2014/04/23.
//
//

#import "NSArray+NTYDifference.h"

@implementation NSArray (NTYDifference)

- (instancetype)minusArray:(NSArray *)another
{
    NSMutableOrderedSet *selfOrderedSet = [NSMutableOrderedSet orderedSetWithArray:self];
    NSMutableOrderedSet *anotherOrderedSet = [NSMutableOrderedSet orderedSetWithArray:another];
    [selfOrderedSet minusOrderedSet:anotherOrderedSet];
    
    return [selfOrderedSet array];
}

- (instancetype)intersectArray:(NSArray *)another
{
    NSMutableOrderedSet *selfOrderedSet = [NSMutableOrderedSet orderedSetWithArray:self];
    NSMutableOrderedSet *anotherOrderedSet = [NSMutableOrderedSet orderedSetWithArray:another];
    [selfOrderedSet intersectOrderedSet:anotherOrderedSet];
    
    return [selfOrderedSet array];
}

@end
