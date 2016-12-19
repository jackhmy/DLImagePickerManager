//
//  DLImagePickerManager.h
//  Communication
//
//  Created by CIO on 16/12/19.
//  Copyright © 2016年 JL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DLImagePickerManager;

@protocol DLImagePickerManagerDelegate <NSObject>

- (void)imagePickerManager:(DLImagePickerManager *)manager didFinishPickingPhotos:(NSArray<UIImage *> *)photos;

@end

@interface DLImagePickerManager : NSObject


/**
 default 1.
 */
@property (nonatomic, assign) NSUInteger selectedImageMaxCount;

/**
 Init DLImagePickerManager instance.

 @param delegate view controller
 @return instance
 */
- (instancetype)initWithImagePickerManagerWithDelegate:(UIViewController<DLImagePickerManagerDelegate> *)delegate;

- (void)showImagePickerController;
- (void)showImagePreviewControllerWithImageIndex:(NSUInteger)imageIndex;
- (void)showImagePickerControllerWithSelectedAssets:(NSArray *)assets;

@end
