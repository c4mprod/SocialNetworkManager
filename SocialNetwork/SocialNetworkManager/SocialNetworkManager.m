//
//  SocialNetworkManager.m
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import "SocialNetworkManager.h"
#import "SocialNetworkManagerDelegate.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>


@implementation SocialNetworkManager


@synthesize mDelegate;

static SocialNetworkManager *sharedInstance = nil;

//@synthesize mFacebookSession;



#pragma mark -
#pragma mark Object Life Cycle Methods



+ (SocialNetworkManager*)sharedSocialNetworkManager
{
	if (sharedInstance == nil)
	{
		sharedInstance = [[SocialNetworkManager alloc] init];
	}
	
	return sharedInstance;
}


+ (void)releaseSharedSocialNetworkManager
{
	if (sharedInstance != nil)
	{
		[sharedInstance release];
		sharedInstance = nil;
	}
}


- (void)dealloc
{
    [mDelegate release];
    [super dealloc];
}



#pragma mark -
#pragma mark Data Management Methods



- (BOOL)checkForOSIntegratedFacebookError:(NSError*)_Error
                              forDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
                               withStatus:(FBSessionState)_Status
{
    BOOL lErrorDetected = FALSE;
    
    if ([SLComposeViewController class] != nil &&
        FBSession.activeSession.accessTokenData.loginType == FBSessionLoginTypeSystemAccount &&
        ![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        lErrorDetected = TRUE;
    }
    
    if([[_Error.userInfo valueForKey:@"com.facebook.sdk:ErrorLoginFailedReason"] rangeOfString:@"com.facebook.sdk:SystemLoginDisallowedWithoutError"].location != NSNotFound)
    {
        lErrorDetected = TRUE;
    }
    
    if (lErrorDetected && [_Delegate respondsToSelector:@selector(facebookOSIntegratedDisabledWithStatus:andError:)])
    {
        [_Delegate facebookOSIntegratedDisabledWithStatus:_Status andError:_Error];
        return TRUE;
    }
    
    return FALSE;
}



#pragma mark -
#pragma mark Facebook Methods



- (void)closeSessionAndClearToken
{
    [FBSession.activeSession closeAndClearTokenInformation];
}


// Post Status Update button handler; will attempt different approaches depending upon configuration.
- (void)facebookPublishName:(NSString*)_Name
                       Link:(NSURL*)_Link
                    caption:(NSString*)_Caption
                description:(NSString*)_Description
                    picture:(NSURL*)_Picture
                   delegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    //Facebook setup on users device.
    BOOL haveIntegratedFacebookAtAll = ([SLComposeViewController class] != nil);
    
    if (FBSession.activeSession.accessTokenData.loginType == FBSessionLoginTypeFacebookApplication &&
         ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]])
    {
        [self closeSessionAndClearToken];
    }
    else if (FBSession.activeSession.accessTokenData.loginType == FBSessionLoginTypeSystemAccount &&
              !(haveIntegratedFacebookAtAll && [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]))
    {
        [self closeSessionAndClearToken];
    }
    

    if(FB_ISSESSIONOPENWITHSTATE(FBSession.activeSession.state))
    {
        [self postFeedWithDescription:_Description
                                 link:_Link
                              caption:_Caption
                             delegate:_Delegate];
    }
    else
    {
        // Lastly, fall back on a request for permissions and a direct post using the Graph API
        [self loginFacebookWithPermissions:[NSArray arrayWithObject:@"publish_actions"]
                               forDelegate:_Delegate
                         CompletionHandler:^
         {
             [self postFeedWithDescription:_Description
                                      link:_Link
                                   caption:_Caption
                                  delegate:_Delegate];
         }];
    }
}


- (void)facebookPresentFriendPickerForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    //Facebook setup on users device.
    BOOL haveIntegratedFacebookAtAll = ([SLComposeViewController class] != nil);
    
    if (FBSession.activeSession.accessTokenData.loginType == FBSessionLoginTypeFacebookApplication &&
        ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]])
    {
        [self closeSessionAndClearToken];
    }
    else if (FBSession.activeSession.accessTokenData.loginType == FBSessionLoginTypeSystemAccount &&
             !(haveIntegratedFacebookAtAll && [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]))
    {
        [self closeSessionAndClearToken];
    }
    
    
    if(FB_ISSESSIONOPENWITHSTATE(FBSession.activeSession.state))
    {
        [self presentFriendPickerForDelegate:_Delegate];
    }
    else
    {
        // Lastly, fall back on a request for permissions and a direct post using the Graph API
        [self loginFacebookWithPermissions:[NSArray arrayWithObject:@"publish_actions"]
                               forDelegate:_Delegate
                         CompletionHandler:^
         {
             [self presentFriendPickerForDelegate:_Delegate];
         }];
    }
}


