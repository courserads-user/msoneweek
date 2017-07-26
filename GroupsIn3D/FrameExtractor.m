//
//  FrameExtractor.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "FrameExtractor.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

@interface FrameExtractor ()

@property (nonatomic) BOOL permissionGranted;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureDevice *captureDevice;
@property (nonatomic, retain) CIContext *context;
@property (nonatomic, retain) dispatch_queue_t sessionQueue;

@end

@implementation FrameExtractor

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession andCaptureDevice:(AVCaptureDevice *)captureDevice {
    self = [super init];
    if (self) {
        [self setPermissionGranted:NO];
        [self setSessionQueue:dispatch_queue_create("session queue",NULL)];
        [self setCaptureSession:captureSession];
        [self setCaptureDevice:captureDevice];
        [self setContext:[[CIContext alloc] init]];
        
        [self checkPermission];
        [self configureSession];
        [[self captureSession] startRunning];
    }
    return self;
}

-(void)  checkPermission
{
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            [self setPermissionGranted:YES];
            break;
        case AVAuthorizationStatusNotDetermined:
            [self requestPermission];
            break;
        default:
            [self setPermissionGranted:NO];
            break;
    }
}

-(void)requestPermission
{
    dispatch_suspend([self sessionQueue]);
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        [self setPermissionGranted:granted];
        dispatch_resume([self sessionQueue]);
    }];
}

-(void)configureSession
{
    if(_permissionGranted)
    {
        [[self captureSession] setSessionPreset:AVCaptureSessionPresetHigh];
        if([self captureDevice])
        {
            AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self captureDevice] error:nil];
            if(captureDeviceInput)
            {
                AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
                [videoOutput setSampleBufferDelegate:self queue:dispatch_queue_create("sample buffer", NULL)];
                if([[self captureSession] canAddOutput:videoOutput])
                {
                    [[self captureSession] addOutput:videoOutput];
                    AVCaptureConnection *connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
                    if(connection && [connection isVideoOrientationSupported] && [connection isVideoMirroringSupported])
                    {
                        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                        [connection setVideoMirrored:NO];
                    }
                }
            }
        }
    }
}

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    UIImage *returnVal = nil;
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if(imageBuffer)
    {
        CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
        CGImageRef cgImage = [[self context] createCGImage:ciImage fromRect:[ciImage extent]];
        if(cgImage)
        {
            returnVal = [UIImage imageWithCGImage:cgImage];
            CGImageRelease(cgImage);
        }
    }

    return returnVal;
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    UIImage *uiImage = [self imageFromSampleBuffer:sampleBuffer];
    if(uiImage)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] captured:uiImage];
        });
    }
}

@end
