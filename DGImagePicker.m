//
//  MNImagePicker.m
//  minube
//
//  Created by Daniel García on 20/3/12.
//  Copyright (c) 2012 minube.com. All rights reserved.
//

#import "DGImagePicker.h"
#import "CustomImagePickerController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ImagePreviewViewController.h"

@interface DGImagePicker(){
}
@property (assign,nonatomic) id presentedPicker;
@property (nonatomic) BOOL showPreview;
@property (retain,nonatomic) ALAssetsLibrary * library;
@property (nonatomic)        NSInteger maxSelectableItems;
@property (retain,nonatomic) UIViewController *imagePickerVC;
@property (assign,nonatomic) UIView* frontView;
@property (assign,nonatomic) UIView* backView;
@property (retain,nonatomic) CameraOverlayView *cameraOverlay;
@property (retain,nonatomic) UIImagePickerController *cameraPicker;
@property (retain,nonatomic) AGImagePickerController *galleryPicker;
@property (copy,nonatomic) DGIPDidSuccess successBlock;
@property (copy,nonatomic) DGIPDidFail failureBlock;

- (void)cameraOverlayViewGalleryButtonPressed:(CameraOverlayView *)cameraOverlayView;
- (void)cameraOverlayView:(CameraOverlayView *)cameraOverlayView lastPictureFromGalleryLoaded:(UIImage *)lastPictureFromGallery;
- (void)cameraOverlayViewDidDisappearFromScreen:(CameraOverlayView *)cameraOverlayView;
- (void)cameraOverlayViewGalleryButtonPressed:(CameraOverlayView *)cameraOverlayView AnimationDuration:(CGFloat)duration;
- (void)galleryCameraButtonPressedWithAnimationDuration:(CGFloat)duration;
@end
@implementation DGImagePicker
@synthesize progressHud=_progressHud;
@synthesize showPreview=_showPreview;
@synthesize library=_library;
@synthesize selectedAssetsURLS=_selectedAssetsURLS;
@synthesize maxSelectableItems;
@synthesize imagePickerVC;
@synthesize successBlock,failureBlock;
@synthesize cameraPicker,cameraOverlay,galleryPicker;
@synthesize frontView,backView;
@synthesize presentedPicker;
- (DGImagePicker *)initWithDelegate:(id)delegate successBlock:(DGIPDidSuccess)_successBlock failureBlock:(DGIPDidFail)_failureBlock
{
    return [self initWithDelegate:delegate assetsType:DGAssetsTypeAll successBlock:_successBlock failureBlock:_failureBlock];
}
- (DGImagePicker *)initWithDelegate:(id)delegate assetsType:(DGAssetsType)assetsType successBlock:(DGIPDidSuccess)_successBlock failureBlock:(DGIPDidFail)_failureBlock
{
    return [self initWithDelegate:delegate maxItems:[NSNumber numberWithInt:0] assetsType:assetsType successBlock:_successBlock failureBlock:_failureBlock];
}
- (DGImagePicker *)initWithDelegate:(id)delegate maxItems:(NSNumber *)maxItems successBlock:(DGIPDidSuccess)_successBlock failureBlock:(DGIPDidFail)_failureBlock
{
    return [self initWithDelegate:delegate maxItems:maxItems assetsType:DGAssetsTypeAll successBlock:_successBlock failureBlock:_failureBlock];
}
- (DGImagePicker *)initWithDelegate:(id)delegate maxItems:(NSNumber *)maxItems assetsType:(DGAssetsType)assetsType successBlock:(DGIPDidSuccess)_successBlock failureBlock:(DGIPDidFail)_failureBlock 
{
    return [self initWithDelegate:delegate maxItems:maxItems assetsType:assetsType showPreview:NO successBlock:_successBlock failureBlock:_failureBlock];
}
- (DGImagePicker *)initWithDelegate:(id)delegate maxItems:(NSNumber *)maxItems assetsType:(DGAssetsType)assetsType showPreview:(BOOL)showPreview successBlock:(DGIPDidSuccess)_successBlock failureBlock:(DGIPDidFail)_failureBlock
{    
    self=[super initWithNibName:nil bundle:nil];
    self.imagePickerVC=[[[UIViewController alloc]init]autorelease];
    if(self){
        self.selectedAssetsURLS = [NSMutableArray array];
        self.failureBlock=_failureBlock;
        self.successBlock=_successBlock;
        self.maxSelectableItems=[maxItems intValue];
        self.showPreview=showPreview;
        BOOL photoAndVideoCamera=NO;
        
        self.galleryPicker= [[[AGImagePickerController alloc]initWithDelegate:self selectedAssetsURLS:self.selectedAssetsURLS failureBlock:nil successBlock:nil maximumNumberOfPhotos:[maxItems intValue] shouldChangeStatusBarStyle:NO toolbarItemsForSelection:nil andShouldDisplaySelectionInformation:NO]autorelease];             
        self.library = [AGImagePickerController defaultAssetsLibrary];
        self.galleryPicker.shouldShowSavedPhotosOnTop=YES;
        switch (assetsType) {
            case DGAssetsTypeOnlyPhotos:
                photoAndVideoCamera=NO;
                self.galleryPicker.assetsFilter=[ALAssetsFilter allPhotos];
                break;
            case DGAssetsTypeOnlyVideos:
                photoAndVideoCamera=NO;
                self.galleryPicker.assetsFilter=[ALAssetsFilter allVideos];
                break;
            case DGAssetsTypeAll:
            default:
                photoAndVideoCamera=YES;
                self.galleryPicker.assetsFilter=[ALAssetsFilter allAssets];
                break;
        }
        if(maxItems)
            self.galleryPicker.maximumNumberOfPhotos=[maxItems intValue];
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            self.cameraOverlay=[[[CameraOverlayView alloc]initWithFrame:self.view.frame]autorelease]; 
            self.cameraOverlay.delegate=self;
            self.cameraPicker= [[[CustomImagePickerController alloc] init]autorelease];
            self.cameraPicker.allowsEditing=YES;
            self.cameraPicker.delegate = self;
            self.cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.cameraPicker.cameraOverlayView = self.cameraOverlay;        
            self.cameraPicker.showsCameraControls=NO;
            self.cameraPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
//-            UIImagePickerControllerQualityTypeIFrame1280x720
//-            UIImagePickerControllerQualityTypeIFrame960x540
//-            UIImagePickerControllerQualityType640x480
//-            UIImagePickerControllerQualityTypeLow
//-            UIImagePickerControllerQualityTypeMedium
//-            UIImagePickerControllerQualityTypeHigh;
            self.cameraPicker.videoQuality=UIImagePickerControllerQualityTypeHigh;
            self.cameraOverlay.cameraPicker=self.cameraPicker;
            // Gallery to Camera Switch
            self.galleryPicker.toolbarRightButton=[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(galleryCameraButtonPressed)]autorelease];
            self.cameraOverlay.photoAndVideo=photoAndVideoCamera;
        }                
        if(self.cameraPicker){
            self.presentedPicker=self.cameraPicker;
            [self.view addSubview:self.cameraPicker.view];
        }else{
            self.presentedPicker=self.galleryPicker;
            [self.view addSubview:self.galleryPicker.view];
        }        
    }
    return self;
}
-(void)loadView{
    CGRect viewFrame=[[UIScreen mainScreen] bounds];
    self.view=[[[UIView alloc]initWithFrame:viewFrame]autorelease];    
    self.wantsFullScreenLayout=YES;
}
- (void)viewDidLoad{
    [super viewDidLoad];
}
- (void)galleryCameraButtonPressed{
    [self galleryCameraButtonPressedWithAnimationDuration:0.8];
}
- (void)galleryCameraButtonPressedWithAnimationDuration:(CGFloat)duration{
    [UIView transitionFromView:self.galleryPicker.view toView:self.cameraPicker.view duration:duration options:UIViewAnimationOptionTransitionFlipFromRight completion:^(BOOL finished) {
        if(finished){
            self.presentedPicker=self.cameraPicker;            
        }
    }];
    
}
- (void)cameraOverlayViewGalleryButtonPressed:(CameraOverlayView *)cameraOverlayView{
    [self cameraOverlayViewGalleryButtonPressed:cameraOverlayView AnimationDuration:0.8];
}
- (void)cameraOverlayViewGalleryButtonPressed:(CameraOverlayView *)cameraOverlayView AnimationDuration:(CGFloat)duration{
    [UIView transitionFromView:self.cameraPicker.view toView:self.galleryPicker.view duration:duration options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
        if(finished){
            self.presentedPicker=self.galleryPicker;                                 
        }
    }];    
}
- (void) presentCameraPicker{
    if(![self.presentedPicker isKindOfClass:[self.cameraPicker class]] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [self galleryCameraButtonPressedWithAnimationDuration:0.0];
}
- (void) presentGalleryPicker{
    if(![self.presentedPicker isKindOfClass:[self.galleryPicker class]])
        [self cameraOverlayViewGalleryButtonPressed:self.cameraOverlay AnimationDuration:0.0];
}

-(void)cameraCancel{    
    if(self.failureBlock){
        self.failureBlock(nil);
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if(info){        
        if([[info objectForKey:UIImagePickerControllerMediaType]isEqualToString:@"public.image"]){            
            NSArray *infoArray=nil;
            UIImage *image=[info objectForKey:UIImagePickerControllerOriginalImage];                
            __block NSDate *shootingDate=[[NSDate date]retain];
            NSDictionary *picker=[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:image,shootingDate, nil] forKeys:[NSArray arrayWithObjects:@"public.jpeg",@"shootingDate", nil]]; 
            infoArray=[NSArray arrayWithObject:picker];
            createBlockSafeSelf();
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [blockSafeSelf.library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL * assetURL, NSError * error){
                    if(error){
                        DebugLog(@"Error saving image : %@",error.userInfo);                            
                    }else {
                        DebugLog(@"Image saved successfully");     
                        [blockSafeSelf.selectedAssetsURLS addObject:assetURL];
                        LogObject(blockSafeSelf.selectedAssetsURLS);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSDictionary *ALAssetInfo=[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:assetURL,shootingDate, nil] forKeys:[NSArray arrayWithObjects:@"ALAssetURL",@"shootingDate", nil]];
                            [[NSNotificationCenter defaultCenter]postNotificationName:kDGImagePickerSavedIntoLibraryNotification object:nil userInfo:ALAssetInfo];
                            [shootingDate release];
                        });
                    }
                }];
            });
            if(self.successBlock){
                self.successBlock(infoArray);
            }
            
        }else if([[info objectForKey:UIImagePickerControllerMediaType]isEqualToString:@"public.movie"]){
            NSString *videoFilePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
            __block NSArray *infoArray=nil;
            if ( UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoFilePath))
            {
                createBlockSafeSelf();                
                [self.library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:videoFilePath] completionBlock:^(NSURL *assetURL, NSError *error) {
                    if(error){
                        NSLog(@"Error saving video : %@",error.userInfo);
                        [blockSafeSelf.progressHud dismissWithError:@"Error Guardando Vídeo" afterDelay:0.5];
                        if(self.failureBlock){
                            self.failureBlock(error);
                        }
                    }else {
                        NSLog(@"Video saved successfully");                                                
                        [self.library assetForURL:assetURL resultBlock:^(ALAsset * asset){                        
                            if(asset){
                                [blockSafeSelf.selectedAssetsURLS addObject:assetURL];
                                [blockSafeSelf.progressHud dismissWithSuccess:@"Guardado !!" afterDelay:0.5];  
                                infoArray=[NSArray arrayWithObject:asset];
                                if(self.successBlock){
                                    self.successBlock(infoArray);
                                }                                
                            }
                        }
                        failureBlock:^(NSError * error){
                            NSLog(@"cannot get video - %@", [error localizedDescription]);
                            [blockSafeSelf.progressHud dismissWithError:@"Error Guardando Vídeo" afterDelay:0.5];
                            if(self.failureBlock){
                                self.failureBlock(error);
                            }
                        }];
                    }
                }];
            } 
        }
    }
}
- (void)agImagePickerController:(AGImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info{
    if(self.showPreview){            
        DebugLog(@"Show preview");
        ALAsset *assetItem=[info objectAtIndex:0];
        UIImage *image=[UIImage imageWithCGImage:[[assetItem defaultRepresentation] fullScreenImage]];
        [self.navigationController pushViewController:[[[ImagePreviewViewController alloc]initWithImage:image]autorelease] animated:YES];
    }else {
        DebugLog(@"Don't Show preview");
        if(self.successBlock){
            self.successBlock(info);
        }
    }
}
- (void)agImagePickerController:(AGImagePickerController *)picker didFail:(NSError *)error{
    if(self.failureBlock){
        self.failureBlock(error);
    }
}

- (void)cameraOverlayView:(CameraOverlayView *)cameraOverlayView lastPictureFromGalleryLoaded:(UIImage *)lastPictureFromGallery{
 
}
- (void)cameraOverlayViewDidDisappearFromScreen:(CameraOverlayView *)cameraOverlayView{
}
-(void)viewWillAppear:(BOOL)animated{ 
    LogMethod();
    [super viewWillAppear:animated];    
    [self.cameraOverlay updateLastPhotoTaken];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    self.navigationController.navigationBarHidden=YES;
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];    
    self.navigationController.navigationBarHidden=NO;
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.cameraOverlay resetOriginalState];
}
- (void)viewDidUnload{
    LogMethod();
    [super viewDidUnload];
}
-(void)dealloc{
    LogMethod();
    [_library release];
    [_selectedAssetsURLS release];
    [imagePickerVC release];
    [cameraOverlay release];
    [cameraPicker release];
    [galleryPicker release];
    [super dealloc];
}
@end
