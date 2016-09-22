//
//  ZYHPageCollectionViewController.m
//  UCToutiaoClone
//
//  Created by zhiyi on 16/9/21.
//  Copyright © 2016年 lzy. All rights reserved.
//

#import "ZYHPageCollectionViewController.h"
#import "SingleImgNewsCollectionViewCell.h"
#import "ThreeImgNewsCollectionViewCell.h"
#import "SingleTitleNewsCollectionViewCell.h"
#import "SpecialNewsCollectionViewCell.h"
#import "objc/message.h"
#import "ZYHPageTableViewController.h"
#import "NewsService.h"
#import "ZYHArticleModel.h"
#import "UIColor+hexColor.h"
#import "UIScrollView+MJRefresh.h"
#import "MJRefreshHeader.h"
#import "UCTHomeSearchRefreshView.h"
#import "Masonry.h"

#define ARTICLE_MAP_SPECIALS @"specials"
#define ARTICLE_MAP_ARTICLES @"articles"

id (*objc_msgSendGetCellIdentifier_)(id self, SEL _cmd) = (void *)objc_msgSend;

@interface UICollectionViewCell ()
- (void)updateCellWithModel:(ZYHArticleModel *)model;
@end

@interface ZYHPageCollectionViewController () <UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) UIImageView *bgPlaceholderView;
@property (strong, nonatomic) NSArray *dataList;
@property (strong, nonatomic) NSArray *articlesIdList;
@property (strong, nonatomic) NSMutableDictionary *templateCellDict;
@property (assign, nonatomic) BOOL hadLoadData;
@property (assign, nonatomic) int page;
@end

@implementation ZYHPageCollectionViewController
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    layout = [[UICollectionViewFlowLayout alloc] init];
    [(UICollectionViewFlowLayout *)layout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [(UICollectionViewFlowLayout *)layout setMinimumLineSpacing:2];
    return [super initWithCollectionViewLayout:layout];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // self.clearsSelectionOnViewWillAppear = NO;
    [self.collectionView setBackgroundColor:[UIColor hexColor:@"f9f9f9"]];
    
    // Register cell classes
    [self.collectionView registerClass:[SingleImgNewsCollectionViewCell class] forCellWithReuseIdentifier:[SingleImgNewsCollectionViewCell cellReuseIdentifier]];
    [self.collectionView registerClass:[ThreeImgNewsCollectionViewCell class] forCellWithReuseIdentifier:[ThreeImgNewsCollectionViewCell cellReuseIdentifier]];
    [self.collectionView registerClass:[SingleTitleNewsCollectionViewCell class] forCellWithReuseIdentifier:[SingleTitleNewsCollectionViewCell cellReuseIdentifier]];
    [self.collectionView registerClass:[SpecialNewsCollectionViewCell class] forCellWithReuseIdentifier:[SpecialNewsCollectionViewCell cellReuseIdentifier]];
    
    
    // Do any additional setup after loading the view.
    [self setupCollectionView];
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    [self setupSearchRefreshView];
//}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupSearchRefreshView];
}

- (void)setupCollectionView {
//    [searchRefreshView mas_makeConstraints:^(MASConstraintMaker *make) {
////        make.bottom.equalTo(self.collectionView.wa)
//    }];
    
//    self.collectionView.delegate = self;
//    self.collectionView.dataSource = self;
}

- (void)setupSearchRefreshView {
    UCTHomeSearchRefreshView *searchRefreshView = [[UCTHomeSearchRefreshView alloc] init];
    CGFloat viewHeight = [searchRefreshView searchRefreshViewHeight];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
//    [searchRefreshView setFrame:CGRectMake(0, -50, screenWidth, 50)];
    
    [self.collectionView addSubview:searchRefreshView];
    [searchRefreshView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.collectionView).offset(-viewHeight);
        make.leading.equalTo(self.collectionView);
        make.width.equalTo(self.collectionView);
    }];
}

- (void)loadNewData {
    [self queryDataWithChannelId:_channelId];
}

- (void)loadMoreData {
    
}

- (void)freshData {
    NSLog(@"fresh Data");
}

