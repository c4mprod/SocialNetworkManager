//
//  LogoutViewController.m
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import "LogoutViewController.h"
#import "SocialNetworkManager.h"



@interface LogoutViewController ()

@end



@implementation LogoutViewController



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
    [super dealloc];
}



#pragma mark -
#pragma mark User Interaction Methods



- (IBAction)onLogoutButtonPressed:(id)sender
{
    [[SocialNetworkManager sharedSocialNetworkManager] closeSessionAndClearToken];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction)onFriendPickerButtonPressed:(id)sender
{
    [[SocialNetworkManager sharedSocialNetworkManager] facebookPresentFriendPickerForDelegate:self];
}

- (IBAction)onMailComposerButtonPressed:(id)sender
{
    [[SocialNetworkManager sharedSocialNetworkManager] launchMailWithSubject:@"sujet de la mort qui tue"
                                                                        body:@"Contenu du mail de la mort qui tue"
                                                                      isHTML:FALSE
                                                                  addressees:@[@"raph@c4m.com", @"bob@marley.com"]
                                                                 andDelegate:self];
}

- (IBAction)onTwitterShareButtonPressed:(id)sender
{
    [[SocialNetworkManager sharedSocialNetworkManager] postTwitterFeedsWithText:@"mon super tweet!!"
                                                                          image:[UIImage imageNamed:@"index.jpg"]
                                                                            url:[NSURL URLWithString:@"http://c4mprod.com"]
                                                                    forDelegate:self];
}



#pragma mark -
#pragma mark Social NetworkManager Delegate



- (UIViewController*)viewControllerToPresentSocialNetwork
{
    return self;
}


- (void)facebookFriendPickerDidFinishPicking:(NSMutableArray*)_Selection
{
    NSString *message;
    
    if (_Selection.count == 0) {
        message = @"<No Friends Selected>";
    } else {
        
        NSString *text = @"";
        
        // we pick up the users from the selection, and create a string that we use to update the text view
        // at the bottom of the display; note that self.selection is a property inherited from our base class
        for (id<FBGraphUser> user in _Selection) {
            if ([text length]) {
                text = [text stringByAppendingString:@", "];
            }
            text = [text stringByAppendingString:user.name];
        }
        message = text;
    }
    
    UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:@"You Picked:"
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [lAlertView show];
    [lAlertView release];
}


- (void)facebookFriendPickerCancelled
{
    UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:@"Cancelled"
                                                         message:@"You cancelled friend picker"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [lAlertView show];
    [lAlertView release];
}


- (void)twitterSessionDidSuccessfullyLogin
{
    UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:@"Connected"
                                                         message:@"You successfully connected with Twitter"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [lAlertView show];
    [lAlertView release];
}


- (void)twitterSessionDidFailLoginWithError:(NSError*)_Error
{
    UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Connection to Twitter failed"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [lAlertView show];
    [lAlertView release];
}

- (void)twitterDidSuccessfullyShare
{
    UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:@"Twitter"
                                                         message:@"Tweet sended"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [lAlertView show];
    [lAlertView release];
}


- (void)twitterDidCancelShare
{
    UIAlertView* lAlertView = [[UIAlertView alloc] initWithTitle:@"Twitter"
                                                         message:@"Tweet cancelled"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [lAlertView show];
    [lAlertView release];
}


@end
