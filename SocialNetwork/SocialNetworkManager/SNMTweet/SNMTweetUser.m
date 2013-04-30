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
    SNMTweetUser* user = [[SNMTweetUser alloc] init];
    
    if([_UserTweet isKindOfClass:[NSDictionary class]])
    {
        if([[_UserTweet objectForKey:@"created_at"] isKindOfClass:[NSString class]])
        {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss z yyyy"];
            user.mCreatedDate = [dateFormat dateFromString:[_UserTweet objectForKey:@"created_at"]];
            [dateFormat release];
        }
        
        if([[_UserTweet objectForKey:@"description"] isKindOfClass:[NSString class]])
        {
            user.mDescription = [_UserTweet objectForKey:@"description"];
        }
        
        if([[_UserTweet objectForKey:@"favourites_count"] isKindOfClass:[NSNumber class]])
        {
            user.mFavoriteCount = [[_UserTweet objectForKey:@"favourites_count"] intValue];
        }
        
        if([[_UserTweet objectForKey:@"followers_count"] isKindOfClass:[NSNumber class]])
        {
            user.mFollowersCount = [[_UserTweet objectForKey:@"followers_count"] intValue];
        }
        
        if([[_UserTweet objectForKey:@"friends_count"] isKindOfClass:[NSNumber class]])
        {
            user.mFriendsCount = [[_UserTweet objectForKey:@"friends_count"] intValue];
        }
        
        if([[_UserTweet objectForKey:@"id_str"] isKindOfClass:[NSString class]])
        {
            user.mId = [_UserTweet objectForKey:@"id_str"];
        }
        
        if([[_UserTweet objectForKey:@"name"] isKindOfClass:[NSString class]])
        {
            user.mName = [_UserTweet objectForKey:@"name"];
        }
        
        if([[_UserTweet objectForKey:@"profile_image_url"] isKindOfClass:[NSString class]])
        {
            user.mImageLink = [_UserTweet objectForKey:@"profile_image_url"];
        }
        
        if([[_UserTweet objectForKey:@"screen_name"] isKindOfClass:[NSString class]])
        {
            user.mScreenName = [_UserTweet objectForKey:@"screen_name"];
        }
    }
    return [user autorelease];
}

@end
