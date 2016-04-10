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
#import <MediaPlayer/MediaPlayer.h>
#import "FNNewsReplyController.h"

@interface FNAVListController ()

@property (nonatomic, strong) NSArray<FNAVListItem *> *listItemArray;

@end

@implementation FNAVListController
static NSString * const ID = @"cell";
- (NSArray *)listItemArray
{
    if (!_listItemArray){
        self.listItemArray = [[NSArray alloc] init];
    }
    return _listItemArray;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [FNAVGetAVNewsList getAVNewsListWithTid:self.tid :^(NSArray *array) {
        self.listItemArray = array;
        [self.tableView reloadData];
    }];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FNAVListCell" bundle:nil] forCellReuseIdentifier:ID];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.listItemArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    FNAVListCell *cell = [tableView dequeueReusableCellWithIdentifier:ID forIndexPath:indexPath];
    cell.listItem = self.listItemArray[indexPath.section];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.movieBlock = ^(NSString *urlStr){
        [self playMovieWithUrlStr:urlStr];
    };
    cell.replyBlock = ^(NSString *boardid,NSString *replyid){
        [self replyClickWith:boardid :replyid];
    };
    return cell;
}
// 设置footer高度
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10;
}
// 设置footer样式
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footV = [[UIView alloc] init];
    footV.backgroundColor = FNColor(215, 215, 215);
    footV.bounds = CGRectMake(0, 0, FNScreenW, 10);
    return footV;
}

// 设置行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = self.listItemArray[indexPath.section].title;
    
    return [FNAVListCell totalHeightWithTitle:title];
}


- (void)playMovieWithUrlStr:(NSString *)urlStr
{
    
    NSURL *movieUrl = [NSURL URLWithString:urlStr];
    
    MPMoviePlayerViewController *playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:movieUrl];
    
    [self presentViewController:playerVC animated:YES completion:nil];
}

#pragma mark -  跳转评论界面
- (void)replyClickWith:(NSString *)boardid :(NSString *)replyid
{
    // 1.跳转
    FNNewsReplyController *replyVC = [[FNNewsReplyController alloc] init];
    replyVC.docid = replyid;
    replyVC.boardid = boardid;
    [self.navigationController pushViewController:replyVC animated:YES];
}

@end