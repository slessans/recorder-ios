//
//  SCLPlaybackViewController.m
//  VoiceRecorder
//
//  Created by Scott Lessans on 4/14/14.
//  Copyright (c) 2014 Scott Lessans. All rights reserved.
//

#import "SCLPlaybackViewController.h"

@interface SCLPlaybackViewController () {
    BOOL _isUserSliding;
}

@property (nonatomic) BOOL speaker;
@property (nonatomic, strong) AVAudioPlayer * player;
@property (nonatomic, strong) NSTimer * updateTimer;

- (void) updateGUI;
- (void) updateAudioGUI;

- (void) timerCallback:(id)sender;
- (void) playPauseAction:(id)sender;

- (void) sliderDidBeginSliding:(id)sender;
- (void) sliderDidEndSliding:(id)sender;

- (void) audioOutputControlValueDidChange:(id)sender;

@end

@implementation SCLPlaybackViewController

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.player pause];
    [self updateGUI];
}

- (void) sliderDidBeginSliding:(id)sender
{
    _isUserSliding = YES;
}

- (void) sliderDidEndSliding:(id)sender
{
    float value = self.timeSlider.value; // percentage of way through song
    self.player.currentTime = (value * self.player.duration);
    _isUserSliding = NO;
}

- (void) audioOutputControlValueDidChange:(id)sender
{
    self.speaker = (self.audioOutputControl.selectedSegmentIndex == 1);
    
    if (self.player) {
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        AVAudioSessionPortOverride override = self.speaker ?
        AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
        [audioSession overrideOutputAudioPort:override error:nil];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.speaker = NO;
    _isUserSliding = NO;
    
    [self.playPauseButton addTarget:self
                             action:@selector(playPauseAction:)
                   forControlEvents:UIControlEventTouchUpInside];
    
    self.timeSlider.minimumValue = 0.0;
    self.timeSlider.maximumValue = 1.0;
    
    [self.audioOutputControl addTarget:self
                                action:@selector(audioOutputControlValueDidChange:)
                      forControlEvents:UIControlEventValueChanged];
    
    [self.timeSlider addTarget:self
                        action:@selector(sliderDidBeginSliding:)
              forControlEvents:UIControlEventTouchDown];
    [self.timeSlider addTarget:self
                        action:@selector(sliderDidEndSliding:)
              forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    
    [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    
    [self updateGUI];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateGUI];
}

- (void) playPauseAction:(id)sender
{
    if (!self.player) {
        return;
    }
    if (self.player.playing) {
        [self.player pause];
    } else {
        [self.player play];
    }
    [self updateGUI];
}

- (void) updateGUI
{
    self.fileNameLabel.text = self.audioFilePath;
    
    if (self.player) {
        self.timeSlider.userInteractionEnabled = YES;
        self.playPauseButton.hidden = NO;
        if (self.player.playing) {
            [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        } else {
            [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
        }
    } else {
        self.timeSlider.userInteractionEnabled = NO;
        self.playPauseButton.hidden = YES;
    }
    
    if (self.speaker) {
        self.audioOutputControl.selectedSegmentIndex = 1;
    } else {
        self.audioOutputControl.selectedSegmentIndex = 0;
    }
    
    [self updateAudioGUI];
}

- (void) updateAudioGUI
{
    self.currentTimeLabel.text = makeTimeString(self.player.currentTime);
    self.totalTimeLabel.text = makeTimeString(self.player.duration);
    
    if (!_isUserSliding) {
        if (self.player.duration > 0) {
            self.timeSlider.value = (self.player.currentTime / self.player.duration);
        } else {
            self.timeSlider.value = 0;
        }
    }
    
    if (self.player && self.player.numberOfChannels > 0) {
        [self.player updateMeters];
        self.peakPowerProgressView.progress = meterValueFromPowerSignal([self.player peakPowerForChannel:0]);
        self.averagePowerProgressView.progress = meterValueFromPowerSignal([self.player averagePowerForChannel:0]);
    } else {
        self.peakPowerProgressView.progress = 0;
        self.averagePowerProgressView.progress = 0;
    }
}

- (void) timerCallback:(id)sender
{
    [self updateAudioGUI];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.player) {
        
        NSURL * url = [NSURL fileURLWithPath:self.audioFilePath];
        NSError * error = nil;
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                             error:&error];
        if (!self.player) {
            NSLog(@"Error creating player object: %@", error);
            NSString * message = [NSString stringWithFormat:
                                  @"Error creating audio player: %@",
                                  [error localizedDescription]];
            [[[UIAlertView alloc] initWithTitle:@"Pooop."
                                        message:message
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        } else {
            
            AVAudioSession * audioSession = [AVAudioSession sharedInstance];
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [audioSession setActive:YES error:nil];
            
            AVAudioSessionPortOverride override = self.speaker ?
                AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
            [audioSession overrideOutputAudioPort:override error:nil];
            
            self.player.delegate = self;
            self.player.meteringEnabled = YES;
            [self.player prepareToPlay];
        }
    }
    
    if (!self.updateTimer) {
        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(timerCallback:)
                                                          userInfo:nil
                                                           repeats:YES];
    }
    
    [self updateGUI];
}

NS_INLINE float meterValueFromPowerSignal(float power)
{
    if (power > 0) {
        power = 0;
    } else if (power < -160) {
        power = -160;
    }
    
    power += 160;
    
    return (power / 160);
}

NS_INLINE NSString * makeTimeString(NSTimeInterval time)
{
    long seconds = (long)floor(time);
    return [NSString stringWithFormat: @"%02ld:%02ld",
            (seconds / 60), (seconds % 60)];
}

@end
