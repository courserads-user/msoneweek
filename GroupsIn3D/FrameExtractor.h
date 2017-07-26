//
//  FrameExtractor.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVCaptureSession;
@class AVCaptureDevice;
@class UIImage;

@protocol FrameExtractorDelegate<NSObject>

-(void)captured:(UIImage *)image;

@end

@interface FrameExtractor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, retain) id<FrameExtractorDelegate> delegate;

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession andCaptureDevice:(AVCaptureDevice *)captureDevice;

@end