- (void)setupMJ {
    self.collectionView.mj_header = [MJRefreshHeader headerWithRefreshingBlock:^{
        [self loadNewData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)analysisCellClassNameWithModel:(ZYHArticleModel *)model {
    return objc_getAssociatedObject(model, &kHomeTableViewCellClass);
}

- (void)attachCellClassName:(NSString *)className dataDict:(NSDictionary *)dataDict {
    objc_setAssociatedObject(dataDict, &kHomeTableViewCellClass, className, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)queryDataWithChannelId:(NSString *)channelId {
    __weak __typeof(&*self)weakSelf = self;
    [NewsService queryNewsWithChannelId:channelId completion:^(UCTNetworkResponseStatus status, NSDictionary *dataDict) {
        if (status == UCTNetworkResponseSucceed) {
            //数据先放model解析出来
            weakSelf.articlesIdList = [dataDict objectForKey:@"items"];
            NSDictionary *articlesDict = [dataDict objectForKey:@"articles"];
            NSDictionary *specialsDict = [dataDict objectForKey:@"specials"];
            [weakSelf packageArticlesDataWithArticlesIdList:weakSelf.articlesIdList articlesDict:articlesDict specialsDict:specialsDict];
            [weakSelf setHadLoadData:YES];
            [weakSelf.collectionView reloadData];
        } else {
            NSLog(@"");
        }
    }];
}

- (void)packageArticlesDataWithArticlesIdList:(NSArray *)articlesIdList
                                 articlesDict:(NSDictionary *)articlesDict
                                 specialsDict:(NSDictionary *)specialsDict {
    NSMutableArray *mutArray = [NSMutableArray array];
    for (NSDictionary *articlesIdDict in articlesIdList) {
        NSString *articleMapString = [articlesIdDict objectForKey:@"map"];
        NSString *articleId = [articlesIdDict objectForKey:@"id"];
        if ([ARTICLE_MAP_ARTICLES isEqualToString:articleMapString]) {
            ZYHArticleModel *model = [self packageArticleModelWithArticleDict:[articlesDict objectForKey:articleId]];
            [mutArray addObject:model];
        } else if ([ARTICLE_MAP_SPECIALS isEqualToString:articleMapString]) {
            NSDictionary *specialArticleDict = [specialsDict objectForKey:articleId];
            NSArray *specialArticleList =  [specialArticleDict objectForKey:@"articles"];
            ZYHArticleModel *specialModel = [self packageArticleModelWithArticleDict:specialArticleDict];
            [mutArray addObject:specialModel];
            for (NSDictionary *articleDict in specialArticleList) {
                [mutArray addObject:[self packageArticleModelWithArticleDict:articleDict]];
            }
        } else {
            continue;
        }
    }
    self.dataList = [mutArray copy];
}

- (ZYHArticleModel *)packageArticleModelWithArticleDict:(NSDictionary *)articleDict {
    ZYHArticleModel *model = [[ZYHArticleModel alloc] initWithDataDict:articleDict];
    return model;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZYHArticleModel *model = [_dataList objectAtIndex:indexPath.row];
    Class clazz = NSClassFromString([self analysisCellClassNameWithModel:model]);
    NSString *identifier = objc_msgSendGetCellIdentifier_(clazz, NSSelectorFromString(@"cellReuseIdentifier"));
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    if (nil == cell) {
        cell = [[clazz alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([cell respondsToSelector:@selector(updateCellWithModel:)]) {
        [cell updateCellWithModel:model];
    }
#pragma clang diagnostic pop
    return cell;
}

#pragma mark - Delegate DataSource

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    @autoreleasepool {
        ZYHArticleModel *model = [_dataList objectAtIndex:indexPath.row];
        Class clazz = NSClassFromString([self analysisCellClassNameWithModel:model]);
        NSString *identifier = objc_msgSendGetCellIdentifier_(clazz, NSSelectorFromString(@"cellReuseIdentifier"));
        UICollectionViewCell *cell = [self.templateCellDict objectForKey:identifier];
        if (nil == cell) {
            cell = [[clazz alloc] initWithFrame:CGRectZero];
            [self.templateCellDict setObject:cell forKey:identifier];
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([cell respondsToSelector:@selector(updateCellWithModel:)]) {
            [cell updateCellWithModel:model];
        }
#pragma clang diagnostic pop
        NSLayoutConstraint *calculateCellConstraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:[[UIScreen mainScreen] bounds].size.width];
        [cell.contentView addConstraint:calculateCellConstraint];
        CGSize cellSize = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        [cell.contentView removeConstraint:calculateCellConstraint];
        return cellSize;
    }
}

- (void)setChannelId:(NSString *)channelId {
    _channelId = channelId;
    if (!_hadLoadData) {//缓存
        [self loadNewData];
    }
    NSLog(@"load page");
}

@end