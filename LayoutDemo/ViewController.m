//
//  ViewController.m
//  LayoutDemo
//
//  Created by wyzc on 2018/4/4.
//  Copyright © 2018年 taiben. All rights reserved.
//

#import "ViewController.h"
#import "ReorderCollectionViewLayout.h"
#import "VideoCollectionViewCell.h"

#define SCreenWidth [UIScreen mainScreen].bounds.size.width

@interface ViewController ()<ReorderCollectionViewLayoutDataSource,ReorderCollectionViewLayoutDelegate>
{
    BOOL isDrag;
}
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *viewsArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    isDrag = YES;
    ReorderCollectionViewLayout *followLayout = [[ReorderCollectionViewLayout alloc] init];
    followLayout.itemSize = CGSizeMake(SCreenWidth / 8.0 , self.view.bounds.size.height / 8.0);
    followLayout.minimumLineSpacing = 0;
    followLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:followLayout];
    [self.view addSubview:collectionView];
    _collectionView = collectionView;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    [self setupViewsArray];
    [collectionView registerNib:[UINib nibWithNibName:@"VideoCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"cellID"];
    
}
- (void)setupViewsArray{
    [_viewsArray removeAllObjects]; _viewsArray = nil;
    _viewsArray = [NSMutableArray array];
    for (NSInteger i = 1; i <= 50; i++) {
        UIView *view = [[UIView alloc] init];
        [_viewsArray addObject:view];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _viewsArray.count;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 5.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 5.f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(5.f, 0, 5.f, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForLargeItemsInSection:(NSInteger)section{
    return CGSizeZero;
}

- (UIEdgeInsets)autoScrollTrigerEdgeInsets:(UICollectionView *)collectionView{
    return UIEdgeInsetsMake(50.f, 0, 50.f, 0);
}

- (UIEdgeInsets)autoScrollTrigerPadding:(UICollectionView *)collectionView{
    return UIEdgeInsetsMake(64.f, 0, 0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath{
    if (isDrag) {//拖拽
        [self.collectionView reloadData];
    }else{
        //长按
    }
    isDrag = YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath{
    UIView *view = [_viewsArray objectAtIndex:fromIndexPath.item];
    [_viewsArray removeObjectAtIndex:fromIndexPath.item];
    [_viewsArray insertObject:view atIndex:toIndexPath.item];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"cellID";
    VideoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"VideoCollectionViewCell" owner:self options:nil] lastObject];
    }
    cell.smallView = _viewsArray[indexPath.item];
    cell.indexLab.text = [NSString stringWithFormat:@"%ld",indexPath.item];
    cell.deleteItemBlock = ^() {
        isDrag = NO;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"确定删除此项？"preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_viewsArray.count == 1) {
                return;
            }
            [self.collectionView performBatchUpdates:^{
                [_viewsArray removeObjectAtIndex:indexPath.item];
                [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            } completion:^(BOOL finished) {
                [self.collectionView reloadData];
            }];
        }];
        [alert addAction:cancelAction];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    };
    return cell;
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"点击了view %ld",indexPath.item);
    
}

- (void)reflesh:(UIBarButtonItem *)sender{
    [self setupViewsArray];
    [self.collectionView reloadData];
}



@end
