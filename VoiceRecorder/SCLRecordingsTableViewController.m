//
//  SCLRecordingsTableViewController.m
//  VoiceRecorder
//
//  Created by Scott Lessans on 4/12/14.
//  Copyright (c) 2014 Scott Lessans. All rights reserved.
//

#import "SCLRecordingsTableViewController.h"

@interface SCLRecordingsTableViewController ()

@property (nonatomic, strong) NSArray * recordings;
@property (nonatomic, strong) NSIndexPath * indexPathOfDeleteCell;

- (void) refreshAction:(id)sender;

@end

@implementation SCLRecordingsTableViewController

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
    
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelection = NO;
    
    self.refreshButtonItem.target = self;
    self.refreshButtonItem.action = @selector(refreshAction:);    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshAction:self];
}

- (void) refreshAction:(id)sender
{
    NSString * documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                               objectAtIndex:0];
    
    NSError * error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDir error:&error];
    if (files == nil) {
        NSLog(@"Error refreshing %@", error);
        return;
    }
    
    NSMutableArray * recs = [[NSMutableArray alloc] init];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMM-dd-YYYY_hhmmssa";
    
    for (NSString * file in files) {
        if ([file hasPrefix:@"recording-"] && [file hasSuffix:@".aif"]) {
            
            NSString * dateStr = [[file stringByReplacingOccurrencesOfString:@"recording-" withString:@""]
                                  stringByReplacingOccurrencesOfString:@".aif" withString:@""];
            
            NSString * filePath = [documentsDir stringByAppendingPathComponent:file];
            
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                                            error:nil];
            double fileSize = [[fileAttributes objectForKey:NSFileSize] doubleValue] / (1024 * 1024);
            
            NSDictionary * info =
            @{@"filePath" : filePath,
              @"displayName" : dateStr,
              @"size"       : [NSString stringWithFormat:@"%.2f MB", fileSize]
              };
            [recs addObject:info];
        }
    }

    self.recordings = recs;
    [self.tableView reloadData];    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSIndexPath * toDelete = self.indexPathOfDeleteCell;
    self.indexPathOfDeleteCell = nil;
    
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    NSString * filePath = self.recordings[toDelete.row][@"filePath"];
    NSFileManager * mgr = [NSFileManager defaultManager];
    
    NSError * error = nil;
    if (![mgr removeItemAtPath:filePath error:&error]) {
        NSString * msg = [NSString stringWithFormat:@"Couldn't delete file: %@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"Uh, Oh"
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
    [self refreshAction:self];
}

#pragma mark - Table view data source
- (UITableViewCellEditingStyle) tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        self.indexPathOfDeleteCell = indexPath;
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                         message:@"Are you sure you want to delete this file?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Delete", nil];
        [alert show];
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    UILabel * nameLabel = (UILabel *)[cell viewWithTag:1];
    UILabel * sizeLabel = (UILabel *)[cell viewWithTag:2];
    
    NSDictionary * info = self.recordings[indexPath.row];
    
    nameLabel.text = [NSString stringWithFormat:@"%@", info[@"displayName"]];
    sizeLabel.text = [NSString stringWithFormat:@"Size: %@", info[@"size"]];
    
    return cell;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recordings count];
}


@end
