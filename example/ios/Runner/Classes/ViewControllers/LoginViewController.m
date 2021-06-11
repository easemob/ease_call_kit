//
//  LoginViewController.m
//  EaseCallDemo
//
//  Created by 杜洁鹏 on 2021/2/19.
//

#import "LoginViewController.h"
#import <HyphenateChat/HyphenateChat.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <WHToast/WHToast.h>

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *pwdField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)registerAction:(id)sender {
    [self.view endEditing:YES];
    MBProgressHUD *hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [EMClient.sharedClient registerWithUsername:self.usernameField.text
                                       password:self.pwdField.text
                                     completion:^(NSString *aUsername, EMError *aError) {
        [hub hideAnimated:YES];
        if (aError) {
            [WHToast showErrorWithMessage:aError.errorDescription duration:1.0 finishHandler:nil];
        }else {
            [WHToast showSuccessWithMessage:@"注册成功" duration:1.0 finishHandler:nil];
        }
    }];
}

- (IBAction)loginAction:(id)sender {
    [self.view endEditing:YES];
    MBProgressHUD *hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [EMClient.sharedClient loginWithUsername:self.usernameField.text
                                       password:self.pwdField.text
                                     completion:^(NSString *aUsername, EMError *aError) {
        [hub hideAnimated:NO];
        if (!aError) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"IsLoggedIn" object:@(YES)];
        }else {
            [WHToast showErrorWithMessage:aError.errorDescription duration:1.0 finishHandler:nil];
        }
    }];
}

- (IBAction)tapBackgroundAction:(id)sender {
    [self.view endEditing:YES];
}


@end