- (FBAppCall*)shareWithFacebookAppWithName:(NSString*)_Name
                                      Link:(NSURL*)_Link
                                   caption:(NSString*)_Caption
                               description:(NSString*)_Description
                                   picture:(NSURL*)_Picture
                                   handler:(FBDialogAppCallCompletionHandler)_Handler
{
    return [FBDialogs presentShareDialogWithLink:_Link
                                            name:_Name
                                         caption:_Caption
                                     description:_Description
                                         picture:_Picture
                                     clientState:nil
                                         handler:_Handler];
}


- (BOOL)presentOSIntegratedShareDialogModallyonViewController:(UIViewController*)_ViewController
                                                      session:(FBSession*)_Session
                                                  initialText:(NSString*)_InitialText
                                                       images:(NSArray*)_Images
                                                         urls:(NSArray*)_Urls
                                                      handler:(FBOSIntegratedShareDialogHandler)_Handler
{
    return [FBDialogs presentOSIntegratedShareDialogModallyFrom:_ViewController
                                                        session:_Session
                                                    initialText:_InitialText
                                                         images:_Images
                                                           urls:_Urls
                                                        handler:_Handler];
}


- (void)loginFacebookWithPermissions:(NSArray*)_Permissions
                         forDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
                   CompletionHandler:(void (^)(void))_Action
{
    NSMutableArray* lNotGrandedPermissions = [NSMutableArray array];
    
    for (NSString* aPermission in _Permissions)
    {
        if ([FBSession.activeSession.permissions indexOfObject:aPermission] == NSNotFound)
        {
            [lNotGrandedPermissions addObject:aPermission];
        }
    }
    
   [FBSession openActiveSessionWithPublishPermissions:lNotGrandedPermissions
                                       defaultAudience:FBSessionDefaultAudienceFriends
                                          allowLoginUI:TRUE
                                     completionHandler:^(FBSession *_Session, FBSessionState status, NSError *_Error)
    {
        if (!_Error)
        {                        
            if (FB_ISSESSIONOPENWITHSTATE(_Session.state))
            {
                _Action();
                
                [self notifyDelegateForFacebookSuccessLogin:_Delegate];
            }
            else if (FB_ISSESSIONSTATETERMINAL(_Session.state))
            {
                [self notifyDelegateForFacebookLoginCancelledDelegate:_Delegate];
            }
        }
        else
        {
            [self notifyDelegateForFacebookLoginFail:_Delegate ForError:_Error withStatus:_Session.state];
        }
    }];
}


- (void)postFeedWithDescription:(NSString*)_Description
                           link:(NSURL*)_Link
                        caption:(NSString*)_Caption
                       delegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate

{
    NSMutableDictionary* _Params = [NSMutableDictionary dictionary];
    [_Params setValue:_Description forKey:@"description"];
    [_Params setValue: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"] forKey:@"app_id"];
    [_Params setValue: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] forKey:@"name"];
    [_Params setObject:_Link.absoluteString forKey:@"link"];
    [_Params setObject:_Caption forKey:@"caption"];
    
    [FBRequestConnection startWithGraphPath:@"me/feed"
                                 parameters:_Params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection* _RequestConnection, id _Result, NSError* _Error)
     {
         if (!_Error)
         {
             [self notifyDelegateForFacebookShareSuccess:_Delegate];
         }
         else
         {
             [self notifyDelegateForFacebookShareFail:_Delegate ForError:_Error withStatus:FBSession.activeSession.state];
         }
     }];
}


