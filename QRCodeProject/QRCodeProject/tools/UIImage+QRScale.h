//
//  UIImage+QRScale.h
//  Pods
//
//  Created by xulihua on 15/12/9.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (QRScale)

//缩放图片
-(UIImage *)TransformtoSize:(CGSize)Newsize;

//识别图片的二维码
- (NSString *)decodeQRImageWith:(UIImage*)aImage;

@end
