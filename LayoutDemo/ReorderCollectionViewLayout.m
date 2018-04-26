//
//  ReorderCollectionViewLayout.m
//  LayoutDemo
//
//  Created by wyzc on 2018/4/4.
//  Copyright © 2018年 taiben. All rights reserved.
//

#import "ReorderCollectionViewLayout.h"

typedef NS_ENUM(NSInteger, RAScrollDirction) {
    RAScrollDirctionNone,
    RAScrollDirctionUp,
    RAScrollDirctionDown
};


@interface UIImageView (RACollectionViewReorderableTripletLayout)

- (void)setCellCopiedImage:(UICollectionViewCell *)cell;

@end

@implementation UIImageView (RACollectionViewReorderableTripletLayout)

- (void)setCellCopiedImage:(UICollectionViewCell *)cell {
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 4.f);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = image;
}

@end

@interface ReorderCollectionViewLayout()
@property (nonatomic, strong) UIView *cellFakeView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) RAScrollDirction scrollDirection;
@property (nonatomic, strong) NSIndexPath *reorderingCellIndexPath;
@property (nonatomic, assign) CGPoint reorderingCellCenter;
@property (nonatomic, assign) CGPoint cellFakeViewCenter;
@property (nonatomic, assign) CGPoint panTranslation;
@property (nonatomic, assign) UIEdgeInsets scrollTrigerEdgeInsets;
@property (nonatomic, assign) UIEdgeInsets scrollTrigePadding;
@property (nonatomic, assign) BOOL setUped;
@end

@implementation ReorderCollectionViewLayout
@dynamic delegate;
@synthesize scrollDirection;

#pragma mark - Override methods

- (id<ReorderCollectionViewLayoutDelegate>)delegate
{
    return (id<ReorderCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

- (id<ReorderCollectionViewLayoutDataSource>)datasource
{
    return (id<ReorderCollectionViewLayoutDataSource>)self.collectionView.dataSource;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    //gesture
    [self setUpCollectionViewGesture];
    //scroll triger insets
    _scrollTrigerEdgeInsets = UIEdgeInsetsMake(50.f, 50.f, 50.f, 50.f);
    if ([self.delegate respondsToSelector:@selector(autoScrollTrigerEdgeInsets:)]) {
        _scrollTrigerEdgeInsets = [self.delegate autoScrollTrigerEdgeInsets:self.collectionView];
    }
    //scroll triger padding
    _scrollTrigePadding = UIEdgeInsetsMake(0, 0, 0, 0);
    if ([self.delegate respondsToSelector:@selector(autoScrollTrigerPadding:)]) {
        _scrollTrigePadding = [self.delegate autoScrollTrigerPadding:self.collectionView];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attribute = [super layoutAttributesForItemAtIndexPath:indexPath];
    if (attribute.representedElementCategory == UICollectionElementCategoryCell) {
        if ([attribute.indexPath isEqual:_reorderingCellIndexPath]) {
            attribute.hidden = YES;
        }
    }
    return attribute;
}

#pragma mark - Methods

- (void)setUpCollectionViewGesture
{
    if (!_setUped) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _longPressGesture.delegate = self;
        _panGesture.delegate = self;
        for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [gestureRecognizer requireGestureRecognizerToFail:_longPressGesture]; }}
        [self.collectionView addGestureRecognizer:_longPressGesture];
        [self.collectionView addGestureRecognizer:_panGesture];
        _setUped = YES;
    }
}

- (void)setUpDisplayLink
{
    if (_displayLink) {
        return;
    }
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoScroll)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

