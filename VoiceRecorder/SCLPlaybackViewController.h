//
//  SCLPlaybackViewController.h
//  VoiceRecorder
//
//  Created by Scott Lessans on 4/14/14.
//  Copyright (c) 2014 Scott Lessans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SCLPlaybackViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic, strong) NSString * audioFilePath;

@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UIProgressView *peakPowerProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *averagePowerProgressView;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@property (weak, nonatomic) IBOutlet UISegmentedControl * audioOutputControl;

@end
