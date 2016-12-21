//
//  ViewController.m
//  MoveTag
//
//  Created by txx on 16/12/21.
//  Copyright © 2016年 txx. All rights reserved.
//

#import "ViewController.h"
#import "TagView.h"

@interface ViewController ()<TagViewDelegate>
{
    TagView *view ;
}

@property (weak, nonatomic) IBOutlet UIButton *editButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_editButton setTitle:@"点击这里或者长按标签进入编辑" forState:UIControlStateNormal];
    [_editButton setTitle:@"编辑完成" forState:UIControlStateSelected];
    [_editButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_editButton addTarget:self action:@selector(editBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    NSMutableArray *selectedItems = [NSMutableArray array];
    for (int i = 0; i<10; i++) {
        NSString *title = [NSString stringWithFormat:@"select-%d",i];
        [selectedItems addObject:title];
    }
    
    NSMutableArray *unSelectedItems = [NSMutableArray array];
    for (int i = 0; i<10; i++) {
        NSString *title = [NSString stringWithFormat:@"unSelect-%d",i];
        [unSelectedItems addObject:title];
    }
    
    view = [[TagView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_editButton.frame), self.view.bounds.size.width, self.view.bounds.size.height-CGRectGetMaxY(_editButton.frame)) SelectedItems:selectedItems unselectedItems:unSelectedItems];
    view.delegate = self ;
    [self.view addSubview:view];

}
-(void)editBtnOnClick:(UIButton *)button
{
    view.editState = !button.isSelected;
    NSLog(@"%d",button.isSelected);
}
//delegate
-(void)tagView:(TagView *)tagView editState:(BOOL)state
{
    _editButton.selected = state;
}
-(void)tagView:(TagView *)tagView selectedTag:(NSInteger)row
{
    NSLog(@"点击了%ld",(long)row);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