- (void)presentFriendPickerForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    FBFriendPickerViewController *friendPickerController = [[FBFriendPickerViewController alloc] init];
    friendPickerController.title = @"Pick Friends";
    [friendPickerController loadData];
    
    [friendPickerController presentModallyFromViewController:[_Delegate viewControllerToPresentSocialNetwork] animated:YES handler:
     ^(FBViewController *sender, BOOL donePressed) {
         
         if (!donePressed) {
             [_Delegate facebookFriendPickerCancelled];
             return;
         }
         
         [_Delegate facebookFriendPickerDidFinishPicking:[NSMutableArray arrayWithArray:friendPickerController.selection]];
     }];
}



#pragma mark -
#pragma mark Mail Composer Delegate Methods



#pragma mark -
#pragma mark Mail Methods



- (void)launchMailWithSubject:(NSString *)_Subject
                         body:(NSString *)_Body
                       isHTML:(BOOL)_Html
                   addressees:(NSArray *)_AddresseesMail
                  andDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailComposeController = [[MFMailComposeViewController alloc] init];
        mailComposeController.mailComposeDelegate = self;
        self.mDelegate = _Delegate;
        
        
        mailComposeController.navigationBar.barStyle = [_Delegate viewControllerToPresentSocialNetwork].navigationController.navigationBar.barStyle;
        mailComposeController.navigationBar.tintColor = [_Delegate viewControllerToPresentSocialNetwork].navigationController.navigationBar.tintColor;
        mailComposeController.title = _Subject;
        
        if (_AddresseesMail && [_AddresseesMail count] != 0)
        {
            [mailComposeController setToRecipients:_AddresseesMail];
        }
        
        [mailComposeController setSubject:_Subject];
        
        [mailComposeController setMessageBody:_Body isHTML:_Html];
        
        [[_Delegate viewControllerToPresentSocialNetwork] presentViewController:mailComposeController animated:TRUE completion:nil];
        [mailComposeController release];
    }
	else
	{
		if ([_Delegate respondsToSelector:@selector(NoEmailConfigured)])
		{
			[_Delegate NoEmailConfigured];
		}
	}
}


- (void)mailComposeController:(MFMailComposeViewController*)_Controller
          didFinishWithResult:(MFMailComposeResult)_Result
                        error:(NSError*)_Error
{
	[_Controller dismissViewControllerAnimated:TRUE completion:nil];
    
    switch (_Result) {
        case MFMailComposeResultCancelled:            
            if ([mDelegate respondsToSelector:@selector(EmailCancelled)])
            {
                [mDelegate EmailCancelled];
            }
            break;
        case MFMailComposeResultSaved:
            if ([mDelegate respondsToSelector:@selector(EmailSaved)])
            {
                [mDelegate EmailSaved];
            }
            break;
        case MFMailComposeResultSent:
            if ([mDelegate respondsToSelector:@selector(EmailSent)])
            {
                [mDelegate EmailSent];
            }
            break;
        case MFMailComposeResultFailed:
            if ([mDelegate respondsToSelector:@selector(EmailFail)])
            {
                [mDelegate EmailFail];
            }
            break;            
        default:
            break;
    }
    
    self.mDelegate = nil;
}



#pragma mark -
#pragma mark Twitter Methods



- (void)postTwitterFeedsWithText:(NSString*)_Text
                           image:(UIImage*)_Image
                             url:(NSURL*)_URL
                     forDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") && IOS_VERSION_LESS_THAN(@"6.0"))
    {
        //if ([TWTweetComposeViewController canSendTweet])
        {
            TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
            [tweetSheet setInitialText:_Text];
            [tweetSheet addImage:_Image];
            [tweetSheet addURL:_URL];
            [tweetSheet setCompletionHandler:^(SLComposeViewControllerResult result)
             {
                 switch (result) {
                     case SLComposeViewControllerResultCancelled:
                         [self notifyDelegateForTwitterShareCancelledForDelegate:_Delegate];
                         [tweetSheet dismissModalViewControllerAnimated:TRUE];
                         break;
                     case SLComposeViewControllerResultDone:
                         [self notifyDelegateForTwitterShareSuccess:_Delegate];
                         break;
                         
                     default:
                         break;
                 }
             }];
            [[_Delegate viewControllerToPresentSocialNetwork] presentViewController:tweetSheet animated:TRUE completion:nil];
        }
    }
    else if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        //if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet setInitialText:_Text];
            [tweetSheet addImage:_Image];
            [tweetSheet addURL:_URL];
            [tweetSheet setCompletionHandler:^(SLComposeViewControllerResult result)
            {
                switch (result) {
                    case SLComposeViewControllerResultCancelled:
                        [self notifyDelegateForTwitterShareCancelledForDelegate:_Delegate];
                        [tweetSheet dismissModalViewControllerAnimated:TRUE];
                        break;
                    case SLComposeViewControllerResultDone:
                        [self notifyDelegateForTwitterShareSuccess:_Delegate];
                        break;
                        
                    default:
                        break;
                }
            }];
            [[_Delegate viewControllerToPresentSocialNetwork] presentViewController:tweetSheet animated:YES completion:nil];
        }
    }
}


