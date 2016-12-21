//
//  TagView.m
//  MoveTag
//
//  Created by txx on 16/12/21.
//  Copyright © 2016年 txx. All rights reserved.
//

#import "TagView.h"
#import "CollectionViewCell.h"
#import "CollectionReusableView.h"

@interface TagView()<UICollectionViewDelegate,UICollectionViewDataSource,UIGestureRecognizerDelegate>
{
    NSIndexPath *_currentIndexPath;
    CGPoint _deltaPoint;
}

@property(nonatomic,strong)NSMutableArray<NSString *>       *selectItems;
@property(nonatomic,strong)NSMutableArray<NSString *>       *unSelectItems;

@property(nonatomic,strong)UICollectionView                *collectionView;
@property(nonatomic,strong)UICollectionViewFlowLayout      *flowLayout;

@property(nonatomic,strong)UIPanGestureRecognizer          *panGesture;
@property(nonatomic,strong)UILongPressGestureRecognizer    *longPressGesture;

/**
 快照
 */
@property (strong, nonatomic) UIView *snapedImageView;

@end

static NSString *const TCellId = @"TCellId";
static NSString *const TReusableId = @"TReusableId";

@implementation TagView

- (instancetype)initWithFrame:(CGRect)frame SelectedItems:(NSArray<NSString *> *)selectedItems unselectedItems:(NSArray<NSString *> *)unselectedItems
{
    self = [super initWithFrame:frame];
    if (self) {
        _selectItems = [selectedItems mutableCopy];
        _unSelectItems = [unselectedItems mutableCopy];
        
        _unSelectItemTitle = @"      点击添加更多栏目";
        [self addSubview:self.collectionView];
        [self.collectionView addGestureRecognizer:self.panGesture];
        [self.collectionView addGestureRecognizer:self.longPressGesture];

    }
    return self;
}
-(void)setEditState:(BOOL)editState
{
    _editState = editState;
    if (_delegate && [_delegate respondsToSelector:@selector(tagView:editState:)]) {
        [_delegate tagView:self editState:_editState];
    }
    [self.collectionView reloadData];
}

-(void)panGestureHandler:(UIPanGestureRecognizer *)panGesture
{
    CGPoint location = [panGesture locationInView:self.collectionView];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            // 获取当前手指所在的cell
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:_currentIndexPath];
            // 截取当前cell 保存为snapedImageView
            self.snapedImageView = [cell snapshotViewAfterScreenUpdates:NO];
            // 设置初始位置和当前cell一样
            self.snapedImageView.center = cell.center;
            // 隐藏当前cell
            cell.alpha = 0.f;
            // 记录当前手指的位置的x和y距离cell的x,y的间距, 便于同步截图的位置
            _deltaPoint = CGPointMake(location.x - cell.frame.origin.x, location.y - cell.frame.origin.y);
            // 放大截图
            self.snapedImageView.transform = CGAffineTransformMakeScale(1.4, 1.4);
            // 添加截图到collectionView上
            [self.collectionView addSubview:self.snapedImageView];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            // 这种设置并不精准, 效果不好, 开始移动的时候有跳跃现象
            //            self.snapedImageView.center = location;
            CGRect snapViewFrame = self.snapedImageView.frame;
            snapViewFrame.origin.x =  location.x - _deltaPoint.x;
            snapViewFrame.origin.y =  location.y - _deltaPoint.y;
            self.snapedImageView.frame = snapViewFrame;
            
            // 获取当前手指的位置对应的indexPath
            NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:location];
            if (newIndexPath &&  // 不为nil的时候
                newIndexPath.section == _currentIndexPath.section && // 只在同一个section中移动
                newIndexPath.row != 0 // 第一个不要移动
                ) {
                
                // 更新数据
                // 同一个section中, 需要将两个下标之间的所有的数据改变位置(前移或者后移)
                NSMutableArray *oldRows = [self.selectItems mutableCopy];
                // 当手指所在的cell在截图cell的后面的时候
                if (newIndexPath.row > _currentIndexPath.row) {
                    // 将这个区间的数据都前后交换, 就能够达到 数组中这两个下标之间所有的数据都向前移动一位 并且currentIndexPath.row的元素移动到了newIndexPath.row的位置
                    for (NSInteger index = _currentIndexPath.row; index<newIndexPath.row; index++) {
                        [oldRows exchangeObjectAtIndex:index withObjectAtIndex:index+1];
                    }
                    
                    // 或者可以像下面这样来处理
                    // 缓存最初的元素
                    id tempFirst = oldRows[_currentIndexPath.row];
                    for (NSInteger index = _currentIndexPath.row; index<newIndexPath.row; index++) {
                        if (index != newIndexPath.row - 1) {
                            // 这之间的所有的元素前移一位
                            oldRows[index] = oldRows[index++];
                        }
                        else {
                            // 第一个元素移动到这个区间的最后
                            oldRows[index] = tempFirst;
                        }
                    }
                    
                }
                if (newIndexPath.row < _currentIndexPath.row) {
                    
                    for (NSInteger index = _currentIndexPath.row; index>newIndexPath.row; index--) {
                        [oldRows exchangeObjectAtIndex:index withObjectAtIndex:index-1];
                    }
                }
                // 先更新数据设置为交换后的数据
                self.selectItems = oldRows;
                // 再移动cell
                [self.collectionView moveItemAtIndexPath:_currentIndexPath toIndexPath:newIndexPath];
                
                // 获取到新位置的cell
                UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:newIndexPath];
                // 设置为移动后的新的indexPath
                _currentIndexPath = newIndexPath;
                // 隐藏新的cell
                cell.alpha = 0.f;
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            // 获取当前的cell
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:_currentIndexPath];
            // 显示隐藏的cell
            cell.alpha = 1.f;
            // 删除cell的截图
            [self.snapedImageView removeFromSuperview];
            _currentIndexPath = nil;
            break;
        }
        default:
            break;
    }
}

