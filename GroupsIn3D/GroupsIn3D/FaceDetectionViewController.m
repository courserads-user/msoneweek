//
//  FaceDetectionViewController.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "FaceDetectionViewController.h"
#import "FrameExtractor.h"
#import "VNFaceObservation+Hack.h"
#import <Vision/Vision.h>

@interface FaceDetectionViewController () <FrameExtractorDelegate>

@property (retain, nonatomic) FrameExtractor *frameExtractor;
@property (retain, nonatomic) UIView *highlightView;

@end

@implementation FaceDetectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    AVCaptureDevice *videoDevice = [[[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera]
                                                                                            mediaType:AVMediaTypeVideo
                                                                                             position:AVCaptureDevicePositionFront] devices] objectAtIndex:0];
    if (videoDevice)
    {
        NSError *error;
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (!error)
        {
            if ([session canAddInput:videoInput])
            {
                [session addInput:videoInput];
                AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
                previewLayer.frame = self.view.bounds;
                [self.view.layer addSublayer:previewLayer];
            }
        }
    }
    
    [self setFrameExtractor:[[FrameExtractor alloc] initWithCaptureSession:session andCaptureDevice:videoDevice]];
    [[self frameExtractor] setDelegate:self];
    [self setHighlightView:[UIView new]];
    [[self highlightView] setFrame:self.view.bounds];
    [[self highlightView] setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.0]];
    [[self highlightView] setOpaque:NO];
    [self.view addSubview:[self highlightView]];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)captured:(UIImage *)image
{
    VNDetectFaceRectanglesRequest *faceRequest = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        NSArray *results = [request results];
        [self.highlightView.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        for(VNFaceObservation *faceObservation in results)
        {
            CGRect imageRect = AVMakeRectWithAspectRatioInsideRect(self.highlightView.frame.size, self.highlightView.bounds);
            CAShapeLayer *layer = [faceObservation faceShapeLayer:imageRect];
            [[[self highlightView] layer] addSublayer:layer];
        }
    }];
    
    NSDictionary<VNImageOption, id> *options = @{};
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:options];
    NSError *error;
    [requestHandler performRequests:@[faceRequest] error:&error];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
