//
//  SBSysctlLookup.h
//  DeviceExplorer
//
//  Created by Paul Dardeau on 2/11/13.
//  Copyright (c) 2013 Paul Dardeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBSysctlLookup : NSObject

+ (NSString*)printValuesFor:(NSString*)nodeName;

@end
