//
//  AppDelegate.m
//  WebsocketExampleClient
//
//  Created by Elabs Developer on 2/10/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "AppDelegate.h"
#import <Google/GGLContext.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Google
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    //[GIDSignIn sharedInstance].delegate = self;
    //[GIDSignIn sharedInstance].clientID = @"817156086865-u2nepbnuahi35j7vm9skvr8mfn95jesb.apps.googleusercontent.com";//non-bunker
    //[GIDSignIn sharedInstance].clientID = @"744915257573-v66um6neu8ev3m4hg1abiil3qksu6i98.apps.googleusercontent.com";//prod
    //[GIDSignIn sharedInstance].clientID = @"744915257573-ri8suktjsu5s1b3jddkacm6k0a45vi02.apps.googleusercontent.com";//local
    
  return YES;
}

#pragma mark - Google Auth

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    NSLog(@"URL: %@", url.absoluteString);
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *userId = user.userID;                  // For client-side use only!
    NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *name = user.profile.name;
    NSString *email = user.profile.email;
    NSDictionary *statusText = @{@"statusText":
                                     [NSString stringWithFormat:@"Signed in user: %@, userid: %@, email: %@",
                                      name, userId, email]};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ToggleAuthUINotification"
     object:nil
     userInfo:statusText];

    self.token = idToken;
    //[self bunkerAuth];
    [self bunkerStart];
}
// [END signin_handler]

// This callback is triggered after the disconnect call that revokes data
// access to the user's resources has completed.
- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    
    NSDictionary *statusText = @{@"statusText": @"Disconnected user" };
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ToggleAuthUINotification"
     object:nil
     userInfo:statusText];
}

#pragma mark - Unused bunker/websocket calls

- (void)bunkerStart {
    NSString *urlString = [NSString stringWithFormat:@"http://bunkerchat.net/login"];
    //NSString *urlString = [NSString stringWithFormat:@"http://localhost:9002/login"];
    
    //NSDictionary *params = @{@"code": [(AppDelegate *)[UIApplication sharedApplication].delegate token]};
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"application/html" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    //[request setHTTPBody:[self httpBodyForParamsDictionary:params]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        } else {
            NSString* newStr = [NSString stringWithUTF8String:[data bytes]];
            NSLog(@"Signed in as %@", newStr);//data.bytes);
            
            self.sid = @"";
            for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
            {
                //NSLog(@"name: '%@'\n",   [cookie name]);
                //NSLog(@"value: '%@'\n",  [cookie value]);
                //NSLog(@"domain: '%@'\n", [cookie domain]);
                //NSLog(@"path: '%@'\n",   [cookie path]);
                
                if ([cookie.name isEqualToString:@"sails.sid"]) {
                    self.sid = cookie.value;
                    self.socketCookie = cookie;
                }
            }
            
            [self bunkerAuth];
        }
    }];
    [task resume];
}

- (NSString *)sailsCookieString {
    return [NSString stringWithFormat:@"%@=%@", @"sails.sid", self.sid];
}

- (void)bunkerAuth {
    if (!self.token) {
        NSLog(@"Cannot auth to bunker with google token");
        return;
    }
    
    if (!self.sid) {
        NSLog(@"Cannot auth to bunker with sails id");
        return;
    }
    
    NSString *signinEndpoint = [NSString stringWithFormat:@"http://bunkerchat.net/auth/googleCallback"];
    //NSString *signinEndpoint = [NSString stringWithFormat:@"http://localhost:9002/auth/googleCallback"];
    NSDictionary *params = @{@"code": self.token};
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint]];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self sailsCookieString] forHTTPHeaderField:@"Cookie"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[self httpBodyForParamsDictionary:params]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        } else {
            NSString* newStr = [NSString stringWithUTF8String:[data bytes]];
            NSLog(@"Bunker auth with data %@", newStr);//data.bytes);
        }
    }];
    [task resume];
}

- (NSData *)httpBodyForParamsDictionary:(NSDictionary *)paramDictionary
{
    NSError *error =nil;
    return  [NSJSONSerialization dataWithJSONObject:paramDictionary
                                            options:0
                                              error:&error];
}

#pragma mark - App Delegate calls

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
