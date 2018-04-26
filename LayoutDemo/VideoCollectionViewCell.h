//
//  VideoCollectionViewCell.h
//  LayoutDemo
//
//  Created by wyzc on 2018/4/4.
//  Copyright © 2018年 taiben. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kRandomColor [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]
//typedef void(^DeleteItemBlock) (void);

@interface VideoCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *smallView;
@property (weak, nonatomic) IBOutlet UILabel *indexLab;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
//@property (nonatomic, copy) DeleteItemBlock deleteItemBlock;
@property (nonatomic, copy) dispatch_block_t deleteItemBlock;




@end
