//
//  MACCameraListViewController.m
//  MultiAirCam
//
//  Created by Martin Gratzer on 09.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import "MACCameraListViewController.h"
#import "MACCameraCollectionViewCell.h"

#define CELL_REUSE_ID @"CameraCell"

@interface MACCameraListViewController () <MACCameraCollectionViewCellDelegate, TMFConnectorDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {    
    UICollectionView *_collectionView;
    NSMutableArray *_cameras;

    NSLock *_subscribeLock;
}
@end

@implementation MACCameraListViewController
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)loadView {
    [super loadView];

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[self createLayout]];
    _collectionView.opaque = YES;
    _collectionView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [_collectionView registerClass:[MACCameraCollectionViewCell class] forCellWithReuseIdentifier:CELL_REUSE_ID];    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;

    [self.view addSubview:_collectionView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _cameras = [NSMutableArray new];
    _subscribeLock = [NSLock new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
#warning TODO: Start discovery for all needed commands
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

#pragma mark TMFConnectorDelegate
- (void)connector:(TMFConnector *)tmf didChangeDiscoveringPeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)type {
    [_subscribeLock lock];
    if(![_cameras containsObject:peer] && type == TMFPeerChangeUpdate) {
        type = TMFPeerChangeFound;
    }

    NSIndexPath *ip = [self indexPathOfCamera:peer];
    if(type == TMFPeerChangeRemove) {
    	[_cameras removeObject:peer];
    }
    else if (type == TMFPeerChangeFound) {
        [_cameras addObject:peer];
        ip = [self indexPathOfCamera:peer];        
    }

    [_collectionView performBatchUpdates:^{
        switch(type) {
            case TMFPeerChangeFound: {
                [_collectionView insertItemsAtIndexPaths:@[ip]];
            }
                break;

            case TMFPeerChangeRemove: {
                [_collectionView deleteItemsAtIndexPaths:@[ip]];
            }
                break;

            case TMFPeerChangeUpdate: {
                [_collectionView reloadItemsAtIndexPaths:@[ip]];
            }
                break;
        }
    }
                              completion:^(BOOL finished) {
                                  if(finished) {
                                      if(type == TMFPeerChangeFound) {
                                          [self subscribe:peer];
                                      }
                                  }
                              }];
    [_subscribeLock unlock];
}

#pragma mark UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_cameras count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MACCameraCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_REUSE_ID forIndexPath:indexPath];
    [self configureCell:cell atIndexpath:indexPath];
    return cell;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(320.0f, 280.0f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f);
}

#pragma mark MACCameraCollectionViewCellDelegate
- (void)takePictureWithCell:(MACCameraCollectionViewCell *)cell {
    NSParameterAssert(cell != nil);
    NSParameterAssert(cell.camera != nil);
#warning TODO: Send MACCameraActionTakePicture action
}

- (void)toggleFlashWithCell:(MACCameraCollectionViewCell *)cell {
    NSParameterAssert(cell != nil);
    NSParameterAssert(cell.camera != nil);
#warning TODO: Send MACCameraActionToggleFlash action
}

- (void)flipCameraWithCell:(MACCameraCollectionViewCell *)cell {
    NSParameterAssert(cell != nil);
    NSParameterAssert(cell.camera != nil);
#warning TODO: Send MACCameraActionToggleCamera action
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)subscribe:(TMFPeer *)camera {
    NSParameterAssert(camera!=nil);
#warning TODO: Subscribe to all commands of the given peer
}

- (void)configureCell:(MACCameraCollectionViewCell *)cell atIndexpath:(NSIndexPath *)indexPath {
    cell.camera = [_cameras objectAtIndex:indexPath.row];
    cell.delegate = self;
}

- (UICollectionViewLayout *)createLayout {
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    return flowLayout;
}

- (NSIndexPath *)indexPathOfCamera:(TMFPeer *)camera {
    if([_cameras containsObject:camera]) {
        NSUInteger idx = [_cameras indexOfObject:camera];
        return [NSIndexPath indexPathForRow:idx inSection:0];
    }
    return nil;
}

- (void)subscribeError:(NSError *)error camera:(TMFPeer *)camera {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Subscribe Error", @"")
                                message:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Could not subscribe at", @""), camera.name, error]
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                      otherButtonTitles:nil] show];
}

- (void)actionError:(NSError *)error camera:(TMFPeer *)camera {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                message:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Could not send action to", @""), camera.name, error]
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                      otherButtonTitles:nil] show];
}

@end
