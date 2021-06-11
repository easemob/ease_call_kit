//
//  SettingsViewController.m
//  EaseCallDemo
//
//  Created by 杜洁鹏 on 2021/2/19.
//

#import "SettingsViewController.h"
#import <HyphenateChat/HyphenateChat.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *btnTitle = [@"退出" stringByAppendingFormat:@"(%@)",EMClient.sharedClient.currentUsername];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [self.logoutBtn setTitle:btnTitle forState:UIControlStateNormal];
    self.segmentControl.selectedSegmentIndex = [ud integerForKey:@"EaseCallKit_SingleCallType"];
    
}

- (IBAction)segmentControlChanged:(UISegmentedControl *)sender {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:sender.selectedSegmentIndex forKey:@"EaseCallKit_SingleCallType"];
}

- (IBAction)logoutBtnAction:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [EMClient.sharedClient logout:YES completion:^(EMError *aError) {
        [hud hideAnimated:NO];
        [NSNotificationCenter.defaultCenter postNotificationName:@"IsLoggedIn" object:@NO];
    }];
}

@end
