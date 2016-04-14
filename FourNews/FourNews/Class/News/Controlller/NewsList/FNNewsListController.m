//
//  FNNewsListController.m
//  FourNews
//
//  Created by admin on 16/3/28.
//  Copyright © 2016年 天涯海北. All rights reserved.
//

#import "FNNewsListController.h"
#import "FNNewsListItem.h"
#import "FNGetNewsListDatas.h"
#import "FNNewsSglImgCell.h"
#import "FNNewsThrImgCell.h"
#import "FNGetListCell.h"
#import "FNTabBarController.h"
#import "FNNewsDetailController.h"
#import "FNNewsGetDetailNews.h"
#import "FNNewsGetReply.h"
#import "FNNewsPhotoSetController.h"
#import "FNNewsGetPhotoSetItem.h"
#import <MJRefresh.h>

typedef NS_ENUM(NSUInteger, FNNewsListCellHeightType) {
    FNNewsListCellHeightTypeAD = 200,
    FNNewsListCellHeightTypeSgl = 90,
    FNNewsListCellHeightTypeThr = 120,
};

@interface FNNewsListController ()

@property (nonatomic, strong) NSMutableArray<FNNewsListItem *> *newsListArray;

@property (nonatomic, assign) NSInteger refreshCount;

@property (nonatomic, strong) NSArray *replyArray;

@end

@implementation FNNewsListController


- (NSMutableArray *)newsListArray
{
    if (!_newsListArray) {
        NSMutableArray *arr = [NSMutableArray array];
        _newsListArray = arr;
    }
    
    return _newsListArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.refreshCount = 1;
    // 设置估算高度，减少heightForRowAtIndexPath调用频率
    self.tableView.estimatedRowHeight = 100.0;
    // 设置刷新控件
    self.tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(bottomDragRefreshData)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(topDragRefreshData)];
    [self.tableView.mj_header beginRefreshing];
    
    // 监听通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonRepeatClick) name:FNTabBarButtonRepeatClickNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(titleButtonRepeatClick) name:FNTitleButtonRepeatClickNotification object:nil];
    
    // 右边内容条设置
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(YJNavBarMaxY+YJTitlesViewH, 0, YJTabBarH, 0);

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark - tabBarButton被点击调用的方法
- (void)tabBarButtonRepeatClick
{
    // 不在当前窗口 返回
    if (self.view.window == nil) return;
    // 不再屏幕中间 返回
    if (self.tableView.scrollsToTop == NO) return;
    
    [self.tableView.mj_header beginRefreshing];
}
- (void)titleButtonRepeatClick
{
    // 不在当前窗口 返回
    if (self.view.window == nil) return;
    // 不再屏幕中间 返回
    if (self.tableView.scrollsToTop == NO) return;
    
    [self.tableView.mj_header beginRefreshing];
}
#pragma mark - 上下拉刷新的方法
- (void)bottomDragRefreshData
{
    [FNGetNewsListDatas getNewsListItemsWithProgramaid:self.pgmid :1 :^(NSArray *array) {
        [self.tableView.mj_header endRefreshing];
        self.newsListArray = (NSMutableArray *)array;
        [self.tableView reloadData];
        [self.tableView.mj_header endRefreshing];
        
    }];
}
- (void)topDragRefreshData
{
    [FNGetNewsListDatas getNewsListItemsWithProgramaid:self.pgmid :++self.refreshCount :^(NSArray *array) {
        [self.newsListArray addObjectsFromArray:(NSMutableArray *)array];
        [self.tableView reloadData];
        [self.tableView.mj_footer endRefreshing];
    }];
}



#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.newsListArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    FNNewsListItem *item = self.newsListArray[indexPath.row];

    id cell = [FNGetListCell cellWithTableView:tableView :item :indexPath];
    [cell setContItem:item];


    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FNNewsListItem *item = self.newsListArray[indexPath.row];
    // 将算过的totalHeight存储，下次直接返回
    if (item.totalHeight==0) {
        if (indexPath.row == 0 && item.ads) {
            item.totalHeight = FNNewsListCellHeightTypeAD;
        } else if (item.imgextra) {
            item.totalHeight = FNNewsListCellHeightTypeThr;
        } else {
            item.totalHeight = FNNewsListCellHeightTypeSgl;
        }
    }
    return item.totalHeight;
    
}

#pragma mark - 监听cell的点击 跳转
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // 点击cell后
    // 1.拿到详情页的网络数据
    // 2.跳转到详情控制器
    // 3.详情控制器拿到数据进行数据展示
    
    
    FNNewsListItem *listItem = self.newsListArray[indexPath.row];
    if (listItem.photosetID) {
        FNNewsPhotoSetController *photoSetVC = [[FNNewsPhotoSetController alloc] init];
        photoSetVC.photoSetid = listItem.photosetID;
        photoSetVC.listItem = listItem;
        [self.navigationController pushViewController:photoSetVC animated:YES];
        
    } else {
        // 1.跳转
        FNNewsDetailController *detailVC = [[FNNewsDetailController alloc] init];
        [self.navigationController pushViewController:detailVC animated:YES];
        detailVC.listItem = listItem;
        // 传数据
        [FNNewsGetDetailNews getNewsDetailWithDocid:listItem.docid :^(FNNewsDetailItem *item) {
            [FNNewsGetReply hotReplyWithDetailItem:item :^(NSArray *array) {
                if (array == nil) {
                } else {
                    item.replys = array;
                }
                detailVC.detailItem = item;
                
            }];
            
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
