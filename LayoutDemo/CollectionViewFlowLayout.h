//
//  CollectionViewFlowLayout.h
//  LayoutDemo
//
//  Created by wyzc on 2018/4/4.
//  Copyright © 2018年 taiben. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CollectionViewDelegateLayout <UICollectionViewDelegateFlowLayout>

@optional

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForLargeItemsInSection:(NSInteger)section;

@end



@interface CollectionViewFlowLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) id<CollectionViewDelegateLayout> delegate;
@property (nonatomic, assign, readonly) CGSize largeCellSize;
@property (nonatomic, assign, readonly) CGSize smallCellSize;
@end
