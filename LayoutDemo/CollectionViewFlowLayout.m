//
//  CollectionViewFlowLayout.m
//  LayoutDemo
//
//  Created by wyzc on 2018/4/4.
//  Copyright © 2018年 taiben. All rights reserved.
//

#import "CollectionViewFlowLayout.h"

@interface CollectionViewFlowLayout()
{
    CGFloat _itemSpacing;
    CGFloat _lineSpacing;
}
@property (nonatomic, assign) NSInteger numOfLines;
@property (nonatomic, assign) NSInteger numOfCells;
@property (nonatomic, assign) CGSize collectionViewSize;
@property (nonatomic, assign) UIEdgeInsets insets;
@end


@implementation CollectionViewFlowLayout

- (void)prepareLayout{
    [super prepareLayout];
    
    self.delegate = (id<CollectionViewDelegateLayout>)self.collectionView.delegate;
    
    _collectionViewSize = self.collectionView.bounds.size;
    
    _numOfCells = [self.collectionView numberOfItemsInSection:0];
    
    _numOfLines = ceil((CGFloat)_numOfCells / 3.f);//每行3个cell
}

- (id<CollectionViewDelegateLayout>)delegate{
    return (id<CollectionViewDelegateLayout>)self.collectionView.delegate;
}

//ContentSize
- (CGSize)collectionViewContentSize
{
    CGSize contentSize = CGSizeMake(_collectionViewSize.width, (_numOfLines * _smallCellSize.height + ((_numOfLines-1)/3+2)*_smallCellSize.height) + _insets.top + _insets.bottom);//总高
    
    return contentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    NSMutableArray *attributesArray = [NSMutableArray array];
    for (NSInteger i = 0; i < _numOfCells; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    return  attributesArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    _itemSpacing = 0;
    _lineSpacing = 0;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        _itemSpacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:indexPath.section];
    } if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        _lineSpacing = [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:indexPath.section];
    }
    //cellSize
    CGFloat largeCellSideLength = (2.f * (_collectionViewSize.width - _insets.left - _insets.right) - _itemSpacing) / 3.f;
    CGFloat smallCellSideLength = (largeCellSideLength - _itemSpacing) / 2.f;
    _largeCellSize = CGSizeMake(largeCellSideLength, largeCellSideLength);
    _smallCellSize = CGSizeMake(smallCellSideLength, smallCellSideLength);
    
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForLargeItemsInSection:)]) {
        if (!CGSizeEqualToSize([self.delegate collectionView:self.collectionView layout:self sizeForLargeItemsInSection:indexPath.section], CGSizeZero)) {
            _largeCellSize = [self.delegate collectionView:self.collectionView layout:self sizeForLargeItemsInSection:indexPath.section];
            _smallCellSize = CGSizeMake(_collectionViewSize.width - _largeCellSize.width - _itemSpacing - _insets.left - _insets.right, (_largeCellSize.height / 2.f) - (_itemSpacing / 2.f));
        }
    }
    //insets
    _insets = UIEdgeInsetsMake(0, 0, 0, 0);
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        _insets = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:indexPath.section];
    }
    
    NSInteger line = indexPath.item / 3;
    CGFloat lineSpaceForIndexPath = _lineSpacing * line;
    CGFloat lineOriginY = (indexPath.item/3+indexPath.item/9)*_smallCellSize.height + lineSpaceForIndexPath + _insets.top;//适于大cell
    CGFloat lineOriginYSmall = (indexPath.item/3+1+indexPath.item/9)*_smallCellSize.height + lineSpaceForIndexPath + _insets.top;//适于小cell
    CGFloat rightSideLargeCellOriginX = _collectionViewSize.width - _largeCellSize.width - _insets.right;
    CGFloat rightSideSmallCellOriginX = _collectionViewSize.width - _smallCellSize.width - _insets.right;
    
    if ((indexPath.item+17)%18 == 0) { //右大
        attribute.frame = CGRectMake(rightSideLargeCellOriginX,lineOriginY,_largeCellSize.width,_largeCellSize.height);
    }else if ((indexPath.item+9) % 18 == 0) { //左大
        attribute.frame = CGRectMake(_insets.left,lineOriginY,_largeCellSize.width,_largeCellSize.height);
    }else if ((indexPath.item)%18 == 0) { //左上小
        
        attribute.frame = CGRectMake(_insets.left,(indexPath.item*4/9)*_smallCellSize.height+lineSpaceForIndexPath + _insets.top,_smallCellSize.width,_smallCellSize.height);
    }else if ((indexPath.item+17-1) % 18 == 0) { //左下小
        
        attribute.frame = CGRectMake(_insets.left,(indexPath.item*4/9+1)*_smallCellSize.height+lineSpaceForIndexPath + _insets.top,_smallCellSize.width,_smallCellSize.height);
    }else if ((indexPath.item+8)%18 == 0) { //右上小
        attribute.frame = CGRectMake(rightSideSmallCellOriginX,lineOriginY,_smallCellSize.width,_smallCellSize.height);
    }else if ((indexPath.item+7) % 18 == 0) { //右下小
        attribute.frame = CGRectMake(rightSideSmallCellOriginX,lineOriginY+_smallCellSize.height,_smallCellSize.width,_smallCellSize.height);
    }else{
        //小cell
        if ((indexPath.item%3 == 0)) { //小（左）
            attribute.frame = CGRectMake(_insets.left,lineOriginYSmall,_smallCellSize.width,_smallCellSize.height);
        }else if ((indexPath.item+2)%3 == 0) { //小（中）
            attribute.frame = CGRectMake(rightSideLargeCellOriginX,lineOriginYSmall,_smallCellSize.width,_smallCellSize.height);
        }else if ((indexPath.item+1)%3 == 0){ //小（右）
            attribute.frame = CGRectMake(rightSideSmallCellOriginX,lineOriginYSmall,_smallCellSize.width,_smallCellSize.height);
        }else{
            attribute.frame = CGRectMake(rightSideSmallCellOriginX,lineOriginYSmall,_smallCellSize.width,_smallCellSize.height);
        }
    }
    
    return attribute;
}
@end
