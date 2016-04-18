//
//  FNAVListController.m
//  FourNews
//
//  Created by admin on 16/4/10.
//  Copyright © 2016年 天涯海北. All rights reserved.
//

#import "FNAVListController.h"
#import "FNAVGetAVNewsList.h"
#import "FNAVListCell.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FNNewsReplyController.h"
#import <MJRefresh.h>
#import "FNTabBarController.h"
#import "FNAVDetailController.h"
#import "FNAVViewController.h"

@interface FNAVListController ()

@property (nonatomic, assign) NSInteger refreshCount;

@property (nonatomic, strong) NSMutableArray<FNAVListItem *> *listItemArray;

@property (nonatomic, strong) AVPlayerViewController *playerVC;

@property (nonatomic, strong) NSIndexPath *previousIndexPath;

@property (nonatomic, weak) FNAVDetailController *avDetailVc;

@property (nonatomic, weak) FNAVViewController *avVC;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVPlayer *player;
@end

@implementation FNAVListController
static NSString * const ID = @"cell";
- (NSArray *)listItemArray
{
    if (!_listItemArray){
        self.listItemArray = [[NSMutableArray alloc] init];
    }
    return _listItemArray;
    
}

- (AVPlayerViewController *)playerVC
{
    if (!_playerVC) {
        _playerVC = [[AVPlayerViewController alloc] init];
    }
    return _playerVC;
}


- (void)viewDidLoad
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    self.tableView.rowHeight = 290;
    [session setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // 设置下拉刷新
    self.tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(bottomDragRefreshData)];
    // 设置上拉刷新
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(topDragRefreshData)];
    // 加载完直接刷新
    [self.tableView.mj_header beginRefreshing];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FNAVListCell" bundle:nil] forCellReuseIdentifier:ID];
    
    // 右边内容条设置
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(YJNavBarMaxY+YJTitlesViewH, 0, YJTabBarH, 0);
    
    // 监听通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonRepeatClick) name:FNTabBarButtonRepeatClickNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(titleButtonRepeatClick) name:FNTitleButtonRepeatClickNotification object:nil];
    
//    UIImageView *navigationImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, FNScreenW, 44)];
//    navigationImgV.image = [self drawNavigationBar];
//    self.navigationController.navigationBarHidden = YES;
//    [self.parentViewController.view addSubview:navigationImgV];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    
//    self.navigationController.navigationBarHidden = YES;
//}
/** 截屏 */
- (UIImage *)drawScreen
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(FNScreenW, FNScreenH), NO, 0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [self.navigationController.view.layer renderInContext:ctx];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    NSData *data = UIImagePNGRepresentation(image);
            [data writeToFile:[NSString stringWithFormat:@"/Users/admin/Desktop/imag.png"]atomically:YES];
    return image;
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

- (void)bottomDragRefreshData
{
    [FNAVGetAVNewsList getAVNewsListWithTid:self.tid :0 :^(NSArray *array) {
        self.listItemArray = (NSMutableArray *)array;
        [self.tableView reloadData];
        [self.tableView.mj_header endRefreshing];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }];
}

- (void)topDragRefreshData
{
    [FNAVGetAVNewsList getAVNewsListWithTid:self.tid :++self.refreshCount :^(NSArray *array) {
        [self.listItemArray addObjectsFromArray:array];
        [self.tableView reloadData];
        [self.tableView.mj_footer endRefreshing];
    }];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.listItemArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    FNAVListCell *cell = [tableView dequeueReusableCellWithIdentifier:ID forIndexPath:indexPath];
    cell.listItem = self.listItemArray[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.movieBlock = ^(NSString *urlStr,UIView *playerV){
        [self playMovieWithUrlStr:urlStr :playerV];
    };
    cell.replyBlock = ^(FNAVListItem *item){
        [self replyClickWithListItem:item];
    };
//    NSLog(@"cell.frame%@",NSStringFromCGRect(cell.frame));
    return cell;
}

- (void)playMovieWithUrlStr:(NSString *)urlStr :(UIView *)playerV
{
    // 移除正在播放的窗口视频
    
    [self.avDetailVc.view removeFromSuperview];
    [self.avDetailVc removeFromParentViewController];
    
    // 取出当前indexPath
    NSIndexPath *indexPath;
    for (int i = 0; i<self.listItemArray.count; i++) { // 遍历取出
        if ([self.listItemArray[i].mp4_url isEqualToString:urlStr]) {
            indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    // 存在上一个indexPath，则刷新上一次播放的视频的cell
    if (self.previousIndexPath && indexPath.row != self.previousIndexPath.row) {
        [self.tableView reloadRowsAtIndexPaths:@[self.previousIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    // 保存当前indexPath
    self.previousIndexPath = indexPath;
    
    playerV.subviews.count ? [playerV.subviews[0] removeFromSuperview] : playerV.subviews.count;
    [self.playerVC.view removeFromSuperview];
    self.playerVC = nil;
    
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlStr]];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerVC.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.playerVC.showsPlaybackControls = YES;
    self.playerVC.player = self.player;
    self.playerVC.view.frame = playerV.bounds;
    [playerV addSubview:self.playerVC.view];
    
    [self.playerVC.player play];
}

#pragma mark -  跳转评论界面
- (void)replyClickWithListItem:(FNAVListItem *)item
{
    // 移除正在播放的非窗口视频
    if (self.previousIndexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[self.previousIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.playerVC.view removeFromSuperview];
    self.playerVC = nil;
    
    FNAVViewController *avVC = (FNAVViewController *)[self parentViewController];
    // 1.跳转.
    // 用画的图片遮盖
    UIImageView *screenImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, FNScreenW, FNScreenH)];
    screenImgV.image = [self drawScreen];
    [self.parentViewController.view addSubview:screenImgV];
    avVC.screenImgV = screenImgV;
    self.navigationController.navigationBarHidden = YES;
    
    // 创建详情控制器
    FNAVDetailController *avDetailVC = [[FNAVDetailController alloc] init];
    avDetailVC.item = item;
    avDetailVC.view.frame = CGRectMake(FNScreenW, 0, FNScreenW, FNScreenH);
    self.avDetailVc = avDetailVC;
    [avVC addChildViewController:avDetailVC];
    [avVC.view addSubview:avDetailVC.view];
    
    __weak FNAVDetailController *weakAVController = avDetailVC;
    avDetailVC.backBlock = ^{
        [UIView animateWithDuration:0.2 animations:^{
            weakAVController.view.frame = CGRectMake(FNScreenW, 0, FNScreenW, FNScreenH);
        } completion:^(BOOL finished) {
            [weakAVController.view removeFromSuperview];
            [weakAVController removeFromParentViewController];
            avVC.navigationController.navigationBarHidden = NO;
            [avVC.screenImgV removeFromSuperview];
        }];
    };
    
    [UIView animateWithDuration:0.2 animations:^{
        avDetailVC.view.frame = CGRectMake(0, 0, FNScreenW, FNScreenH);
    }];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    NSLog(@"%@",change);
}











@end