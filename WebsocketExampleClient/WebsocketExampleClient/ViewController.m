//
//  ViewController.m
//  WebsocketExampleClient
//
//  Created by Elabs Developer on 2/10/14.
//  Copyright (c) 2014 Elabs. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <Socket_IO_Client_Swift/Socket_IO_Client_Swift-Swift.h>

@interface ViewController () {
  SRWebSocket *webSocket;
}

@property (weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *webAuthButton;

@property (strong, nonatomic) SocketIOClient *socket;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  //[self connectWebSocket];

  UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [self.messagesTextView addGestureRecognizer:tgr];

  [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    UIViewAnimationOptions options = curve << 16;

    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
      CGRect frame = self.containerView.frame;
      frame.origin.y = CGRectGetMinY(endFrame) - CGRectGetHeight(self.containerView.frame);
      self.containerView.frame = frame;

      frame = self.messagesTextView.frame;
      frame.size.height = CGRectGetMinY(self.containerView.frame) - CGRectGetMinY(frame);
      self.messagesTextView.frame = frame;
    } completion:nil];
  }];
    
    /*[GIDSignIn sharedInstance].uiDelegate = self;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(receiveToggleAuthUINotification:)
     name:@"ToggleAuthUINotification"
     object:nil];*/
    
    [self toggleAuthUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([(AppDelegate *)[UIApplication sharedApplication].delegate socketCookie]) {
        [self hideAuthUI];
        
        [self socketIO];
    }
}

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage:nil];
    return YES;
}

- (IBAction)sendMessage:(id)sender {
    /*if (!webSocket) {
     [self connectWebSocket];
     }
     [webSocket send:self.messageTextField.text];*/
    
    self.messageTextField.text = nil;
}


- (void)toggleAuthUI {
    if ([GIDSignIn sharedInstance].currentUser.authentication == nil) {
        // Not signed in
        [self showAuthUI];
    } else {
        // Signed in
        [self hideAuthUI];
    }
}

- (void)showAuthUI {
    //[self statusText].text = @"Google Sign in\niOS Demo";
    self.signInButton.hidden = NO;
    self.webAuthButton.hidden = NO;
    self.signOutButton.hidden = YES;
    //self.disconnectButton.hidden = YES;
}

- (void)hideAuthUI {
    self.signInButton.hidden = YES;
    self.webAuthButton.hidden = YES;
    self.signOutButton.hidden = NO;
    //self.disconnectButton.hidden = NO;
}
// [END toggle_auth]

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:@"ToggleAuthUINotification"
     object:nil];
    
}

- (void)receiveToggleAuthUINotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ToggleAuthUINotification"]) {
        [self toggleAuthUI];
        //self.statusText.text = [notification userInfo][@"statusText"];
    }
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

#pragma mark - Socket IO

- (void)socketIO {
    //NSString *sid = [(AppDelegate *)[UIApplication sharedApplication].delegate sid];
    NSHTTPCookie *cookie = [(AppDelegate *)[UIApplication sharedApplication].delegate socketCookie];
    if (!cookie) {
        NSLog(@"no cookie for socket io");
        return;
    }
    NSString *urlString = @"bunkerchat.net";
    //NSString *urlString = [NSString stringWithFormat:@"ws://bunkerchat.net/socket.io/?__sails_io_sdk_version=0.11.0&__sails_io_sdk_platform=browser&__sails_io_sdk_language=javascript&EIO=3&transport=websocket"];
    NSDictionary *params = @{@"__sails_io_sdk_version":@"0.11.0", @"__sails_io_sdk_platform":@"browser", @"__sails_io_sdk_language":@"javascript", @"EIO":@"3"};//, @"transport": @"websocket"};
    self.socket = [[SocketIOClient alloc] initWithSocketURL:urlString options:@{
                                                                                @"log": @YES,
                                                                                           @"forcePolling": @YES,
                              @"cookies": @[cookie],
                                                                                           @"connectParams":params
                              }
                              ];
    
    
    [self.socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
        ///NSArray *arr = @[@{@"method":@"get",@"headers":@{},@"data":@{},@"url":@"/init"}];
        NSArray *arr = @[@"NULL"];
        //[self.socket emitWithAck:@"get" withItems:arr];
        //[self.socket emit:@"get" withItems:arr];
        //[self.socket emitWithAck:@"get" withItems:arr](0, ^(NSArray* data) {
        [self.socket emitWithAck:@"/init" withItems:arr](0, ^(NSArray *data) {
            NSLog(@"received data!");
        });
    }];
    
    [self.socket on:@"disconnect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket disconnected");
    }];
    
    [self.socket on:@"reconnect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket trying to reconnect");
    }];
    
    [self.socket on:@"error" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket error %@", data);
    }];
    
    [self.socket onAny:^(SocketAnyEvent *event) {
        //SocketIOClientStatus status = self.socket.status;
        if ([self isNewEvent:event]) {
            NSLog(@"Any event - %@", event.event);
        }
    }];
    
    [self.socket on:@"/init" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"/INIT event!");
    }];
    
    [self.socket on:@"init" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"INIT event!");
    }];
    
    [self.socket on:@"messaged" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"Messaged event!");
    }];
    
    [self.socket on:@"user" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"User event!");
    }];
    
    [self.socket on:@"room" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"Room event!");
    }];
    
    /*[self.socket on:@"currentAmount" callback:^(NSArray* data, SocketAckEmitter* ack) {
        double cur = [[data objectAtIndex:0] floatValue];
        
        [socket emitWithAck:@"canUpdate" withItems:@[@(cur)]](0, ^(NSArray* data) {
            [socket emit:@"update" withItems:@[@{@"amount": @(cur + 2.50)}]];
        });
        
        [ack with:@[@"Got your currentAmount, ", @"dude"]];
    }];*/
    
    [self.socket connect];
}

