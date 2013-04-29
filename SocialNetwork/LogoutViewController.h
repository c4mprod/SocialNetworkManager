//
//  LogoutViewController.h
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocialNetworkManagerDelegate.h"


@interface LogoutViewController : UIViewController <SocialNetworkManagerDelegate>
- (IBAction)onLogoutButtonPressed:(id)sender;
- (IBAction)onFriendPickerButtonPressed:(id)sender;
- (IBAction)onMailComposerButtonPressed:(id)sender;
- (IBAction)onTwitterShareButtonPressed:(id)sender;
@end
