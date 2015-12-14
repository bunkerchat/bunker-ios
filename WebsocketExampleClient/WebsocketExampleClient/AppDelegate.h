//
//  AppDelegate.h
//  WebsocketExampleClient
//
//  Created by Elabs Developer on 2/10/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
//#import <Google/SignIn.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *sid;
@property (strong, nonatomic) NSHTTPCookie *socketCookie;

@end
