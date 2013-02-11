//
//  SBDetailViewController.h
//  DeviceExplorer
//
//  Created by Paul Dardeau on 2/11/13.
//  Copyright (c) 2013 Paul Dardeau. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
