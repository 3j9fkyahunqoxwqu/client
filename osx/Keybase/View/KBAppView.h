//
//  KBAppView.h
//  Keybase
//
//  Created by Gabriel on 2/4/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KBAppKit.h"
#import "KBRPC.h"
#import "KBEnvironment.h"

@interface KBAppView : YOView

@property (nonatomic) KBRUser *user;
@property (readonly) KBEnvironment *environment;

- (void)openWithEnvironment:(KBEnvironment *)environment;

- (KBWindow *)openWindow;

- (void)showLogin;
- (void)logout:(BOOL)prompt;

- (void)showInProgress:(NSString *)title;
- (void)checkStatus;

- (NSString *)APIURLString:(NSString *)path;

@end
