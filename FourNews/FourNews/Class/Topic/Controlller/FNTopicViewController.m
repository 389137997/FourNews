//
//  TopicViewController.m
//  FourNews
//
//  Created by admin on 16/3/27.
//  Copyright © 2016年 天涯海北. All rights reserved.
//

#import "FNTopicViewController.h"
#import "FNTopicGetListItem.h"
#import "FNTopicListCell.h"
#import <MJRefresh.h>
#import "FNTabBarController.h"
#import "FNTopicDetailController.h"

@interface FNTopicViewController()
@property (nonatomic, assign) NSInteger refreshCount;

@property (nonatomic, strong) NSMutableArray *listItems;

@end

@implementation FNTopicViewController
static NSString * const ID = @"cell";
static NSString * const FOOT = @"footer";
- (NSMutableArray *)listItems
{
    if (!_listItems) {
        _listItems = [NSMutableArray array];
    }
    return _listItems;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    // 设置下拉刷新
    self.tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(bottomDragRefreshData)];
    // 设置上拉刷新
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(topDragRefreshData)];
    // 加载完直接刷新
    [self.tableView.mj_header beginRefreshing];
    // 点击选项跳到顶部刷新
    FNTabBarController *tabBarVC = (FNTabBarController *)self.tabBarController;
    tabBarVC.newsBtnBlock = ^{
        [self.tableView.mj_header beginRefreshing];
    };
    
    // 注册cell
    [self.tableView registerNib:[UINib nibWithNibName:@"FNTopicListCell" bundle:nil] forCellReuseIdentifier:ID];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:FOOT];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)bottomDragRefreshData
{
    [FNTopicGetListItem getTopicNewsListWithPageCount:0 :^(NSArray *array) {
        self.listItems = (NSMutableArray*)array;
        [self.tableView reloadData];
        [self.tableView.mj_header endRefreshing];
    }];
}

- (void)topDragRefreshData
{
    [FNTopicGetListItem getTopicNewsListWithPageCount:++self.refreshCount :^(NSArray *array) {
        [self.listItems addObjectsFromArray:array];
        [self.tableView reloadData];
        [self.tableView.mj_footer endRefreshing];
    }];
}

#pragma mark - datasource数据源

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.listItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FNTopicListCell *cell = [tableView dequeueReusableCellWithIdentifier:ID forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.listItem = self.listItems[indexPath.section];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 338;
}
// 设置footer高度
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10;
}
// 设置footer样式
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footV = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FOOT];
    footV.contentView.backgroundColor = FNColor(200, 200, 200);
    
    return footV;
}

#pragma mark - tableViewDatagete


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FNTopicDetailController *detailVc = [[FNTopicDetailController alloc] init];
    detailVc.listItem = _listItems[indexPath.section];
    
    [self.navigationController pushViewController:detailVc animated:YES];
}



@end
