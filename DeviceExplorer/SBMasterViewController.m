//
//  SBMasterViewController.m
//  DeviceExplorer
//
//  Created by Paul Dardeau on 2/11/13.
//  Copyright (c) 2013 Paul Dardeau. All rights reserved.
//

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <pwd.h>
#include <sys/param.h>
#include <sys/mount.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import "SBMasterViewController.h"
#import "SBMachViewController.h"
#import "SBSysctlViewController.h"
#import "SBDetailViewController.h"
#import "SBTextViewController.h"


static const int IDX_CORETELEPHONY = 0;
static const int IDX_DEVICESTORAGE = 1;
static const int IDX_MACH          = 2;
static const int IDX_NSLOCALE      = 3;
static const int IDX_NSTIMEZONE    = 4;
static const int IDX_PROCESSLIST   = 5;
static const int IDX_SYSCTL        = 6;
static const int IDX_UIDEVICE      = 7;
static const int IDX_COUNT         = 8;


@interface SBMasterViewController ()
{
}
@end

@implementation SBMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Device Explorer", @"Device Explorer");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)queryDeviceStorage
{
    NSMutableString* output = [[NSMutableString alloc] init];

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    struct statfs tStats;
    statfs([[paths lastObject] cString], &tStats);
    float total_space = (float)(tStats.f_blocks * tStats.f_bsize);
    [output appendFormat:@"total space = %.0f bytes\n", total_space];
    
    NSError* error = nil;
    NSDictionary* dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    
    if( dictionary != nil )
    {
        NSNumber* fileSystemFreeSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        if( fileSystemFreeSizeInBytes != nil )
        {
            [output appendFormat:@"free space = %@ bytes\n", fileSystemFreeSizeInBytes];
        }
    }
    
    return output;
}

- (NSString*)queryProcessList
{
    NSMutableString* output = [[NSMutableString alloc] init];

    int rc = 0;
    size_t length = 0;
    static const int name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    
    // Call sysctl with a NULL buffer to get proper length
    rc = sysctl((int *)name,
                (sizeof(name) / sizeof(*name)) - 1,
                NULL,
                &length,
                NULL,
                0);
    
    if( rc == 0 )
    {
        // Allocate buffer
        struct kinfo_proc* proc_list = malloc(length);
        
        if( proc_list != NULL )
        {
            // Get the actual process list
            rc = sysctl((int *)name,
                        (sizeof(name) / sizeof(*name)) - 1,
                        proc_list,
                        &length,
                        NULL,
                        0);
            if( rc == 0 )
            {
                const int proc_count = length / sizeof(struct kinfo_proc);
                [output appendFormat:@"process count = %d\n", proc_count];
                
                NSMutableDictionary* mapPidsToProcNames = [[NSMutableDictionary alloc] initWithCapacity:proc_count];
    
                for (int i = 0; i < proc_count; ++i)
                {
                    // uid: kp_eproc.e_ucred.cr_uid
                    NSNumber* pidValue =
                        [NSNumber numberWithInt:proc_list[i].kp_proc.p_pid];
                    NSString* procName =
                        [NSString stringWithUTF8String:proc_list[i].kp_proc.p_comm];
                    
                    [mapPidsToProcNames setObject:procName forKey:pidValue];
                }

                NSArray* sortedPids = [[mapPidsToProcNames allKeys] sortedArrayUsingSelector: @selector(compare:)];
                
                for( NSNumber* pidValue in sortedPids )
                {
                    [output appendFormat:@"%d\t%@\n",
                        [pidValue intValue],
                        [mapPidsToProcNames objectForKey:pidValue]];
                }
            }
            else
            {
                [output appendString:@"unable to retrieve process list"];
            }
            
            free(proc_list);
        }
    }
    else
    {
        [output appendString:@"unable to retrieve process list"];
    }
    
    return output;
}

- (NSString*)queryNSTimeZone
{
    NSMutableString* output = [[NSMutableString alloc] init];
    
    NSTimeZone* timeZone = [NSTimeZone systemTimeZone];
    if( timeZone != nil )
    {
        [output appendFormat:@"abbreviation = %@\n", [timeZone abbreviation]];
        
        [output appendFormat:@"daylightSavingTimeOffset = %.0f\n",
            [timeZone daylightSavingTimeOffset]];
        
        [output appendFormat:@"description = %@\n", [timeZone description]];
        
        [output appendFormat:@"isDaylightSavingTime = %@\n",
            [timeZone isDaylightSavingTime] ? @"YES" : @"NO"];
        
        [output appendFormat:@"name = %@\n", [timeZone name]];
        
        [output appendFormat:@"secondsFromGMT = %d\n", [timeZone secondsFromGMT]];
    }
    else
    {
        [output appendString:@"no time zone information available"];
    }
    
    return output;
}