-  (void)invalidateDisplayLink
{
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)autoScroll
{
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    CGSize contentSize = self.collectionView.contentSize;
    CGSize boundsSize = self.collectionView.bounds.size;
    CGFloat increment = 0;
    
    if (self.scrollDirection == RAScrollDirctionDown) {
        CGFloat percentage = (((CGRectGetMaxY(_cellFakeView.frame) - contentOffset.y) - (boundsSize.height - _scrollTrigerEdgeInsets.bottom - _scrollTrigePadding.bottom)) / _scrollTrigerEdgeInsets.bottom);
        increment = 15 * percentage;
        if (increment >= 15.f) {
            increment = 15.f;
        }
    }else if (self.scrollDirection == RAScrollDirctionUp) {
        CGFloat percentage = (1.f - ((CGRectGetMinY(_cellFakeView.frame) - contentOffset.y - _scrollTrigePadding.top) / _scrollTrigerEdgeInsets.top));
        increment = -15.f * percentage;
        if (increment <= -15.f) {
            increment = -15.f;
        }
    }
    
    if (contentOffset.y + increment <= -contentInset.top) {
        self.collectionView.contentOffset = CGPointMake(contentOffset.x, -contentInset.top);
        [self invalidateDisplayLink];
        return;
    }else if (contentOffset.y + increment >= contentSize.height - boundsSize.height - contentInset.bottom) {
        self.collectionView.contentOffset = CGPointMake(contentOffset.x, contentSize.height - boundsSize.height - contentInset.bottom);
        [self invalidateDisplayLink];
        return;
    }
    
    _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + increment);
    _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
    self.collectionView.contentOffset = CGPointMake(contentOffset.x, contentOffset.y + increment);
    [self moveItemIfNeeded];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPress
{
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan: {
            //indexPath
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
            //can move
            if ([self.datasource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)]) {
                if (![self.datasource collectionView:self.collectionView canMoveItemAtIndexPath:indexPath]) {
                    return;
                }
            }
            //will begin dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:indexPath];
            }
            //indexPath
            _reorderingCellIndexPath = indexPath;
            //scrolls top off
            self.collectionView.scrollsToTop = NO;
            //cell fake view
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            _cellFakeView = [[UIView alloc] initWithFrame:cell.frame];
            _cellFakeView.clipsToBounds = YES;
            UIImageView *cellFakeImageView = [[UIImageView alloc] initWithFrame:cell.bounds];
            UIImageView *highlightedImageView = [[UIImageView alloc] initWithFrame:cell.bounds];
            cellFakeImageView.contentMode = UIViewContentModeScaleAspectFill;
            highlightedImageView.contentMode = UIViewContentModeScaleAspectFill;
            cellFakeImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            cell.highlighted = YES;
            [highlightedImageView setCellCopiedImage:cell];
            cell.highlighted = NO;
            [cellFakeImageView setCellCopiedImage:cell];
            [self.collectionView addSubview:_cellFakeView];
            [_cellFakeView addSubview:cellFakeImageView];
            [_cellFakeView addSubview:highlightedImageView];
            //set center
            _reorderingCellCenter = cell.center;
            _cellFakeViewCenter = _cellFakeView.center;
            [self invalidateLayout];
            //animation
            CGRect fakeViewRect = CGRectMake(cell.center.x - (self.smallCellSize.width / 2.f), cell.center.y - (self.smallCellSize.height / 2.f), self.smallCellSize.width, self.smallCellSize.height);
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.center = cell.center;
                _cellFakeView.frame = fakeViewRect;
                _cellFakeView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                highlightedImageView.alpha = 0;
            } completion:^(BOOL finished) {
                [highlightedImageView removeFromSuperview];
            }];
            //did begin dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self didBeginDraggingItemAtIndexPath:indexPath];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSIndexPath *currentCellIndexPath = _reorderingCellIndexPath;
            //will end dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentCellIndexPath];
            }
            //scrolls top on
            self.collectionView.scrollsToTop = YES;
            //disable auto scroll
            [self invalidateDisplayLink];
            //remove fake view
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:currentCellIndexPath];
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.transform = CGAffineTransformIdentity;
                _cellFakeView.frame = attributes.frame;
            } completion:^(BOOL finished) {
                [_cellFakeView removeFromSuperview];
                _cellFakeView = nil;
                _reorderingCellIndexPath = nil;
                _reorderingCellCenter = CGPointZero;
                _cellFakeViewCenter = CGPointZero;
                [self invalidateLayout];
                if (finished) {
                    //did end dragging
                    if ([self.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                        [self.delegate collectionView:self.collectionView layout:self didEndDraggingItemAtIndexPath:currentCellIndexPath];
                    }
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan
{
    switch (pan.state) {
        case UIGestureRecognizerStateChanged: {
            //translation
            _panTranslation = [pan translationInView:self.collectionView];
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
            //move layout
            [self moveItemIfNeeded];
            //scroll
            if (CGRectGetMaxY(_cellFakeView.frame) >= self.collectionView.contentOffset.y + (self.collectionView.bounds.size.height - _scrollTrigerEdgeInsets.bottom -_scrollTrigePadding.bottom)) {
                if (ceilf(self.collectionView.contentOffset.y) < self.collectionView.contentSize.height - self.collectionView.bounds.size.height) {
                    self.scrollDirection = RAScrollDirctionDown;
                    [self setUpDisplayLink];
                }
            }else if (CGRectGetMinY(_cellFakeView.frame) <= self.collectionView.contentOffset.y + _scrollTrigerEdgeInsets.top + _scrollTrigePadding.top) {
                if (self.collectionView.contentOffset.y > -self.collectionView.contentInset.top) {
                    self.scrollDirection = RAScrollDirctionUp;
                    [self setUpDisplayLink];
                }
            }else {
                self.scrollDirection = RAScrollDirctionNone;
                [self invalidateDisplayLink];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [self invalidateDisplayLink];
            break;
            
        default:
            break;
    }
}

- (void)moveItemIfNeeded
{
    NSIndexPath *atIndexPath = _reorderingCellIndexPath;
    NSIndexPath *toIndexPath = [self.collectionView indexPathForItemAtPoint:_cellFakeView.center];
    
    if (toIndexPath == nil || [atIndexPath isEqual:toIndexPath]) {
        return;
    }
    //can move
    if ([self.datasource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)]) {
        if (![self.datasource collectionView:self.collectionView itemAtIndexPath:atIndexPath canMoveToIndexPath:toIndexPath]) {
            return;
        }
    }
    
    //will move
    if ([self.datasource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.datasource collectionView:self.collectionView itemAtIndexPath:atIndexPath willMoveToIndexPath:toIndexPath];
    }
    //move
    [self.collectionView performBatchUpdates:^{
        //update cell indexPath
        _reorderingCellIndexPath = toIndexPath;
        [self.collectionView moveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];
        //did move
        if ([self.datasource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [self.datasource collectionView:self.collectionView itemAtIndexPath:atIndexPath didMoveToIndexPath:toIndexPath];
        }
    } completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_panGesture isEqual:gestureRecognizer]) {
        if (_longPressGesture.state == 0 || _longPressGesture.state == 5) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([_panGesture isEqual:gestureRecognizer]) {
        if (_longPressGesture.state != 0 && _longPressGesture.state != 5) {
            if ([_longPressGesture isEqual:otherGestureRecognizer]) {
                return YES;
            }
            return NO;
        }
    }else if ([_longPressGesture isEqual:gestureRecognizer]) {
        if ([_panGesture isEqual:otherGestureRecognizer]) {
            return YES;
        }
    }
    return YES;
}
@end

