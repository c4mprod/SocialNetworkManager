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
//#import "AFHTTPClient.h"
#import "AFNetworking.h"
#import "SNMTweet.h"
#import "JSONKit.h"




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
#warning Value stored to 'lErrorDetected' is never read
    BOOL lErrorDetected = FALSE;
    
    if ([SLComposeViewController class] != nil &&
        FBSession.activeSession.accessTokenData.loginType == FBSessionLoginTypeSystemAccount &&
        ![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        lErrorDetected = TRUE;
    }
    
    BOOL isSystemDisallowedError = FALSE;
    if([_Error.userInfo valueForKey:@"com.facebook.sdk:ErrorLoginFailedReason"] && [[_Error.userInfo valueForKey:@"com.facebook.sdk:ErrorLoginFailedReason"] rangeOfString:@"com.facebook.sdk:SystemLoginDisallowedWithoutError"].location != NSNotFound)
    {
        isSystemDisallowedError = TRUE;
    }
    
    if (isSystemDisallowedError && [_Delegate respondsToSelector:@selector(facebookOSIntegratedDisabledWithStatus:andError:)])
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
- (void)facebookPublishLink:(NSURL*)_Link
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
                              picture:_Picture
                             delegate:_Delegate];
    }
    else
    {
        // Lastly, fall back on a request for permissions and a direct post using the Graph API
        [self loginFacebookWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                      forDelegate:_Delegate
                                CompletionHandler:^
         {
             [self postFeedWithDescription:_Description
                                      link:_Link
                                   caption:_Caption
                                   picture:_Picture
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
        [self loginFacebookWithReadPermissions:nil
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


- (void)loginFacebookWithReadPermissions:(NSArray*)_Permissions
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
    
    [FBSession openActiveSessionWithReadPermissions:lNotGrandedPermissions
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


- (void)loginFacebookWithPublishPermissions:(NSArray*)_Permissions
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


/*- (void)postFeedWithDescription:(NSString*)_Description
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
}*/


- (void)postFeedWithDescription:(NSString*)_Description
                           link:(NSURL*)_Link
                        caption:(NSString*)_Caption
                        picture:(NSURL*)_PictureURL
                       delegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{  
    
    // If it is available, we will first try to post using the share dialog in the Facebook app
    FBAppCall *appCall = [FBDialogs presentShareDialogWithLink:_Link
                                                          name:nil
                                                       caption:_Caption
                                                   description:_Description
                                                       picture:_PictureURL
                                                   clientState:nil
                                                       handler:^(FBAppCall *call, NSDictionary *results, NSError *_Error) {
                                                           if ([results valueForKey:@"completionGesture"] && [[results valueForKey:@"completionGesture"] isEqualToString:@"cancel"])
                                                           {
                                                               [self notifyDelegateForFacebookShareCancelled:_Delegate];
                                                           }
                                                           else if ([results valueForKey:@"completionGesture"] && [[results valueForKey:@"completionGesture"] isEqualToString:@"post"])
                                                           {
                                                               [self notifyDelegateForFacebookShareSuccess:_Delegate];
                                                           }
                                                           else
                                                           {
                                                               [self notifyDelegateForFacebookShareFail:_Delegate ForError:_Error withStatus:FBSession.activeSession.state];
                                                           }
                                                           
                                                       }];
    
    if (!appCall)
    {
        if ([FBDialogs canPresentOSIntegratedShareDialogWithSession:FBSession.activeSession])
        {
            // Next try to post using Facebook's iOS6 integration
            [FBDialogs presentOSIntegratedShareDialogModallyFrom:[_Delegate viewControllerToPresentSocialNetwork]
                                                     initialText:_Description
                                                           image:nil
                                                             url:_Link
                                                         handler:^(FBOSIntegratedShareDialogResult result, NSError *_Error)
             {
                 if (!_Error && FBOSIntegratedShareDialogResultSucceeded == result)
                 {
                     [self notifyDelegateForFacebookShareSuccess:_Delegate];
                 }
                 else if (!_Error && FBOSIntegratedShareDialogResultCancelled == result)
                 {
                     [self notifyDelegateForFacebookShareCancelled:_Delegate];
                 }
                 else
                 {
                     [self notifyDelegateForFacebookShareFail:_Delegate ForError:_Error withStatus:FBSession.activeSession.state];
                 }
             }];
        }
        else
        {
            // Lastly, fall back on a request for permissions and a direct post using the Graph API
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
    }
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



- (void)launchMailWithSubject:(NSString *)_Subject
                         body:(NSString *)_Body
                       isHTML:(BOOL)_Html
                   addressees:(NSArray *)_AddresseesMail
                  andDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([MFMailComposeViewController canSendMail])
    {
        // remove the custom nav bar font
       	NSMutableDictionary* navBarTitleAttributes = [[UINavigationBar appearance] titleTextAttributes].mutableCopy;
        UIFont* navBarTitleFont = navBarTitleAttributes[UITextAttributeFont];
        navBarTitleAttributes[UITextAttributeFont] = [UIFont systemFontOfSize:navBarTitleFont.pointSize];
        [[UINavigationBar appearance] setTitleTextAttributes:navBarTitleAttributes];
        [navBarTitleAttributes release];
        
        // set up and present the MFMailComposeViewController
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer setSubject:_Subject];
        [mailComposer setMessageBody:_Body isHTML:YES];
        if (_AddresseesMail && [_AddresseesMail count] != 0)
        {
            [mailComposer setToRecipients:_AddresseesMail];
        }
        
        mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[_Delegate viewControllerToPresentSocialNetwork] presentViewController:mailComposer animated:YES completion:^{}];
        [mailComposer release];
//        MFMailComposeViewController *mailComposeController = [[MFMailComposeViewController alloc] init];
//        mailComposeController.mailComposeDelegate = self;
//        self.mDelegate = _Delegate;
//        
//        
//        mailComposeController.navigationBar.barStyle = [_Delegate viewControllerToPresentSocialNetwork].navigationController.navigationBar.barStyle;
//        mailComposeController.navigationBar.tintColor = [_Delegate viewControllerToPresentSocialNetwork].navigationController.navigationBar.tintColor;
//        mailComposeController.title = _Subject;
//        
//        if (_AddresseesMail && [_AddresseesMail count] != 0)
//        {
//            [mailComposeController setToRecipients:_AddresseesMail];
//        }
//        
//        [mailComposeController setSubject:_Subject];
//        
//        [mailComposeController setMessageBody:_Body isHTML:_Html];
//        
//        [[_Delegate viewControllerToPresentSocialNetwork] presentModalViewController:mailComposeController animated:TRUE];
//        [mailComposeController release];
    }
	else
	{
		if ([_Delegate respondsToSelector:@selector(NoEmailConfigured)])
		{
			[_Delegate NoEmailConfigured];
		}
	}
}


- (void)launchSMSWithText:(NSString*)_Text
                recipient:(NSArray *)_Recipients
              andDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController* smsViewController = [[MFMessageComposeViewController alloc] init];
        smsViewController.messageComposeDelegate = self;
        [smsViewController setBody:_Text];
        [smsViewController setRecipients:_Recipients];
        self.mDelegate = _Delegate;
        
        
        smsViewController.navigationBar.barStyle = [_Delegate viewControllerToPresentSocialNetwork].navigationController.navigationBar.barStyle;
        smsViewController.navigationBar.tintColor = [_Delegate viewControllerToPresentSocialNetwork].navigationController.navigationBar.tintColor;
        
        
        [[_Delegate viewControllerToPresentSocialNetwork] presentModalViewController:smsViewController animated:TRUE];
    }
	else
	{
		if ([_Delegate respondsToSelector:@selector(NoSMSConfigured)])
		{
			[_Delegate NoSMSConfigured];
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


- (void)messageComposeViewController:(MFMessageComposeViewController *)_Controller didFinishWithResult:(MessageComposeResult)_Result
{
    [_Controller dismissViewControllerAnimated:TRUE completion:nil];
    
    switch (_Result) {
        case MessageComposeResultCancelled:
            if ([mDelegate respondsToSelector:@selector(SMSCancelled)])
            {
                [mDelegate SMSCancelled];
            }
            break;
        case MessageComposeResultSent:
            if ([mDelegate respondsToSelector:@selector(SMSSent)])
            {
                [mDelegate SMSSent];
            }
            break;
        case MessageComposeResultFailed:
            if ([mDelegate respondsToSelector:@selector(SMSFail)])
            {
                [mDelegate SMSFail];
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
            [[_Delegate viewControllerToPresentSocialNetwork] presentModalViewController:tweetSheet animated:TRUE];
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
                        break;
                    case SLComposeViewControllerResultDone:
                        [self notifyDelegateForTwitterShareSuccess:_Delegate];
                        break;
                        
                    default:
                        break;
                }
                [tweetSheet dismissModalViewControllerAnimated:TRUE];
            }];
            [[_Delegate viewControllerToPresentSocialNetwork] presentModalViewController:tweetSheet animated:TRUE];
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


- (BOOL) getTweetFromURL:(NSString*)_Tweet ForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    BOOL isURLCompatible = NO;
    
    //            NSString* tweeturl = [NSString stringWithFormat:@"https://api.twitter.com/1/statuses/show/%@.json",[array objectAtIndex:1]];
    NSArray* array = [_Tweet componentsSeparatedByString:@"https://twitter.com/"];
    if([array count] != 2)
    {
        array = [_Tweet componentsSeparatedByString:@"https://mobile.twitter.com/"];
    }
    
    if([array count] == 2)
    {
        NSString* string = [array objectAtIndex:1];
        array = [string componentsSeparatedByString:@"/status/"];
        if([array count] == 2)
        {
            NSString* tweeturl = [NSString stringWithFormat:@"https://api.twitter.com/1/statuses/show.json?id=%@&include_entities=true",[array objectAtIndex:1]];
            NSURLRequest * request= [NSURLRequest requestWithURL:[NSURL URLWithString:tweeturl]];
            AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
             {
                 NSString *filesContent					= [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                 id objectreponse						= [filesContent mutableObjectFromJSONString];
                 [filesContent release];
                 [_Delegate didGetTweet:[SNMTweet createTweetObjectWithDictionary:objectreponse]];
             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error)
             {
                 if ([_Delegate respondsToSelector:@selector(didFailGettingTweet:)])
                 {
                     [_Delegate didFailGettingTweet:error];
                 }
                }];
            AFHTTPClient* client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"c4mprod.com"]];
            [client enqueueHTTPRequestOperation:operation];
            isURLCompatible = YES;
        }
    }
    return isURLCompatible;
}

/**
 * check if an url is twitter compatible
 * @return YES if the url tweet is compatible, NO if it's a wrong URL
 */
- (BOOL) isTwitterURL:(NSString*)_TweetURL
{
    BOOL isURLCompatible = NO;
    NSArray* array = [_TweetURL componentsSeparatedByString:@"https://twitter.com/"];
    if([array count] != 2)
    {
        array = [_TweetURL componentsSeparatedByString:@"https://mobile.twitter.com/"];
    }
    
    if([array count] == 2)
    {
        NSString* string = [array objectAtIndex:1];
        array = [string componentsSeparatedByString:@"/status/"];
        if([array count] == 2)
        {
            isURLCompatible = YES;
        }
    }
    return isURLCompatible;
}



#pragma mark -
#pragma mark Google +



- (void)googlePlusShareLink:(NSURL*)_Link
                    caption:(NSString*)_Caption
                description:(NSString*)_Description
                    picture:(NSURL*)_Picture
                   delegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    C4MLog(@"");
    self.mDelegate = _Delegate;
    [GPPShare sharedInstance].delegate = self;
    id<GPPShareBuilder> shareBuilder = [[GPPShare sharedInstance] shareDialog];
    
    [shareBuilder setContentDeepLinkID:@"test"];
    [shareBuilder setURLToShare:_Link];
    [shareBuilder setTitle:_Caption
               description:_Description
              thumbnailURL:_Picture];
    
    [shareBuilder open];
}


- (void)finishedSharing:(BOOL)_Share
{
    if (_Share && [mDelegate respondsToSelector:@selector(googlePlusDidSuccessfullyShare)])
    {
        [mDelegate googlePlusDidSuccessfullyShare];
    }
    else if ([mDelegate respondsToSelector:@selector(googlePlusDidSuccessfullyShare)])
    {
        [mDelegate googlePlusDidCancelShare];        
    }
}



#pragma mark -
#pragma mark Facebook Delegate Call Methods



- (void)notifyDelegateForFacebookSuccessLogin:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
  if ([_Delegate respondsToSelector:@selector(facebookSessionDidSuccessfullyLogin)])
  {
    [_Delegate facebookSessionDidSuccessfullyLogin];
  }
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


- (void)notifyDelegateForFacebookShareCancelled:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
{
    if ([_Delegate respondsToSelector:@selector(facebookDidCancelShare)])
    {
        [_Delegate facebookDidCancelShare];
    }
}


- (void)notifyDelegateForFacebookShareFail:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
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
