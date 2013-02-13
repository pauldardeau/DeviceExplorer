//
//  SBSysctlViewController.m
//  DeviceExplorer
//
//  Created by Paul Dardeau on 2/11/13.
//  Copyright (c) 2013 Paul Dardeau. All rights reserved.
//

#import <sys/types.h>
#import <sys/sysctl.h>

#import "SBSysctlViewController.h"
#import "SBTextViewController.h"
#import "SBSysctlLookup.h"

// http://www.opensource.apple.com/source/system_cmds/system_cmds-496/sysctl.tproj/sysctl.c

static const int IDX_DEBUG    = 0;
static const int IDX_HW       = 1;
static const int IDX_KERN     = 2;
static const int IDX_MACHDEP  = 3;
static const int IDX_NET      = 4;
static const int IDX_SECURITY = 5;
static const int IDX_USER     = 6;
static const int IDX_VFS      = 7;
static const int IDX_VM       = 8;
static const int IDX_COUNT    = 9;


@interface SBSysctlViewController ()

@end

@implementation SBSysctlViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"sysctl", @"sysctl");

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return IDX_COUNT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString* cellText = @"";

    switch( indexPath.row )
    {
        case IDX_DEBUG:
            cellText = @"debug";
            break;
        case IDX_HW:
            cellText = @"hw";
            break;
        case IDX_KERN:
            cellText = @"kern";
            break;
        case IDX_MACHDEP:
            cellText = @"machdep";
            break;
        case IDX_NET:
            cellText = @"net";
            break;
        case IDX_SECURITY:
            cellText = @"security";
            break;
        case IDX_USER:
            cellText = @"user";
            break;
        case IDX_VFS:
            cellText = @"vfs";
            break;
        case IDX_VM:
            cellText = @"vm";
            break;
    }
    
    cell.textLabel.text = cellText;
    
    return cell;
}

- (NSString*)printSysctlMib:(NSString*)topLevelMib
{
    return [SBSysctlLookup printValuesFor:topLevelMib];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* topLevelMib = nil;
    
    switch( indexPath.row )
    {
        case IDX_DEBUG:
            topLevelMib = @"debug";
            break;
        case IDX_HW:
            topLevelMib = @"hw";
            break;
        case IDX_KERN:
            topLevelMib = @"kern";
            break;
        case IDX_MACHDEP:
            topLevelMib = @"machdep";
            break;
        case IDX_NET:
            topLevelMib = @"net";
            break;
        case IDX_SECURITY:
            topLevelMib = @"security";
            break;
        case IDX_USER:
            topLevelMib = @"user";
            break;
        case IDX_VFS:
            topLevelMib = @"vfs";
            break;
        case IDX_VM:
            topLevelMib = @"vm";
            break;
    }
    
    if( topLevelMib != nil )
    {
        NSString* textToDisplay = [self printSysctlMib:topLevelMib];
        
        if( [textToDisplay length] > 0 )
        {
            UIViewController* viewController = nil;
            viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                    bundle:nil];
            viewController.title = topLevelMib;
            SBTextViewController* textViewController = (SBTextViewController*) viewController;
            textViewController.textToDisplay = textToDisplay;
            
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

@end