- (BOOL)isNewEvent:(SocketAnyEvent *)event {
    NSString *name = event.event;
    if ([name isEqualToString:@"room"] ||
        [name isEqualToString:@"user"]) {
        return NO;
    }
    return YES;
}

- (NSData *)httpBodyForParamsDictionary:(NSDictionary *)paramDictionary
{
    NSError *error =nil;
    return  [NSJSONSerialization dataWithJSONObject:paramDictionary
                                            options:0
                                              error:&error];
}

#pragma mark - unused SRWebSocket delegate

- (void)connectWebSocket {
    webSocket.delegate = nil;
    webSocket = nil;
    
    //NSString *urlString = @"ws://bunkerchat.net/init";
    /*  NSString *sid = [(AppDelegate *)[UIApplication sharedApplication].delegate sid];
     NSString *urlString = [NSString stringWithFormat:@"ws://bunkerchat.net/socket.io/?__sails_io_sdk_version=0.11.0&__sails_io_sdk_platform=browser&__sails_io_sdk_language=javascript&EIO=3&transport=websocket&sid=%@", sid];
     SRWebSocket *newWebSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
     newWebSocket.delegate = self;
     
     [newWebSocket open];*/
    
    //[self socketIO];
    //[self bunkerStart];
    //[self bunkerSocket];
}

- (void)bunkerSocket {
    NSString *sid = [(AppDelegate *)[UIApplication sharedApplication].delegate sid];
    NSString *urlString = [NSString stringWithFormat:@"http://bunkerchat.net/socket.io/?__sails_io_sdk_version=0.11.0&__sails_io_sdk_platform=browser&__sails_io_sdk_language=javascript&EIO=3&transport=websocket&sid=%@", sid];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        } else {
            NSString* newStr = [NSString stringWithUTF8String:[data bytes]];
            NSLog(@"Signed in as %@", newStr);//data.bytes);
        }
    }];
    [task resume];
}

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
  webSocket = newWebSocket;
  [webSocket send:[NSString stringWithFormat:@"Hello from %@", [UIDevice currentDevice].name]];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    if (error) {
        NSLog(@"Error on websocket %@", error.localizedDescription);
    } else {
        [self connectWebSocket];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
  [self connectWebSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
  self.messagesTextView.text = [NSString stringWithFormat:@"%@\n%@", self.messagesTextView.text, message];
}

- (IBAction)didTapSignOut:(id)sender {
    [[GIDSignIn sharedInstance] signOut];
    [self toggleAuthUI];
}

// Note: Disconnect revokes access to user data and should only be called in
//     scenarios such as when the user deletes their account. More information
//     on revocation can be found here: https://goo.gl/Gx7oEG.
- (IBAction)didTapDisconnect:(id)sender {
    [[GIDSignIn sharedInstance] disconnect];
}

@end
