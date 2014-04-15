//
//  SCLViewController.h
//  VoiceRecorder
//
//  Created by Scott Lessans on 4/12/14.
//  Copyright (c) 2014 Scott Lessans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SCLRecordingViewController : UIViewController <AVAudioRecorderDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton * recordingControlButton;
@property (nonatomic, weak) IBOutlet UIButton * allRecordingsButton;
@property (nonatomic, weak) IBOutlet UIButton * saveRecordingButton;
@property (nonatomic, weak) IBOutlet UIButton * cancelRecordingButton;

@property (nonatomic, weak) IBOutlet UILabel * statusLabel; // recording or not recording
@property (nonatomic, weak) IBOutlet UILabel * timeLabel;
@property (nonatomic, weak) IBOutlet UILabel * fileNameLabel;

@end
