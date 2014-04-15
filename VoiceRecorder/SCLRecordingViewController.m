//
//  SCLViewController.m
//  VoiceRecorder
//
//  Created by Scott Lessans on 4/12/14.
//  Copyright (c) 2014 Scott Lessans. All rights reserved.
//

#import "SCLRecordingViewController.h"

static NSString * const FileExt = @"aif";

@interface SCLRecordingViewController ()

@property (nonatomic, strong) AVAudioRecorder * recorder;
@property (nonatomic, strong) NSTimer * updateTimer;

- (void) recordingControlButtonAction:(id)sender;
- (void) timerCallback:(NSTimer *)timer;
- (void) updateAudioGUI;
- (void) updateGUI;
- (void) saveRecordingButtonAction:(id)sender;

- (void) allRecordingsAction:(id)sender;
- (void) cancelRecordingAction:(id)sender;

- (void) beginRecording;
- (void) pauseRecording;

@end

@implementation SCLRecordingViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self pauseRecording];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.recorder = nil;
    
    [self.recordingControlButton addTarget:self
                                    action:@selector(recordingControlButtonAction:)
                          forControlEvents:UIControlEventTouchUpInside];
    [self.saveRecordingButton addTarget:self
                                 action:@selector(saveRecordingButtonAction:)
                       forControlEvents:UIControlEventTouchUpInside];
    
    [self.allRecordingsButton addTarget:self
                                 action:@selector(allRecordingsAction:)
                       forControlEvents:UIControlEventTouchUpInside];
    
    [self.cancelRecordingButton addTarget:self
                                   action:@selector(cancelRecordingAction:)
                         forControlEvents:UIControlEventTouchUpInside];
    
    [self updateGUI];
}

- (void) allRecordingsAction:(id)sender
{
    [self pauseRecording];
    [self performSegueWithIdentifier:@"RecordingsSegue"
                              sender:self];
}

- (void) dealloc
{
    if (self.recorder) {
        [self.recorder stop];
    }
}

