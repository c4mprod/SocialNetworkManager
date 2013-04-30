//
//  C4MAppDelegate.h
//  SocialNetwork
//
//  Created by Raphael Pinto on 25/04/13.
//  Copyright (c) 2013 Raphael Pinto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPPDeepLink.h"


@interface C4MAppDelegate : UIResponder <UIApplicationDelegate, GPPDeepLinkDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
