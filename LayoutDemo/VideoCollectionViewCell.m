//
//  VideoCollectionViewCell.m
//  LayoutDemo
//
//  Created by wyzc on 2018/4/4.
//  Copyright © 2018年 taiben. All rights reserved.
//

#import "VideoCollectionViewCell.h"

@implementation VideoCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.smallView.backgroundColor = kRandomColor;
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    _longPressGesture.numberOfTouchesRequired = 1;
    _longPressGesture.allowableMovement = 100.0f;
    [self.smallView addGestureRecognizer:_longPressGesture];
    /*如果smallView是imageView类型，记得先打开手势开关
     imageView.userInteractionEnabled=YES;*/
}
-(void)handleLongPressGestures:(UILongPressGestureRecognizer *)paramSender{
    if ([paramSender isEqual:_longPressGesture]){
        if (_deleteItemBlock) {
            self.deleteItemBlock();
        }
    }
}
@end
