//
//  VNFaceObservation+Hack.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/25/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "VNFaceObservation+Hack.h"

@implementation VNFaceObservation (Hack)

-(CAShapeLayer *)faceShapeLayer:(CGRect)imageRect
{
    CAShapeLayer *layer = [CAShapeLayer new];
    [layer setFrame:[self faceRect:imageRect]];
    [layer setBorderColor:[UIColor blueColor].CGColor];
    [layer setBorderWidth:2];
    [layer setCornerRadius:3];
    return layer;
}

-(CGRect)faceRect:(CGRect)imageRect
{
    CGFloat w = self.boundingBox.size.width * imageRect.size.width;
    CGFloat h = self.boundingBox.size.height * imageRect.size.height;
    CGFloat x = self.boundingBox.origin.x * imageRect.size.width;
    CGFloat y = CGRectGetMaxY(imageRect) - (self.boundingBox.origin.y * imageRect.size.height) - h;
    return CGRectMake(x, y, w, h);
}

@end
