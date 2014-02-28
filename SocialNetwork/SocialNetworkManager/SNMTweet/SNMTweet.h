//
//  SNMTweet.h
//  twitterTest
//
//  Created by Emeric Janowski on 3/29/13.
//  Copyright (c) 2013 Emeric Janowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNMTweetUser.h"

enum TweetImageFormat
{
    thumbFormat,
    smallFormat,
    mediumFormat,
    largeFormat
};


@interface SNMTweet : NSObject


@property(nonatomic, retain)    NSDate *        mCreatedDate;
@property(nonatomic)            int             mFavoriteCount;
@property(nonatomic)            int             mFavorited;
@property(nonatomic, retain)    NSString *      mId;
@property(nonatomic)            int             mRetweetCount;
@property(nonatomic, retain)    NSString *      mText;
@property(nonatomic)            BOOL            mTruncated;
@property(nonatomic, retain)    NSString *      mURLTweet;
@property(nonatomic, retain)    SNMTweetUser *  mUser;
@property(nonatomic, retain)    NSMutableArray *mArrayImages;
@property(nonatomic, retain)    NSString *      mTwitterAppLink;


+ (SNMTweet*) createTweetObjectWithDictionary:(NSDictionary*)_TweetDictionary;


- (NSString*) getThumbURLForImage:(int)_ImageIndex;
- (NSString*) getSmallURLForImage:(int)_ImageIndex;
- (NSString*) getMediumURLForImage:(int)_ImageIndex;
- (NSString*) getLargeURLForImage:(int)_ImageIndex;

@end
