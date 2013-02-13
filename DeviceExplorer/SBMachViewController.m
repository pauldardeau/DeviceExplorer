//
//  SBMachViewController.m
//  DeviceExplorer
//
//  Created by Paul Dardeau on 2/11/13.
//  Copyright (c) 2013 Paul Dardeau. All rights reserved.
//

#import <mach/mach.h>

#import "SBMachViewController.h"
#import "SBTextViewController.h"

@interface SBMachViewController ()

@end

@implementation SBMachViewController

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
    self.title = NSLocalizedString(@"Mach", @"Mach");
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
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    if( indexPath.row == 0 )
    {
        cell.textLabel.text = @"Host Basic Info";
    }
    else if( indexPath.row == 1 )
    {
        cell.textLabel.text = @"Host Cpu Info";
    }
    else if( indexPath.row == 2 )
    {
        cell.textLabel.text = @"Host Load Info";
    }
    else if( indexPath.row == 3 )
    {
        cell.textLabel.text = @"Host VM Info";
    }
    
    return cell;
}

- (NSString*)queryMachHostInfo
{
    host_name_port_t myhost = mach_host_self();
    kern_return_t kr;
    NSMutableString* textToDisplay = [[NSMutableString alloc] init];
    
    // kernel version
    kernel_version_t kversion;
    kr = host_kernel_version(myhost, kversion);
    if( kr == KERN_SUCCESS )
    {
        [textToDisplay appendFormat:@"kernel version: %s\n", kversion];
    }
    
    // page size
    vm_size_t page_size;
    kr = host_page_size(myhost, &page_size);
    if( kr == KERN_SUCCESS )
    {
        [textToDisplay appendFormat:@"page size (bytes): %u\n", page_size];
    }
    
    // host info
    mach_msg_type_number_t count;
    count = HOST_BASIC_INFO_COUNT;
    host_basic_info_data_t hinfo;
    kr = host_info(myhost,
                   HOST_BASIC_INFO,
                   (host_info_t) &hinfo,
                   &count);
    
    if( kr == KERN_SUCCESS )
    {
        char* cpu_type_name = NULL;
        char* cpu_subtype_name = NULL;
        slot_name(hinfo.cpu_type,
                  hinfo.cpu_subtype,
                  &cpu_type_name,
                  &cpu_subtype_name);
        
        if( cpu_type_name != NULL )
        {
            [textToDisplay appendFormat:@"cpu type: %s\n", cpu_type_name];
        }
        
        if( cpu_subtype_name != NULL )
        {
            [textToDisplay appendFormat:@"cpu subtype: %s\n", cpu_subtype_name];
        }
        
        [textToDisplay appendFormat:@"max_cpus: %d\n", hinfo.max_cpus];
        [textToDisplay appendFormat:@"avail_cpus: %d\n", hinfo.avail_cpus];
        [textToDisplay appendFormat:@"physical_cpu: %d\n", hinfo.physical_cpu];
        [textToDisplay appendFormat:@"physical_cpu_max: %d\n", hinfo.physical_cpu_max];
        [textToDisplay appendFormat:@"logical_cpu: %d\n", hinfo.logical_cpu];
        [textToDisplay appendFormat:@"logical_cpu_max: %d\n", hinfo.logical_cpu_max];
        [textToDisplay appendFormat:@"memory_size: %u MB\n", (hinfo.memory_size >> 20)];
        [textToDisplay appendFormat:@"max_mem: %llu MB\n", (hinfo.max_mem >> 20)];
    }

    return textToDisplay;
}

- (NSString*)queryMachLoadInfo
{
    host_name_port_t myhost = mach_host_self();
    kern_return_t kr;
    mach_msg_type_number_t count;
    NSMutableString* textToDisplay = [[NSMutableString alloc] init];
    
    // host load info
    count = HOST_LOAD_INFO_COUNT;
    host_load_info_data_t load_info;
    kr = host_statistics(myhost,
                         HOST_LOAD_INFO,
                         (host_info_t) &load_info,
                         &count);
    
    if( kr == KERN_SUCCESS )
    {
        [textToDisplay appendString:@"time period (sec): 5, 30, 60\n"];
        [textToDisplay appendFormat:@"load average: %u, %u, %u\n",
            load_info.avenrun[0],
            load_info.avenrun[1],
            load_info.avenrun[2]];
        [textToDisplay appendFormat:@"Mach factor: %u, %u, %u\n",
            load_info.mach_factor[0],
            load_info.mach_factor[1],
            load_info.mach_factor[2]];
    }
    
    return textToDisplay;
}

