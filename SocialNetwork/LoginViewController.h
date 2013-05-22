//
//  LoginViewController.h
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocialNetworkManagerDelegate.h"


@interface LoginViewController : UIViewController <SocialNetworkManagerDelegate>



@property (retain, nonatomic) IBOutlet UIButton *mLoginButton;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *mLoader;



- (IBAction)onLoginButtonPressed:(id)sender;
- (IBAction)onLoginAndPostButtonPressed:(id)sender;
- (IBAction)onGooglePlusShareButtonPressed:(id)sender;
- (IBAction)onSMSButtonPressed:(id)sender;
@end
