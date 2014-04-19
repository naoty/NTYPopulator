//
//  NTYPopulator.h
//  Pods
//
//  Created by naoty on 2014/04/20.
//
//

#import <Foundation/Foundation.h>

@interface NTYPopulator : NSObject

- (instancetype)initWithModelURL:(NSURL *)modelURL sqliteURL:(NSURL *)sqliteURL;
- (void)run;
- (void)runWithSeedFileURL:(NSURL *)seedFileURL;

@end
