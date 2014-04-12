//
//  SCLViewController.m
//  VoiceRecorder
//
//  Created by Scott Lessans on 4/12/14.
//  Copyright (c) 2014 Scott Lessans. All rights reserved.
//

#import "SCLViewController.h"

static NSString * const FileExt = @"aif";

@interface SCLViewController ()

@property (nonatomic, strong) AVAudioRecorder * recorder;
@property (nonatomic, strong) NSTimer * updateTimer;

- (void) recordingControlButtonAction:(id)sender;
- (void) timerCallback:(NSTimer *)timer;
- (void) updateAudioGUI;
- (void) updateGUI;
- (void) saveRecordingButtonAction:(id)sender;

- (void) allRecordingsAction:(id)sender;

- (void) beginRecording;
- (void) pauseRecording;

@end

@implementation SCLViewController

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
    [self.recorder stop];
    self.recorder = nil;
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
        } else {
            self.statusLabel.text = @"Recording Paused";
            [self.recordingControlButton setTitle:@"Resume Recording"
                                         forState:UIControlStateNormal];
        }
        self.fileNameLabel.text = self.recorder.url.path;
        self.saveRecordingButton.hidden = NO;
    } else {
        self.statusLabel.text = @"";
        [self.recordingControlButton setTitle:@"Begin Recording"
                                     forState:UIControlStateNormal];
        self.fileNameLabel.text = nil;
        self.saveRecordingButton.hidden = YES;
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
        self.recorder = [[AVAudioRecorder alloc] initWithURL:generateFileURL()
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

NS_INLINE NSURL * generateFileURL()
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
