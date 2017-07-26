//
//  VNFaceObservation+Hack.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/25/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <UIKit/UIKit.h>

@interface VNFaceObservation (Hack)

-(CAShapeLayer *)faceShapeLayer:(CGRect)imageRect;
-(CGRect)faceRect:(CGRect)imageRect;

@end