- (NSString*)queryNSLocale
{
    NSMutableString* output = [[NSMutableString alloc] init];

    NSLocale* locale = [NSLocale currentLocale];

    if( locale != nil )
    {
        NSString* countryCode = [locale objectForKey:NSLocaleCountryCode];
        
        if( countryCode != nil )
        {
            [output appendFormat:@"NSLocaleCountryCode = %@\n", countryCode];
            
            NSString* countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
            if( countryName != nil )
            {
                [output appendFormat:@"Country display name = %@\n", countryName];
            }
        }

        NSArray* preferredLanguages = [NSLocale preferredLanguages];
        if( [preferredLanguages count] > 0 )
        {
            [output appendFormat:@"Preferred language = %@\n", [preferredLanguages objectAtIndex:0]];
        }
    }
    else
    {
        [output appendString:@"no locale information available"];
    }
    
    return output;
}

- (NSString*)queryCoreTelephony
{
    NSMutableString* output = [[NSMutableString alloc] init];

    CTTelephonyNetworkInfo* networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier* carrier = [networkInfo subscriberCellularProvider];

    if( [carrier.carrierName length] > 0 )
    {
        [output appendFormat:@"CTCarrier.allowsVOIP = %@\n", carrier.allowsVOIP ? @"YES" : @"NO"];
        [output appendFormat:@"CTCarrier.carrierName = %@\n", carrier.carrierName];
        [output appendFormat:@"CTCarrier.isoCountryCode = %@\n", carrier.isoCountryCode];
        [output appendFormat:@"CTCarrier.mobileCountryCode = %@\n", carrier.mobileCountryCode];
        [output appendFormat:@"CTCarrier.mobileNetworkCode = %@\n", carrier.mobileNetworkCode];
    }
    else
    {
        [output appendString:@"no carrier information available"];
    }
    
    return output;
}