- (void)loginTwitterForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate completionHandler:(void (^)(void))_Action
{
    ACAccountStore* lAccountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterType = [lAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [lAccountStore requestAccessToAccountsWithType:twitterType
                                           options:NULL
                                        completion:^(BOOL _Granded, NSError* _Error)
     {
         if (_Granded)
         {
             [self notifyDelegateForTwitterSuccessLogin:_Delegate];
        }
         else
         {
             [self notifyDelegateForTwitterLoginFail:_Delegate ForError:_Error];
         }
     }];
    
    [lAccountStore release];
}



#pragma mark -
#pragma mark Facebook Delegate Call Methods



- (void)notifyDelegateForFacebookSuccessLogin:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    [_Delegate facebookSessionDidSuccessfullyLogin];
}


- (void)notifyDelegateForFacebookLoginCancelledDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{    
    if ([_Delegate respondsToSelector:@selector(facebookSessionOpenDidCancel)])
    {
        [_Delegate facebookSessionOpenDidCancel];
    }
    
    [self closeSessionAndClearToken];
    
}


- (void)notifyDelegateForFacebookLoginFail:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
                                  ForError:(NSError*)_Error
                                withStatus:(FBSessionState)_Status
{
    if ([self checkForOSIntegratedFacebookError:_Error
                                    forDelegate:_Delegate
                                     withStatus:_Status])
    {
        [self closeSessionAndClearToken];
        return;
    }
    
    if ([_Delegate respondsToSelector:@selector(facebookSessionDidFailLoginWithStatus:andError:)])
    {
        [_Delegate facebookSessionDidFailLoginWithStatus:_Status andError:_Error];
    }
    
    [self closeSessionAndClearToken];
}


- (void)notifyDelegateForFacebookShareSuccess:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([_Delegate respondsToSelector:@selector(facebookDidSuccessfullyShare)])
    {
        [_Delegate facebookDidSuccessfullyShare];
    }
}


- (void)notifyDelegateForFacebookShareFail:(NSObject<SocialNetworkManagerDelegate>*)_Delegate ForError:(NSError*)_Error withStatus:(FBSessionState)_Status
{
    if ([self checkForOSIntegratedFacebookError:_Error
                                    forDelegate:_Delegate
                                     withStatus:_Status])
    {
        [self closeSessionAndClearToken];
        return;
    }
    
    if ([_Delegate respondsToSelector:@selector(facebookDidFailShareWithStatus:andError:)])
    {
        [_Delegate facebookDidFailShareWithStatus:_Status andError:_Error];
    }
    
    [self closeSessionAndClearToken];
}



#pragma mark -
#pragma mark Twitter Delegate Call Methods



- (void)notifyDelegateForTwitterSuccessLogin:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([_Delegate respondsToSelector:@selector(twitterSessionDidSuccessfullyLogin)])
    {
        [_Delegate twitterSessionDidSuccessfullyLogin];
    }
}


- (void)notifyDelegateForTwitterLoginFail:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
                                 ForError:(NSError*)_Error
{    
    if ([_Delegate respondsToSelector:@selector(twitterSessionDidFailLoginWithError:)])
    {
        [_Delegate twitterSessionDidFailLoginWithError:_Error];
    }
}


- (void)notifyDelegateForTwitterShareSuccess:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([_Delegate respondsToSelector:@selector(twitterDidSuccessfullyShare)])
    {
        [_Delegate twitterDidSuccessfullyShare];
    }
}


- (void)notifyDelegateForTwitterShareCancelledForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{   
    if ([_Delegate respondsToSelector:@selector(twitterDidCancelShare)])
    {
        [_Delegate twitterDidCancelShare];
    }
}

@end
