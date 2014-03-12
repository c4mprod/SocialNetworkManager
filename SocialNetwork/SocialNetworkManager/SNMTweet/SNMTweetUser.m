//
//  SNMTweetUser.m
//  twitterTest
//
//  Created by Emeric Janowski on 3/29/13.
//  Copyright (c) 2013 Emeric Janowski. All rights reserved.
//

#import "SNMTweetUser.h"


@implementation SNMTweetUser

-(void)dealloc
{
    [_mCreatedDate  release];
    [_mDescription  release];
    [_mId           release];
    [_mName         release];
    [_mImageLink    release];
    [_mScreenName   release];
    
    [super dealloc];
}

+ (SNMTweetUser*) createTweetUserWithDictionary:(NSDictionary*)_UserTweet
{
    SNMTweetUser *user = [[[SNMTweetUser alloc] init] autorelease];
    
    if ([_UserTweet isKindOfClass:[NSDictionary class]])
    {
        if ([_UserTweet[@"created_at"] isKindOfClass:[NSString class]])
        {
            NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss z yyyy"];
            user.mCreatedDate = [dateFormat dateFromString:_UserTweet[@"created_at"]];
        }
        
        if ([_UserTweet[@"description"] isKindOfClass:[NSString class]])
        {
            user.mDescription = _UserTweet[@"description"];
        }
        
        if ([_UserTweet[@"favourites_count"] isKindOfClass:[NSNumber class]])
        {
            user.mFavoriteCount = [_UserTweet[@"favourites_count"] intValue];
        }
        
        if ([_UserTweet[@"followers_count"] isKindOfClass:[NSNumber class]])
        {
            user.mFollowersCount = [_UserTweet[@"followers_count"] intValue];
        }
        
        if ([_UserTweet[@"friends_count"] isKindOfClass:[NSNumber class]])
        {
            user.mFriendsCount = [_UserTweet[@"friends_count"] intValue];
        }
        
        if ([_UserTweet[@"id_str"] isKindOfClass:[NSString class]])
        {
            user.mId = _UserTweet[@"id_str"];
        }
        
        if ([_UserTweet[@"name"] isKindOfClass:[NSString class]])
        {
            user.mName = _UserTweet[@"name"];
        }
        
        if ([_UserTweet[@"profile_image_url"] isKindOfClass:[NSString class]])
        {
            user.mImageLink = _UserTweet[@"profile_image_url"];
        }
        
        if ([_UserTweet[@"screen_name"] isKindOfClass:[NSString class]])
        {
            user.mScreenName = _UserTweet[@"screen_name"];
        }
    }
    return user;
}

@end