- (NSString*)queryUIDevice
{
    NSMutableString* output = [[NSMutableString alloc] init];
    UIDevice* currentDevice = [UIDevice currentDevice];
    
    const float batteryLevel = currentDevice.batteryLevel;
    if( batteryLevel >= 0.0 )
    {
        [output appendFormat:@"batteryLevel = %f\n",
            currentDevice.batteryLevel];
    }
    else
    {
        [output appendString:@"batteryLevel = unknown\n"];
    }
    
    [output appendFormat:@"batteryMonitoringEnabled = %@\n",
        currentDevice.batteryMonitoringEnabled ? @"YES" : @"NO"];
    
    UIDeviceBatteryState batteryState = currentDevice.batteryState;
    NSString* batteryStateDesc = @"unknown";
    
    switch( batteryState )
    {
        case UIDeviceBatteryStateUnplugged:
            batteryStateDesc = @"unplugged";
            break;
        case UIDeviceBatteryStateCharging:
            batteryStateDesc = @"charging";
            break;
        case UIDeviceBatteryStateFull:
            batteryStateDesc = @"full";
            break;
    }
    
    [output appendFormat:@"batteryState = %@\n", batteryStateDesc];
    
    [output appendFormat:@"generatesDeviceOrientationNotifications = %@\n",
        currentDevice.generatesDeviceOrientationNotifications ? @"YES" : @"NO"];
    
    if( [currentDevice respondsToSelector:@selector(identifierForVendor)] )
    {
        NSUUID* identifier = currentDevice.identifierForVendor;
        [output appendFormat:@"identifierForVendor = %@\n",
            [identifier UUIDString]];
    }
    
    [output appendFormat:@"localizedModel = %@\n",
        currentDevice.localizedModel];
    
    [output appendFormat:@"model = %@\n", currentDevice.model];
    
    [output appendFormat:@"multitaskingSupported = %@\n",
        currentDevice.multitaskingSupported ? @"YES" : @"NO"];
    
    [output appendFormat:@"name = %@\n", currentDevice.name];
    
    UIDeviceOrientation orientation = currentDevice.orientation;
    NSString* orientationDesc = @"unkown";
    
    switch( orientation )
    {
        case UIDeviceOrientationPortrait:
            orientationDesc = @"portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientationDesc = @"portrait upside down";
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientationDesc = @"landscape left";
            break;
        case UIDeviceOrientationLandscapeRight:
            orientationDesc = @"landscape right";
            break;
        case UIDeviceOrientationFaceUp:
            orientationDesc = @"face up";
            break;
        case UIDeviceOrientationFaceDown:
            orientationDesc = @"face down";
            break;
    }
    
    [output appendFormat:@"orientation = %@\n", orientationDesc];
    
    [output appendFormat:@"proximityMonitoringEnabled = %@\n",
        currentDevice.proximityMonitoringEnabled ? @"YES" : @"NO"];
    
    [output appendFormat:@"proximityState = %@\n",
        currentDevice.proximityState ? @"close to user" : @"not close to user"];
    
    [output appendFormat:@"systemName = %@\n", currentDevice.systemName];

    [output appendFormat:@"systemVersion = %@\n", currentDevice.systemVersion];

    NSString* uiIdiom;
    
    if( currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        uiIdiom = @"iPad";
    }
    else
    {
        uiIdiom = @"iPhone";
    }
    
    [output appendFormat:@"userInterfaceIdiom = %@\n", uiIdiom];
    
    return output;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return IDX_COUNT;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    const int currentRow = indexPath.row;

    if( currentRow == IDX_CORETELEPHONY )
    {
        cell.textLabel.text = @"CoreTelephony";
    }
    else if( currentRow == IDX_MACH )
    {
        cell.textLabel.text = @"Mach";
    }
    else if( currentRow == IDX_SYSCTL )
    {
        cell.textLabel.text = @"sysctl";
    }
    else if( currentRow == IDX_UIDEVICE )
    {
        cell.textLabel.text = @"UIDevice";
    }
    else if( currentRow == IDX_DEVICESTORAGE )
    {
        cell.textLabel.text = @"Device Storage";
    }
    else if( currentRow == IDX_NSLOCALE )
    {
        cell.textLabel.text = @"NSLocale";
    }
    else if( currentRow == IDX_NSTIMEZONE )
    {
        cell.textLabel.text = @"NSTimeZone";
    }
    else if( currentRow == IDX_PROCESSLIST )
    {
        cell.textLabel.text = @"Process List";
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* viewController = nil;
    
    const int currentRow = indexPath.row;
    
    if( currentRow == IDX_CORETELEPHONY )
    {
        viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                bundle:nil];
        viewController.title = @"CoreTelephony";
        SBTextViewController* textViewController = (SBTextViewController*) viewController;
        textViewController.textToDisplay = [self queryCoreTelephony];
    }
    else if( currentRow == IDX_MACH )
    {
        viewController = [[SBMachViewController alloc] initWithNibName:@"SBMachViewController" bundle:nil];
    }
    else if( currentRow == IDX_SYSCTL )
    {
        viewController = [[SBSysctlViewController alloc] initWithNibName:@"SBSysctlViewController" bundle:nil];
    }
    else if( currentRow == IDX_UIDEVICE )
    {
        viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                bundle:nil];
        viewController.title = @"UIDevice";
        SBTextViewController* textViewController = (SBTextViewController*) viewController;
        textViewController.textToDisplay = [self queryUIDevice];
    }
    else if( currentRow == IDX_DEVICESTORAGE )
    {
        viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                bundle:nil];
        viewController.title = @"Device Storage";
        SBTextViewController* textViewController = (SBTextViewController*) viewController;
        textViewController.textToDisplay = [self queryDeviceStorage];
    }
    else if( currentRow == IDX_NSLOCALE )
    {
        viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                bundle:nil];
        viewController.title = @"NSLocale";
        SBTextViewController* textViewController = (SBTextViewController*) viewController;
        textViewController.textToDisplay = [self queryNSLocale];
    }
    else if( currentRow == IDX_NSTIMEZONE )
    {
        viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                bundle:nil];
        viewController.title = @"NSTimeZone";
        SBTextViewController* textViewController = (SBTextViewController*) viewController;
        textViewController.textToDisplay = [self queryNSTimeZone];
    }
    else if( currentRow == IDX_PROCESSLIST )
    {
        viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                                bundle:nil];
        viewController.title = @"Process List";
        SBTextViewController* textViewController = (SBTextViewController*) viewController;
        textViewController.textToDisplay = [self queryProcessList];
    }
    
    if( viewController )
    {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
