//
//  SNMTweet.m
//  twitterTest
//
//  Created by Emeric Janowski on 3/29/13.
//  Copyright (c) 2013 Emeric Janowski. All rights reserved.
//

#import "SNMTweet.h"
#import "AFNetworking.h"


@implementation SNMTweet

- (void)dealloc
{
    [_mCreatedDate  release];
    [_mId           release];
    [_mText         release];
    [_mURLTweet     release];
    [_mUser         release];
    [_mArrayImages  release];
    [_mTwitterAppLink  release];
    
    
    [super dealloc];
}

+(SNMTweet*)createTweetObjectWithDictionary:(NSDictionary*)_TweetDictionary
{
    SNMTweet* tweet = [[SNMTweet alloc] init];
    if([_TweetDictionary isKindOfClass:[NSDictionary class]])
    {
        if([[_TweetDictionary objectForKey:@"created_at"] isKindOfClass:[NSString class]])
        {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss z yyyy"];
            tweet.mCreatedDate = [dateFormat dateFromString:[_TweetDictionary objectForKey:@"created_at"]];
            [dateFormat release];
        } else if([[_TweetDictionary objectForKey:@"created_at"] isKindOfClass:[NSDate class]])
        {
            tweet.mCreatedDate = [_TweetDictionary objectForKey:@"created_at"];
        }
        
        if([[_TweetDictionary objectForKey:@"favorite_count"] isKindOfClass:[NSNumber class]])
        {
            tweet.mFavoriteCount = [[_TweetDictionary objectForKey:@"favorite_count"] intValue];
        }
        
        if([[_TweetDictionary objectForKey:@"mFavorited"] isKindOfClass:[NSNumber class]])
        {
            tweet.mFavorited = [[_TweetDictionary objectForKey:@"mFavorited"] intValue];
        }
        
        if([[_TweetDictionary objectForKey:@"id_str"] isKindOfClass:[NSString class]])
        {
            tweet.mId = [_TweetDictionary objectForKey:@"id_str"];
        }
        
        if([[_TweetDictionary objectForKey:@"retweet_count"] isKindOfClass:[NSNumber class]])
        {
            tweet.mRetweetCount = [[_TweetDictionary objectForKey:@"retweet_count"] intValue];
        }
        
        if([[_TweetDictionary objectForKey:@"text"] isKindOfClass:[NSString class]])
        {
            tweet.mText = [_TweetDictionary objectForKey:@"text"];
        }
        
        if([[_TweetDictionary objectForKey:@"truncated"] isKindOfClass:[NSNumber class]])
        {
            tweet.mTruncated = [[_TweetDictionary objectForKey:@"truncated"] boolValue];
        }
        
        tweet.mUser = [SNMTweetUser createTweetUserWithDictionary:[_TweetDictionary objectForKey:@"user"]];
        
        tweet.mURLTweet     = [NSString stringWithFormat:@"https://twitter.com/%@/status/%@",tweet.mUser.mScreenName, tweet.mId];
        
        tweet.mTwitterAppLink  = [NSString stringWithFormat:@"twitter://status?id=%@",tweet.mId];
        
        NSDictionary* entities = [_TweetDictionary objectForKey:@"entities"];
        if([entities isKindOfClass:[NSDictionary class]])
        {
            if([[entities objectForKey:@"media"] isKindOfClass:[NSArray class]])
            {
                NSArray* array = [entities objectForKey:@"media"];
                tweet.mArrayImages = [NSMutableArray array];
                for(NSDictionary* dic in array)
                {
                    if([dic isKindOfClass:[NSDictionary class]])
                    {
                        if([[dic objectForKey:@"media_url"] isKindOfClass:[NSString class]])
                        {
                            [tweet.mArrayImages addObject:[dic objectForKey:@"media_url"]];
                        }
                    }
                }
            }
        }
        
    }
    return [tweet autorelease];
}


- (NSString*) getImage:(int)_ImageIndex ForFormat:(int)_ImageFormat
{
    NSString* string;
    switch (_ImageFormat) {
        case thumbFormat:
            string = @"thumb";
        break;
        case smallFormat:
            string = @"small";
        break;
        case mediumFormat:
            string = @"medium";
        break;
        case largeFormat:
            string = @"large";
        break;
        default:
            string = @"large";
        break;
    }
    
    if([self.mArrayImages count] > _ImageIndex)
    {
        return [NSString stringWithFormat:@"%@:%@",[self.mArrayImages objectAtIndex:_ImageIndex],string];
    }
    else
    {
        return nil;
    }
}


- (NSString*) getThumbURLForImage:(int)_ImageIndex
{
    return [self getImage:_ImageIndex ForFormat:thumbFormat];
}

- (NSString*) getSmallURLForImage:(int)_ImageIndex
{
    return [self getImage:_ImageIndex ForFormat:smallFormat];
}

- (NSString*) getMediumURLForImage:(int)_ImageIndex
{
    return [self getImage:_ImageIndex ForFormat:mediumFormat];
}

- (NSString*) getLargeURLForImage:(int)_ImageIndex
{
    return [self getImage:_ImageIndex ForFormat:largeFormat];
}


@end
