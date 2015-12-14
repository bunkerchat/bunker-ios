//
//  GoogleWebAuthViewController.m
//  WebsocketExampleClient
//
//  Created by Michael Harlow on 11/8/15.
//  Copyright © 2015 Elabs. All rights reserved.
//

#import "GoogleWebAuthViewController.h"
#import "AppDelegate.h"
#import "ViewController.h"

@interface GoogleWebAuthViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *googleAuthWebview;

//@property (weak, nonatomic) ViewController *mainVC;

@end

@implementation GoogleWebAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.googleAuthWebview.delegate = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://bunkerchat.net"]];
    [self.googleAuthWebview loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"should start");
    
    if ([request.URL.absoluteString isEqualToString:@"http://bunkerchat.net/#/"]) {
        self.googleAuthWebview.delegate = nil;
        [self performSegueWithIdentifier:@"doneSegue" sender:self];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"did start");
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"did finish");
    
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
        //NSLog(@"%@", cookie);
        
        //if ([cookie.name isEqualToString:@"sails.sid"]) {
        if ([cookie.name isEqualToString:@"connect.sid"]) {
            [(AppDelegate *)[UIApplication sharedApplication].delegate setSid:cookie.value];
            [(AppDelegate *)[UIApplication sharedApplication].delegate setSocketCookie:cookie];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error {
    NSLog(@"did fail");
    
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
/*- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UIViewController *vc = [segue destinationViewController];
    self.mainVC = (ViewController *)vc;
}*/


@end
