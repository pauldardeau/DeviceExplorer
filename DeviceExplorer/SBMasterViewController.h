//
//  SBMasterViewController.h
//  DeviceExplorer
//
//  Created by Paul Dardeau on 2/11/13.
//  Copyright (c) 2013 Paul Dardeau. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SBDetailViewController;

@interface SBMasterViewController : UITableViewController

@property (strong, nonatomic) SBDetailViewController *detailViewController;

@end
