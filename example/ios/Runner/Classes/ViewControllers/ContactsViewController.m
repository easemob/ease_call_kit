//
//  ContactsViewController.m
//  EaseCallDemo
//
//  Created by 杜洁鹏 on 2021/2/19.
//

#import "ContactsViewController.h"
#import <HyphenateChat/HyphenateChat.h>
#import <EaseCallKit/EaseCallUIKit.h>
#import <Masonry/Masonry.h>
#import <WHToast/WHToast.h>

@interface ContactsViewController ()<UITableViewDelegate, UITableViewDataSource, EMContactManagerDelegate>{
    UIRefreshControl *_refreshControl;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@end

@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self addEaseContactDelegate];
    [self autoLoading];
}

- (void)addEaseContactDelegate {
    // 添加环信通讯录监听，以便收到好友申请。
    [EMClient.sharedClient.contactManager addDelegate:self delegateQueue:nil];
}

- (void)handleRefresh{
    [EMClient.sharedClient.contactManager getContactsFromServerWithCompletion:^(NSArray *aList, EMError *aError) {
        if (!aError) {
            self.contacts = aList;
            [self->_refreshControl endRefreshing];
            [self.tableView reloadData];
        }
    }];
}

- (void)autoLoading {
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y - self.tableView.refreshControl.frame.size.height) animated:NO];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
}

- (IBAction)addContactAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"添加好友"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"对方环信Id";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField *envirnmentNameTextField = alertController.textFields.firstObject;
        // 发送好友申请
        [EMClient.sharedClient.contactManager addContact:envirnmentNameTextField.text
                                                 message:@""
                                              completion:^(NSString *aUsername, EMError *aError)
         {
            if (aError) {
                [WHToast showErrorWithMessage:aError.errorDescription duration:1.0 finishHandler:nil];
            }else {
                [WHToast showSuccessWithMessage:@"发送成功" duration:1.0 finishHandler:nil];
            }
        }];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:true completion:nil];
}

- (IBAction)singleCallAction:(id)sender {
    
    NSArray<NSIndexPath *> *indexPaths = [self.tableView indexPathsForSelectedRows];
    if (indexPaths.count != 1) {
        [WHToast showErrorWithMessage:@"请确认人数" duration:1.0 finishHandler:nil];
        return;
    }
    
    NSString *remoteUser = self.contacts[indexPaths.firstObject.row];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSUInteger type = [ud integerForKey:@"EaseCallKit_SingleCallType"];
    [[EaseCallManager sharedManager] startSingleCallWithUId:remoteUser
                                                       type:type == 0 ? EaseCallType1v1Audio : EaseCallType1v1Video
                                                        ext:nil
                                                 completion:^(NSString * callId, EaseCallError * aError)
     {
        if(aError) {
            [WHToast showErrorWithMessage:@"呼叫失败" duration:1.0 finishHandler:nil];
        }
    }];
}

- (IBAction)multipleCallAction:(id)sender {
    NSArray<NSIndexPath *> *indexPaths = [self.tableView indexPathsForSelectedRows];
    if (indexPaths.count == 0) {
        [WHToast showErrorWithMessage:@"请确认人数" duration:1.0 finishHandler:nil];
        return;
    }
    
    NSMutableArray *inviteUsers = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths) {
        NSString *user = self.contacts[ indexPath.row];
        [inviteUsers addObject:user];
    }
    
    [[EaseCallManager sharedManager] startInviteUsers:inviteUsers
                                                  ext:nil
                                           completion:^(NSString * _Nonnull callId, EaseCallError * aError)
    {
        if(aError) {
            [WHToast showErrorWithMessage:@"呼叫失败" duration:1.0 finishHandler:nil];
        }
    }];
}

#pragma mark - getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        _tableView.editing = YES;
        _tableView.refreshControl = [self refreshControl];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        _tableView.rowHeight = 50;
    }
    return _tableView;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        _refreshControl.tintColor = [UIColor grayColor];
        _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"loading..."];
        [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

#pragma mark - tableViewDataSource & tableDelegate
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *cellId = @"CELL";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = self.contacts[indexPath.row];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contacts.count;
}

#pragma mark - EMContactManagerDelegate

- (void)friendshipDidAddByUser:(NSString *)aUsername {
    [WHToast showMessage:[NSString stringWithFormat:@"添加%@为好友", aUsername]
                duration:1.5
           finishHandler:^{
        [self autoLoading];
    }];
}

@end
