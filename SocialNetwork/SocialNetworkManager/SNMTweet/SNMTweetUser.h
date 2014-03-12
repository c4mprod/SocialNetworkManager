//
//  SNMTweetUser.h
//  twitterTest
//
//  Created by Emeric Janowski on 3/29/13.
//  Copyright (c) 2013 Emeric Janowski. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SNMTweetUser : NSObject

@property (nonatomic, retain)   NSDate *        mCreatedDate;
@property (nonatomic, retain)   NSString *      mDescription;
@property (nonatomic)           int             mFavoriteCount;
@property (nonatomic)           int             mFollowersCount;
@property (nonatomic)           int             mFriendsCount;
@property (nonatomic, retain)   NSString *      mId;
@property (nonatomic, retain)   NSString *      mName;
@property (nonatomic, retain)   NSString *      mImageLink;
@property (nonatomic, retain)   NSString *      mScreenName;

+ (SNMTweetUser*) createTweetUserWithDictionary:(NSDictionary*)_UserTweet;
@end
