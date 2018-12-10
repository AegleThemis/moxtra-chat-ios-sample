//
//  ViewController.m
//  MoxieChat
//
//  Created by Moxtra on 2017/6/26.
//  Copyright © 2017年 Moxtra. All rights reserved.
//

#import "ViewController.h"
#import <ChatSDK/MXChatSDK.h>


/*SDK configuration */
#define MOXTRASDK_BASE_DOMAIN @"www.grouphour.com"
#define MOXTRASDK_CLIENT_ID @"ODMyNGYyMzI"
#define MOXTRASDK_CLIENT_SECRET @"OWI5OGMzMjM"

#define MOXTRASDK_UNIQUE_ID  @"mc_jacob"
#define MOXTRASDK_ORG_ID  @"PP2iXx2qi4f46aic2WD01Y7"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, MXChatClientDelegate, MXChatListModelDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) MXChatListModel *chatListModel;
@property (nonatomic, strong) MXMeetListModel *meetListModel;

@property (nonatomic, strong) NSMutableArray<MXChat *> *chatList;
@property (nonatomic, strong) MXChat *lastOpenedChatItem;

@end

static NSString *const kCellReustIdentifier = @"kCellReustIdentifier";

@implementation ViewController

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [MXChatClient sharedInstance].delegate = self;
    [self login];
    
    [self setupNavigationItem];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableArray<MXChat *> *)chatList
{
    if (_chatList == nil)
    {
        _chatList = [[NSMutableArray alloc] init];
    }
    return _chatList;
}

- (MXChatListModel *)chatListModel
{
    if (_chatListModel == nil)
    {
        _chatListModel = [[MXChatListModel alloc] init];
        _chatListModel.delegate = self;
    }
    return _chatListModel;
}

- (MXMeetListModel *)meetListModel
{
    if (_meetListModel == nil)
    {
        _meetListModel = [[MXMeetListModel alloc] init];
    }
    return _meetListModel;
}

#pragma mark - UserInterface

- (void)setupNavigationItem
{
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithTitle:@"APIs" style:UIBarButtonItemStylePlain target:self action:@selector(apiButtonOnClicked:)],
                                              nil];
}

#pragma mark - UITableViewDataSource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chatList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReustIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellReustIdentifier];
    }
    
    MXChat *chatItem = [self.chatList objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",chatItem.topic];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MXChat *chatItem = [self.chatList objectAtIndex:indexPath.row];
    MXChatViewController *chatViewController = [[MXChatViewController alloc] initWithChat:chatItem];
    chatViewController.edgesForExtendedLayout = UIRectEdgeNone;
    self.lastOpenedChatItem = chatItem;
    [self.navigationController pushViewController:chatViewController animated:YES];
}

#pragma mark - WidgetsAction

- (void)apiButtonOnClicked:(UINavigationItem *)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf login];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Unlink Account" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf unLink];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Fetch Chat List" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf fetchChatList];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"New Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf startNewChat];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Start Meet" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf startMeet];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Join Meet" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf joinMeet];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete Last Open Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf deleteLastOpenChat];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    alert.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - SDKActions

- (void)login
{
    __weak typeof(self) weakSelf = self;
    [[MXChatClient sharedInstance] setupDomain:MOXTRASDK_BASE_DOMAIN httpsDomain:nil wssDomain:nil linkConfig:nil];
    [[MXChatClient sharedInstance] linkWithUniqueId:MOXTRASDK_UNIQUE_ID orgId:MOXTRASDK_ORG_ID clientId:MOXTRASDK_CLIENT_ID clientSecret:MOXTRASDK_CLIENT_SECRET completionHandler:^(NSError * _Nullable error) {
            [weakSelf alertWithMessage:@"Login success"];
            [weakSelf fetchChatList];
    }];
}

- (void)unLink
{
    [[MXChatClient sharedInstance] unlink];
    [self.chatList removeAllObjects];
    [self.tableView reloadData];
}

- (void)fetchChatList
{
    if ([self checkLogin])
    {
        self.chatList = [self.chatListModel.chats mutableCopy];
        [self.tableView reloadData];
    }
}

