//
//  SocialNetworkManager.h
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SocialNetworkManagerDelegate.h"
#import <MessageUI/MessageUI.h>
#import "GPPShare.h"

#ifndef IOS_VERSION_MACROS
#define IOS_VERSION_MACROS

#define IOS_VERSION_EQUAL_TO(v)                  ([[UIDevice currentDevice].systemVersion compare:v options:NSNumericSearch] == NSOrderedSame)
#define IOS_VERSION_GREATER_THAN(v)              ([[UIDevice currentDevice].systemVersion compare:v options:NSNumericSearch] == NSOrderedDescending)
#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[UIDevice currentDevice].systemVersion compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IOS_VERSION_LESS_THAN(v)                 ([[UIDevice currentDevice].systemVersion compare:v options:NSNumericSearch] == NSOrderedAscending)
#define IOS_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[UIDevice currentDevice].systemVersion compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif

@interface SocialNetworkManager : NSObject <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, GPPShareDelegate>


@property (nonatomic, retain) NSObject<SocialNetworkManagerDelegate>*  mDelegate;

+ (SocialNetworkManager*)sharedSocialNetworkManager;
+ (void)releaseSharedSocialNetworkManager;



//// FBSample logic
//// In this sample the app delegate maintains a property for the current
//// active session, and the view controllers reference the session via
//// this property, as well as play a role in keeping the session object
//// up to date; a more complicated application may choose to introduce
//// a simple singleton that owns the active FBSession object as well
//// as access to the object by the rest of the application
//@property (retain, nonatomic) FBSession *mFacebookSession;




#pragma mark -
#pragma mark Facebook



- (void)loginFacebookWithReadPermissions:(NSArray*)_Permissions
                             forDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
                       CompletionHandler:(void (^)(void))_Action;
- (void)loginFacebookWithPublishPermissions:(NSArray*)_Permissions
                                forDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate
                          CompletionHandler:(void (^)(void))_Action;
- (void)closeSessionAndClearToken;
- (void)facebookPublishLink:(NSURL*)_Link
                    caption:(NSString*)_Caption
                description:(NSString*)_Description
                    picture:(NSURL*)_Picture
                   delegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;
- (void)facebookPresentFriendPickerForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;



#pragma mark -
#pragma mark Mail



- (void)launchMailWithSubject:(NSString *)_Subject
                         body:(NSString *)_Body
                       isHTML:(BOOL)_Html
                   addressees:(NSArray *)_AddresseesMail
                  andDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;


- (void)launchSMSWithText:(NSString*)_Text
                recipient:(NSArray *)_AddresseesMail
              andDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;


#pragma mark -
#pragma mark Twitter



- (void)postTwitterFeedsWithText:(NSString*)_Text
                           image:(UIImage*)_Image
                             url:(NSURL*)_URL
                     forDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;



- (BOOL) getTweetFromURL:(NSString*)_Tweet ForDelegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;
- (BOOL) isTwitterURL:(NSString*)_TweetURL;



#pragma mark -
#pragma mark Google +



- (void)googlePlusShareLink:(NSURL*)_Link
                    caption:(NSString*)_Caption
                description:(NSString*)_Description
                    picture:(NSURL*)_Picture
                   delegate:(NSObject<SocialNetworkManagerDelegate>*)_Delegate;


@end
