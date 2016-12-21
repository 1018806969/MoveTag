//
//  TagView.h
//  MoveTag
//
//  Created by txx on 16/12/21.
//  Copyright © 2016年 txx. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TagView;
@protocol TagViewDelegate <NSObject>

-(void)tagView:(TagView *)tagView editState:(BOOL)state;

-(void)tagView:(TagView *)tagView selectedTag:(NSInteger)row;

@end

@interface TagView : UIView


@property(nonatomic,strong)NSString *unSelectItemTitle;
@property(nonatomic,assign)BOOL      editState;


@property(nonatomic,assign)id<TagViewDelegate>delegate;

- (instancetype)initWithFrame:(CGRect)frame SelectedItems:(NSArray<NSString *> *)selectedItems unselectedItems:(NSArray<NSString *> *)unselectedItems;


@end
