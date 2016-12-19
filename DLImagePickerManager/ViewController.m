//
//  ViewController.m
//  DLImagePickerManager
//
//  Created by CIO on 16/12/19.
//  Copyright © 2016年 JL. All rights reserved.
//

#import "ViewController.h"
#import "DLImagePickerManager.h"

@interface ViewController () <DLImagePickerManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *button;

@property (nonatomic, strong) DLImagePickerManager *imagePickerManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectePhoto:(id)sender {
    [self.imagePickerManager showImagePickerController];
}

- (void)imagePickerManager:(DLImagePickerManager *)manager didFinishPickingPhotos:(NSArray<UIImage *> *)photos {
    NSLog(@"photo:%@", photos);
    [self.button setBackgroundImage:photos.firstObject forState:UIControlStateNormal];
}

- (DLImagePickerManager *)imagePickerManager {
    if (!_imagePickerManager) {
        _imagePickerManager = [[DLImagePickerManager alloc] initWithImagePickerManagerWithDelegate:self];
    }
    return _imagePickerManager;
}

@end