/**
 手势代理
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // 手指的位置
    CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
    // 获取手指所在的位置的cell的indexPath -- 位置不在cell上时为nil
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (gestureRecognizer == _panGesture) {
        if (indexPath) { // indexPath不为nil 说明手指开始的位置是在cell上面
            if (indexPath.section == 0 && indexPath.row != 0 && _editState) {
                // 只允许第一个section里面的cell响应手势
                // 并且不允许拖动第一个cell, 当然你可以自定义不能拖动的cell
                _currentIndexPath = indexPath;
                return YES;
            }
        }
        return NO;
    }
    if (gestureRecognizer == _longPressGesture) {
        if (!_editState && indexPath.section == 0) return YES;
        else return NO;
    }
    return YES;
}

-(void)longPressHandler:(UILongPressGestureRecognizer *)longPressGesture
{
    self.editState = YES;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_editState) {
        if (indexPath.section == 0)
        {
            if (indexPath.row == 0) return ;
            [self.unSelectItems addObject:self.selectItems[indexPath.row]];
            [self.selectItems removeObjectAtIndex:indexPath.row];
            // 在第二组最后增加一个
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:self.unSelectItems.count-1 inSection:1];
            [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
        }else
        {
            [self.selectItems addObject:self.unSelectItems[indexPath.row]];
            [self.unSelectItems removeObjectAtIndex:indexPath.row];
            
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:self.selectItems.count-1 inSection:0];
            [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
        }
    }else
    {
        if (indexPath.section == 0) {
            if (_delegate && [_delegate respondsToSelector:@selector(tagView:selectedTag:)]) {
                [_delegate tagView:self selectedTag:indexPath.row];
            }
        }else
        {
            [self.selectItems addObject:self.unSelectItems[indexPath.row]];
            [self.unSelectItems removeObjectAtIndex:indexPath.row];
            
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:self.selectItems.count-1 inSection:0];
            [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
        }
    }
}





-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) return self.selectItems.count;
    return self.unSelectItems.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:TCellId forIndexPath:indexPath];
    
    if (indexPath.section == 0)
    {
        cell.titleLabel.text = self.selectItems[indexPath.row];
    }else
    {
        cell.titleLabel.text = self.unSelectItems[indexPath.row];
    }
    cell.editeState = self.editState;
    return cell ;
}
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:TReusableId forIndexPath:indexPath];
    if (indexPath.section == 0) header.titleLabel.text = @"";
    header.titleLabel.text = _unSelectItemTitle;
    return header;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == 0) return CGSizeZero;
        return CGSizeMake(100, 44);
}


- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:TCellId];
        [_collectionView registerClass:[CollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:TReusableId];
        _collectionView.backgroundColor = [UIColor whiteColor];
    }
    return _collectionView;
}
-(UICollectionViewFlowLayout *)flowLayout
{
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc]init];
        _flowLayout.itemSize = CGSizeMake(100, 44);
        _flowLayout.sectionInset = UIEdgeInsetsMake(0, 15, 0, 15);
        _flowLayout.headerReferenceSize = CGSizeMake(100, 44);
    }
    return _flowLayout;
}
- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandler:)];
        _panGesture.delegate = self;
        // 优先执行collectionView系统的手势
//        [_panGesture requireGestureRecognizerToFail:self.collectionView.panGestureRecognizer];
    }
    return _panGesture;
}
- (UILongPressGestureRecognizer *)longPressGesture {
    if (!_longPressGesture) {
         _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
        _longPressGesture.delegate = self;
    }
    return _longPressGesture;
}
@end
