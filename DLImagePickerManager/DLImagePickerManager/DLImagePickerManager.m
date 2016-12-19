//
//  DLImagePickerManager.m
//  Communication
//
//  Created by CIO on 16/12/19.
//  Copyright © 2016年 JL. All rights reserved.
//

#import "DLImagePickerManager.h"
#import "TZImageManager.h"
#import "TZImagePickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

@interface DLImagePickerManager () <
UINavigationControllerDelegate,
UIActionSheetDelegate,
UIImagePickerControllerDelegate>

@property (nonatomic, weak) UIViewController<DLImagePickerManagerDelegate> *delegate;

@property (nonatomic, strong) UIImagePickerController* imagePickerVc;
@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, assign) BOOL selectedOriginPhoto;

@end

@implementation DLImagePickerManager

#pragma mark - life cycle
- (instancetype)init {
    return nil;
}

- (instancetype)initWithImagePickerManagerWithDelegate:(UIViewController<DLImagePickerManagerDelegate> *)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.selectedImageMaxCount = 1;
    }
    return self;
}

#pragma mark - public methods
- (void)showImagePickerController {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"去相册选择", nil];
    [sheet showInView:self.delegate.view];
}

- (void)showImagePickerControllerWithSelectedAssets:(NSArray *)assets {

    self.selectedAssets = [assets mutableCopy];
    [self showImagePickerController];
}

- (void)showImagePreviewControllerWithImageIndex:(NSUInteger)imageIndex {
    
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithSelectedAssets:self.selectedAssets selectedPhotos:self.selectedPhotos index:imageIndex];
    imagePickerVc.allowPickingOriginalPhoto = NO;
    imagePickerVc.isSelectOriginalPhoto = self.selectedOriginPhoto;
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {

        self.selectedOriginPhoto = isSelectOriginalPhoto;
        self.selectedPhotos = [NSMutableArray arrayWithArray:photos];
        self.selectedAssets = [NSMutableArray arrayWithArray:assets];

        !self.delegate ?: [self.delegate imagePickerManager:self didFinishPickingPhotos:self.selectedPhotos];

        if (isSelectOriginalPhoto && assets.count > 0) {
            [self getOriginalPhotoWithAssets:assets];
        }
    }];
    [self.delegate presentViewController:imagePickerVc animated:YES completion:nil];

}

#pragma mark - actions
- (void)takePhoto {
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerVc.sourceType = sourceType;
        if(iOS8Later) {
            _imagePickerVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        [self.delegate presentViewController:_imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}
- (void)pushImagePickerController {

    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:self.selectedImageMaxCount delegate:nil];

    imagePickerVc.selectedAssets = self.selectedImageMaxCount == 1 ? nil : self.selectedAssets; // optional, 可选的
    imagePickerVc.isSelectOriginalPhoto = NO;
    // 1.如果你需要将拍照按钮放在外面，不要传这个参数
    imagePickerVc.allowTakePicture = NO; // 在内部显示拍照按钮
    // 2. 在这里设置imagePickerVc的外观
    imagePickerVc.navigationBar.barTintColor = self.delegate.navigationController.navigationBar.barTintColor;
    //    imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    //    imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    // 3. 设置是否可以选择视频/图片/原图
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = YES;
    // 4. 照片排列按修改时间升序
    //    imagePickerVc.sortAscendingByModificationDate = YES;
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {

        self.selectedOriginPhoto = isSelectOriginalPhoto;
        self.selectedPhotos = [NSMutableArray arrayWithArray:photos];
        self.selectedAssets = [NSMutableArray arrayWithArray:assets];

        !self.delegate ?: [self.delegate imagePickerManager:self didFinishPickingPhotos:self.selectedPhotos];

        if (isSelectOriginalPhoto && assets.count > 0) {
            [self getOriginalPhotoWithAssets:assets];
        }
    }];

    [self.delegate presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - private methods
- (void)getOriginalPhotoWithAssets:(NSArray *)assets {

    [self.selectedPhotos removeAllObjects];
    TZImageManager *imageManager = [TZImageManager manager];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < assets.count; i++) {
            [imageManager getOriginalPhotoWithAsset:assets[i] completion:^(UIImage *photo, NSDictionary *info) {
                NSString *fileUrlKey = info[@"PHImageFileURLKey"];
                if (fileUrlKey) {
                    [self.selectedPhotos addObject:photo];
                }
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !self.delegate ?: [self.delegate imagePickerManager:self didFinishPickingPhotos:self.selectedPhotos];
        });
    });
}

#pragma mark - delegate

#pragma mark action sheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied || author == kCLAuthorizationStatusRestricted || author ==kCLAuthorizationStatusDenied)) {
        // 无权限 做一个友好的提示
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机(相册)" message:@"请在iPhone的""设置-隐私-相机(相册)""中允许访问相机(相册)" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
        return;
    }

    if (buttonIndex == 0) { // take photo / 去拍照
        [self takePhoto];
    } else if (buttonIndex == 1) {
        [self pushImagePickerController];
    }
}

#pragma mark image picker delegate
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        TZImagePickerController *tzImagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:self.selectedImageMaxCount delegate:nil];
        tzImagePickerVc.sortAscendingByModificationDate = YES;
        [tzImagePickerVc showProgressHUD];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        // save photo and get asset / 保存图片，获取到asset
        [[TZImageManager manager] savePhotoWithImage:image completion:^(NSError *error) {
            [[TZImageManager manager] getCameraRollAlbum:NO allowPickingImage:YES completion:^(TZAlbumModel *model) {
                [[TZImageManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:NO allowPickingImage:YES completion:^(NSArray<TZAssetModel *> *models) {
                    [tzImagePickerVc hideProgressHUD];
                    TZAssetModel *assetModel = [models firstObject];
                    if (tzImagePickerVc.sortAscendingByModificationDate) {
                        assetModel = [models lastObject];
                    }
                    [self.selectedAssets addObject:assetModel.asset];
                    [self.selectedPhotos addObject:image];
                    !self.delegate ?: [self.delegate imagePickerManager:self didFinishPickingPhotos:self.selectedPhotos];
                }];
            }];
        }];
    }
}

#pragma mark - getter
- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.delegate.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.delegate.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        if (iOS9Later) {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

- (NSMutableArray *)selectedPhotos {
    if (!_selectedPhotos) {
        _selectedPhotos = [NSMutableArray new];
    }
    return _selectedPhotos;
}

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray new];
    }
    return _selectedAssets;
}

@end
