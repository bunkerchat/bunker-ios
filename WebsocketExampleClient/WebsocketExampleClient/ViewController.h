//
//  ViewController.h
//  WebsocketExampleClient
//
//  Created by Elabs Developer on 2/10/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SocketRocket/SRWebSocket.h>
#import <GoogleSignIn/GoogleSignIn.h>

@interface ViewController : UIViewController <SRWebSocketDelegate, UITextFieldDelegate, GIDSignInUIDelegate>//, GPPSignInDelegate>

@property (weak, nonatomic) IBOutlet UITextView *messagesTextView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;

- (IBAction)sendMessage:(id)sender;

- (void)toggleAuthUI;

@end