- (void)startNewChat
{
    if ([self checkLogin])
    {
        __block UITextField *alertTextFiled;
        __weak typeof(self) weakSelf = self;
        UIAlertController *addChatAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Chat's Topic", @"Chat's Topic") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [addChatAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            alertTextFiled = textField;
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Done", @"Done") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.chatListModel createChatWithTopic:alertTextFiled.text completionHandler:^(NSError * _Nullable error, MXChat * _Nullable chatItem) {
                if (error)
                {
                    [weakSelf alertWithError:error];
                }
                else
                {
                    MXChatViewController *chatViewController = [[MXChatViewController alloc] initWithChat:chatItem];
                    
                    chatViewController.edgesForExtendedLayout = UIRectEdgeNone;
                    weakSelf.lastOpenedChatItem = chatItem;
                    [weakSelf.navigationController pushViewController:chatViewController animated:YES];
                }
            }];
        }];
        [addChatAlert addAction:cancelAction];
        [addChatAlert addAction:confirmAction];
        [self presentViewController:addChatAlert animated:YES completion:nil];
    }
}

- (void)startMeet
{
    if ([self checkLogin])
    {
        [self.meetListModel startMeetWithTopic:@"Meet" completionHandler:^(NSError * _Nullable error, MXMeetSession * _Nullable meetSession) {
            [meetSession presentMeetWindow];
        }];
    }
}

- (void)joinMeet
{
    if ([self checkLogin])
    {
        __weak typeof(self) weakSelf = self;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Input Meet ID" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"meet's id";
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSArray * textfields = alert.textFields;
            UITextField * idfield = textfields[0];
            [self.meetListModel joinMeetWithMeetId:idfield.text completionHandler:^(NSError * _Nullable error, MXMeetSession * _Nullable meetSession) {
                if (error)
                {
                    [weakSelf alertWithError:error];
                }
                else
                {
                    [meetSession presentMeetWindow];
                }
            }];
            
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)deleteLastOpenChat
{
    if ([self checkLogin])
    {
        if (self.lastOpenedChatItem != nil)
        {
            __weak typeof(self) weakSelf = self;
            [self.chatListModel deleteOrLeaveChat:self.lastOpenedChatItem withCompletionHandler:^(NSError * _Nullable error) {
                if (error)
                {
                    [weakSelf alertWithError:error];
                }
                else
                {
                    weakSelf.lastOpenedChatItem = nil;
                }
            }];
        }
        else
        {
            [self alertWithMessage:@"Could not found last open chat"];
        }
    }
}

#pragma mark - Helper

- (void)alertWithError:(NSError *)error
{
    NSString *title = @"Error";
    NSString *message = [NSString stringWithFormat:@"domain:%@, code:%@\n%@", error.domain, @(error.code), error.localizedDescription];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)alertWithMessage:(NSString *)message
{
    NSString *title = @"Tip";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)checkLogin
{
    if ([MXChatClient sharedInstance].currentUser != nil)
    {
        return YES;
    }
    else
    {
        [self alertWithMessage:@"Please login first"];
        return NO;
    }
}

#pragma mark - MXChatClientDelegate

- (void)chatClientDidUnlink:(MXChatClient *)chatClient
{
    self.chatListModel = nil;
    self.meetListModel = nil;
    [self alertWithMessage:@"Unlink success"];
}

#pragma mark - MXChatListModel

- (void)chatListModel:(MXChatListModel *)chatListModel didCreateChats:(NSArray<MXChat *> *)createdChats
{
    if (createdChats)
    {
        [self.chatList insertObjects:createdChats atIndexes:[NSIndexSet indexSetWithIndex:0]];
        [self.tableView reloadData];
    }
}

- (void)chatListModel:(MXChatListModel *)chatListModel didUpdateChats:(NSArray<MXChat *> *)updatedChats
{
    [self.tableView reloadData];
}

- (void)chatListModel:(MXChatListModel *)chatListModel didDeleteChats:(NSArray<MXChat *> *)deletedChats
{
    if (deletedChats)
    {
        [self.chatList removeObjectsInArray:deletedChats];
        [self.tableView reloadData];
    }
}

@end