- (NSString*)queryMachCpuInfo
{
    host_name_port_t myhost = mach_host_self();
    kern_return_t kr;
    mach_msg_type_number_t count;
    NSMutableString* textToDisplay = [[NSMutableString alloc] init];

    // cpu load statistics
    count = HOST_CPU_LOAD_INFO_COUNT;
    host_cpu_load_info_data_t cpu_load_info;
    kr = host_statistics(myhost,
                         HOST_CPU_LOAD_INFO,
                         (host_info_t) &cpu_load_info,
                         &count);
    
    if( kr == KERN_SUCCESS )
    {
        [textToDisplay appendFormat:@"user state ticks = %u\n",
            cpu_load_info.cpu_ticks[CPU_STATE_USER]];
        [textToDisplay appendFormat:@"system state ticks = %u\n",
            cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM]];
        [textToDisplay appendFormat:@"nice state ticks = %u\n",
            cpu_load_info.cpu_ticks[CPU_STATE_NICE]];
        [textToDisplay appendFormat:@"idle state ticks = %u\n",
            cpu_load_info.cpu_ticks[CPU_STATE_IDLE]];
    }

    return textToDisplay;
}

- (NSString*)queryMachVmInfo
{
    host_name_port_t myhost = mach_host_self();
    kern_return_t kr;
    mach_msg_type_number_t count;
    NSMutableString* textToDisplay = [[NSMutableString alloc] init];

    // virtual memory statistics
    count = HOST_VM_INFO_COUNT;
    vm_statistics_data_t vm_stat;
    kr = host_statistics(myhost,
                         HOST_VM_INFO,
                         (host_info_t) &vm_stat,
                         &count);
    
    if( kr == KERN_SUCCESS )
    {
        vm_size_t pagesize = 0;
        
        host_page_size(myhost, &pagesize);

        if( pagesize > 0 )
        {
            natural_t memBytesUsed = (vm_stat.active_count +
                                      vm_stat.inactive_count +
                                      vm_stat.wire_count) * pagesize;
            natural_t memBytesFree = vm_stat.free_count * pagesize;
            natural_t memBytesTotal = memBytesUsed + memBytesFree;
            [textToDisplay appendFormat:@"bytes used = %u\n", memBytesUsed];
            [textToDisplay appendFormat:@"bytes free = %u\n", memBytesFree];
            [textToDisplay appendFormat:@"bytes total = %u\n", memBytesTotal];
        }

        [textToDisplay appendFormat:@"pages free = %u\n", vm_stat.free_count];
        [textToDisplay appendFormat:@"pages active = %u\n", vm_stat.active_count];
        [textToDisplay appendFormat:@"pages inactive = %u\n", vm_stat.inactive_count];
        [textToDisplay appendFormat:@"pages wired = %u\n", vm_stat.wire_count];
        [textToDisplay appendFormat:@"pages zero filled = %u\n", vm_stat.zero_fill_count];
        [textToDisplay appendFormat:@"pages reactivated = %u\n", vm_stat.reactivations];
        [textToDisplay appendFormat:@"pageins = %u\n", vm_stat.pageins];
        [textToDisplay appendFormat:@"pageouts = %u\n", vm_stat.pageouts];
        [textToDisplay appendFormat:@"faults = %u\n", vm_stat.faults];
        [textToDisplay appendFormat:@"copy-on-write faults = %u\n", vm_stat.cow_faults];
        [textToDisplay appendFormat:@"cache lookups = %u\n", vm_stat.lookups];
        [textToDisplay appendFormat:@"cache hits = %u\n", vm_stat.hits];
    }
    
    return textToDisplay;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* viewController = nil;
    viewController = [[SBTextViewController alloc] initWithNibName:@"SBTextViewController"
                                                            bundle:nil];
    NSString* textToDisplay = nil;
    
    if( indexPath.row == 0 )
    {
        viewController.title = @"Host Basic Info";
        textToDisplay = [self queryMachHostInfo];
    }
    else if( indexPath.row == 1 )
    {
        viewController.title = @"Host CPU Info";
        textToDisplay = [self queryMachCpuInfo];
    }
    else if( indexPath.row == 2 )
    {
        viewController.title = @"Host Load Info";
        textToDisplay = [self queryMachLoadInfo];
    }
    else if( indexPath.row == 3 )
    {
        viewController.title = @"Host VM Info";
        textToDisplay = [self queryMachVmInfo];
    }
         
    if( viewController )
    {
        if( textToDisplay )
        {
            SBTextViewController* textViewController = (SBTextViewController*) viewController;
            textViewController.textToDisplay = textToDisplay;
        }

        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
