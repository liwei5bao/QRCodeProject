//
//  UIImage+QRScale.m
//  Pods
//
//  Created by xulihua on 15/12/9.
//
//

#import "UIImage+QRScale.h"
#import "ZBarReaderController.h"

@implementation UIImage (QRScale)


-(UIImage *)TransformtoSize:(CGSize)Newsize
{
    // 创建一个bitmap的context
    UIGraphicsBeginImageContext(Newsize);
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(0, 0, Newsize.width, Newsize.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage *TransformedImg=UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return TransformedImg;
}

//识别图片的二维码
- (NSString *)decodeQRImageWith:(UIImage*)aImage {
    NSString *qrResult = nil;
    if (aImage.size.width < 641) {
        aImage = [aImage TransformtoSize:CGSizeMake(640, 640)];
    }
    //iOS8及以上可以使用系统自带的识别二维码图片接口，但此api有问题，在一些机型上detector为nil。
    
    //    if (iOS8_OR_LATER) {
    //        CIContext *context = [CIContext contextWithOptions:nil];
    //        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    //        CIImage *image = [CIImage imageWithCGImage:aImage.CGImage];
    //        NSArray *features = [detector featuresInImage:image];
    //        CIQRCodeFeature *feature = [features firstObject];
    //
    //        qrResult = feature.messageString;
    //    } else {
    ZBarReaderController* read = [ZBarReaderController new];
    CGImageRef cgImageRef = aImage.CGImage;
    ZBarSymbol* symbol = nil;
    for(symbol in [read scanImage:cgImageRef]) break;
    qrResult = symbol.data;
    return qrResult;
}


@end
