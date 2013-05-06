//
//  LoginViewController.m
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import "LoginViewController.h"
#import "SocialNetworkManager.h"
#import "LogoutViewController.h"




@interface LoginViewController ()

@end

@implementation LoginViewController



#pragma mark -
#pragma mark View Controller Life Cycle



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc {
    [_mLoginButton release];
    [_mLoader release];
    [super dealloc];
}



#pragma mark -
#pragma mark User Interaction Methods



- (IBAction)onLoginButtonPressed:(id)sender
{
    _mLoader.hidden = FALSE;
    
    [[SocialNetworkManager sharedSocialNetworkManager] loginFacebookWithReadPermissions:nil
                                                                            forDelegate:self
                                                                      CompletionHandler:^
     {}];
}

- (IBAction)onLoginAndPostButtonPressed:(id)sender
{
    _mLoader.hidden = FALSE;
    
    [[SocialNetworkManager sharedSocialNetworkManager] facebookPublishLink:nil
                                                                   caption:@"Caption"
                                                               description:@"Description"
                                                                   picture:[NSURL URLWithString:@"https://lh3.googleusercontent.com/-cD3cctbz8bE/TjEVQizURWI/AAAAAAAAVxM/Hcxoa6qHASg/w947-h710/C4M+PROD"]
                                                                  delegate:self];
}

- (IBAction)onGooglePlusShareButtonPressed:(id)sender
{
    _mLoader.hidden = FALSE;
    
    [[SocialNetworkManager sharedSocialNetworkManager] googlePlusShareLink:[NSURL URLWithString:@"http://www.c4mprod.com"]
                                                                   caption:@"Caption"
                                                               description:@"Description"
                                                                   picture:[NSURL URLWithString:@"https://lh3.googleusercontent.com/-cD3cctbz8bE/TjEVQizURWI/AAAAAAAAVxM/Hcxoa6qHASg/w947-h710/C4M+PROD"]
                                                                  delegate:self];
}

- (IBAction)onSMSButtonPressed:(id)sender
{
    _mLoader.hidden = FALSE;
    
    [[SocialNetworkManager sharedSocialNetworkManager] launchSMSWithText:@"sms text"
                                                               recipient:[NSArray arrayWithObject:@"0650747164"]
                                                             andDelegate:self];
}



#pragma mark -
#pragma mark Social NetworkManager Delegate



- (UIViewController*)viewControllerToPresentSocialNetwork
{
    return self;
}


- (void)facebookSessionDidSuccessfullyLogin
{    
    _mLoader.hidden = TRUE;
    LogoutViewController* lLogoutViewController = [[LogoutViewController alloc] initWithNibName:@"LogoutViewController" bundle:nil];
    [self.navigationController pushViewController:lLogoutViewController animated:TRUE];
    [lLogoutViewController release];
}

- (void)facebookOSIntegratedDisabledWithStatus:(FBSessionState)_Status andError:(NSError*)_Error
{
    _mLoader.hidden = TRUE;
    NSLog(@"facebookOSIntegratedDisabledWithStatus %@", _Error);
    UIAlertView* lAlert = [[UIAlertView alloc] initWithTitle:@"erreur"
                                                     message:@"facebook natif désactivé"
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [lAlert show];
    [lAlert release];
}


- (void)facebookSessionDidFailLoginWithStatus:(FBSessionState)_Status andError:(NSError*)_Error
{
    NSLog(@"facebookSessionDidFailLoginWithStatus %@", _Error);
    _mLoader.hidden = TRUE;
    NSLog(@"_Error %@", _Error);
    UIAlertView* lAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"error %i",_Status] message:_Error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [lAlert show];
    [lAlert release];
}


- (void)facebookSessionDidSuccessfullyShared
{
    NSLog(@"facebookSessionDidSuccessfullyShared");
    _mLoader.hidden = TRUE;
    LogoutViewController* lLogoutViewController = [[LogoutViewController alloc] initWithNibName:@"LogoutViewController" bundle:nil];
    [self.navigationController pushViewController:lLogoutViewController animated:TRUE];
    [lLogoutViewController release];
}


- (void)facebookSessionDidFailShareWithStatus:(FBSessionState)_Status andError:(NSError*)_Error
{
    NSLog(@"facebookSessionDidFailShareWithStatus %@", _Error);
    _mLoader.hidden = TRUE;
    UIAlertView* lAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"error %i",_Status] message:_Error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [lAlert show];
    [lAlert release];
}


- (void)googlePlusDidSuccessfullyShare
{
    _mLoader.hidden = TRUE;
    UIAlertView* lAlert = [[UIAlertView alloc] initWithTitle:@"G+" message:@"Share succeded" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [lAlert show];
    [lAlert release];
}


- (void)googlePlusDidCancelShare
{
    _mLoader.hidden = TRUE;
    UIAlertView* lAlert = [[UIAlertView alloc] initWithTitle:@"G+" message:@"Share did cancel" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [lAlert show];
    [lAlert release];
}


@end