- (void) saveRecordingButtonAction:(id)sender
{
    if (!self.recorder) {
        return;
    }
    if (self.recorder.isRecording) {
        [self.recorder pause];
    }
    NSURL * tmpFileURL = self.recorder.url;
    [self.recorder stop];
    self.recorder = nil;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSError * error = nil;
    if (![fileManager moveItemAtURL:tmpFileURL
                              toURL:generateFinishedFileURL()
                              error:&error])
    {
        NSLog(@"Error saving file: %@", error);
        
        // this wouldn't be suitable for a production app, but I want to know if this happens.
        NSString * message = [NSString stringWithFormat:
                              @"An error occurred while saving your file: %@",
                              [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"Weird."
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
    [self updateGUI];
}

- (void) cancelRecordingAction:(id)sender
{
    if (!self.recorder) {
        return;
    }
    [self pauseRecording];
    
    NSString * message = @"Are you sure you want to cancel this recording? All audio will be lost.";
    [[[UIAlertView alloc] initWithTitle:@"Are you sure?"
                               message:message
                              delegate:self
                     cancelButtonTitle:@"Nevermind"
                      otherButtonTitles:@"Cancel!", nil] show];    
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    // for now, this could only be triggered by cancel alert. if it wasn't
    // the cancel button, then it must be the Cancel! button (hehe)
    NSURL * tmpFileUrl = self.recorder.url;
    [self.recorder stop];
    self.recorder = nil;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSError * error = nil;
    if (![fileManager removeItemAtURL:tmpFileUrl error:&error]) {
        // this wouldn't be suitable for a production app, but I want to know if this happens.
        NSString * message = [NSString stringWithFormat:
                              @"An error occurred while deleting your file: %@",
                              [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"Weird."
                                   message:message
                                  delegate:nil
                         cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        NSLog(@"Error deleting file: %@", error);
    }
    
    [self updateGUI];
}

- (void) recordingControlButtonAction:(id)sender
{
    if (self.recorder && self.recorder.isRecording) {
        [self pauseRecording];
    } else {
        [self beginRecording];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                        target:self
                                                      selector:@selector(timerCallback:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void) timerCallback:(NSTimer *)timer
{
    [self updateAudioGUI];
}

- (void) updateAudioGUI
{
    if (self.recorder) {
        NSTimeInterval t = self.recorder.currentTime;
        
        long minutes = (long)floor(t) / 60;
        long seconds = (long)floor(t) % 60;
        
        self.timeLabel.text = [NSString stringWithFormat:
                               @"%02ld:%02ld", minutes, seconds];
        
    } else {
        self.timeLabel.text = @"";
    }
}

- (void) updateGUI
{
    if (self.recorder) {
        if (self.recorder.isRecording) {
            [self.recordingControlButton setTitle:@"Pause Recording"
                                         forState:UIControlStateNormal];
            self.statusLabel.text = @"Recording";
            self.saveRecordingButton.hidden = YES;
            self.cancelRecordingButton.hidden = YES;
        } else {
            self.statusLabel.text = @"Recording Paused";
            [self.recordingControlButton setTitle:@"Resume Recording"
                                         forState:UIControlStateNormal];
            self.saveRecordingButton.hidden = NO;
            self.cancelRecordingButton.hidden = NO;
        }
        self.fileNameLabel.text = self.recorder.url.path;
        self.allRecordingsButton.hidden = YES;
    } else {
        self.statusLabel.text = @"";
        [self.recordingControlButton setTitle:@"Begin Recording"
                                     forState:UIControlStateNormal];
        self.fileNameLabel.text = nil;
        self.saveRecordingButton.hidden = YES;
        self.cancelRecordingButton.hidden = YES;
        self.allRecordingsButton.hidden = NO;
    }
    
    [self updateAudioGUI];
}

- (void) pauseRecording
{
    if (self.recorder && self.recorder.isRecording) {
        [self.recorder pause];
    }
    [self updateGUI];
}

- (void) beginRecording
{
    
    if (self.recorder && self.recorder.isRecording) {
        return;
    }
    
    if (!self.recorder) {
        
        NSDictionary * settings =
        @{AVFormatIDKey             : intKey(kAudioFormatLinearPCM),
          AVSampleRateKey           : floatKey(44100.0),
          AVNumberOfChannelsKey     : intKey(1),
          AVLinearPCMBitDepthKey    : intKey(24),
          AVLinearPCMIsBigEndianKey : boolKey(NO),
          AVLinearPCMIsFloatKey     : boolKey(NO),
          AVEncoderAudioQualityKey  : intKey(AVAudioQualityMax)
          };
        
        NSError * error = nil;
        self.recorder = [[AVAudioRecorder alloc] initWithURL:generateTemporaryFileURL()
                                                    settings:settings
                                                       error:&error];
        
        if (error) {
            self.recorder = nil;
            NSLog(@"Could not create recorder: %@", error);
            [[[UIAlertView alloc] initWithTitle:@"Could Not Create Recorder"
                                        message:[error localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
            [self updateGUI];
            return;
        }
        
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
        
        [self.recorder prepareToRecord];
    }
    [self.recorder record];
    [self updateGUI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

NS_INLINE NSURL * generateTemporaryFileURL()
{
    NSString * fileName = [NSString stringWithFormat:@"recording.%@",
                           FileExt];
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
}

NS_INLINE NSURL * generateFinishedFileURL()
{
    NSString * documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMM-dd-YYYY_hhmmssa";
    
    NSString * fileName = [NSString stringWithFormat:@"recording-%@.%@",
                           [formatter stringFromDate:[NSDate date]],
                           FileExt];
    
    return [NSURL fileURLWithPath:[documentsDir stringByAppendingPathComponent:fileName]];
}

NS_INLINE NSNumber* intKey(int i)
{
    return [NSNumber numberWithInt:i];
}

NS_INLINE NSNumber* floatKey(float i)
{
    return [NSNumber numberWithFloat:i];
}

NS_INLINE NSNumber* boolKey(BOOL i)
{
    return [NSNumber numberWithBool:i];
}

@end
