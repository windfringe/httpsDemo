//
//  ViewController.m
//  httpsDemo
//
//  Created by mobile_dev01 on 15/6/26.
//  Copyright (c) 2015年 sipsd. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>

#define kAllowsInvalidSSLCertificate 1

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self sslRequest];
}


- (void)sslRequest
{
    AFHTTPRequestSerializer *reqSerializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *request;
    
    NSString *httpsURL = @"https://www.example.com";
    request = [reqSerializer requestWithMethod:@"GET" URLString:httpsURL parameters:nil error:nil];
    
    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:kAllowsInvalidSSLCertificate];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [operation setSecurityPolicy:securityPolicy];
    
    [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
        if ([challenge previousFailureCount] > 0) {
            //this will cause an authentication failure
            [[challenge sender] cancelAuthenticationChallenge:challenge];
            NSLog(@"Bad Username Or Password");
            return;
        }
        
        //this is checking the server certificate
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            SecTrustResultType result;
            //This takes the serverTrust object and checkes it against your keychain
            SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
            
            //if we want to ignore invalid server for certificates, we just accept the server
            if (kAllowsInvalidSSLCertificate) {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] forAuthenticationChallenge: challenge];
                return;
            } else if(result == kSecTrustResultProceed || result == kSecTrustResultUnspecified) {
                //When testing this against a trusted server I got kSecTrustResultUnspecified every time. But the other two match the description of a trusted server
                [challenge.sender useCredential:[NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] forAuthenticationChallenge: challenge];
                return;
            }
        } else if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodClientCertificate) {
            //this handles authenticating the client certificate
            
            /*
             What we need to do here is get the certificate and an an identity so we can do this:
             NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:myCerts persistence:NSURLCredentialPersistencePermanent];
             [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
             
             It's easy to load the certificate using the code in -installCertificate
             It's more difficult to get the identity.
             We can get it from a .p12 file, but you need a passphrase:
             */
            
            NSData *p12Data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ios_cer" ofType:@"pfx"]];
            
            // your p12 password
            CFStringRef password = CFSTR("p12 PASSPHRASE");
            const void *keys[] = { kSecImportExportPassphrase };
            const void *values[] = { password };
            CFDictionaryRef optionsDictionary = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            CFArrayRef p12Items;
            
            OSStatus result = SecPKCS12Import((__bridge CFDataRef)p12Data, optionsDictionary, &p12Items);
            
            if(result == noErr) {
                CFDictionaryRef identityDict = CFArrayGetValueAtIndex(p12Items, 0);
                SecIdentityRef identityApp =(SecIdentityRef)CFDictionaryGetValue(identityDict,kSecImportItemIdentity);
                
                SecCertificateRef certRef;
                SecIdentityCopyCertificate(identityApp, &certRef);
                
                SecCertificateRef certArray[1] = { certRef };
                CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
                CFRelease(certRef);
                
                NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identityApp certificates:(__bridge NSArray *)myCerts persistence:NSURLCredentialPersistencePermanent];
                CFRelease(myCerts);
                
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
            }
        } else if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodDefault || [[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodNTLM) {
            
            // For normal authentication based on username and password. This could be NTLM or Default.
            /*
             DAVCredentials *cred = _parentSession.credentials;
             NSURLCredential *credential = [NSURLCredential credentialWithUser:cred.username password:cred.password persistence:NSURLCredentialPersistenceForSession];
             [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
             */
            
            NSLog(@"BASIC AUTHENTICATION");
            
        } else {
            //If everything fails, we cancel the challenge.
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // 对AFHTTPRequestOperation返回的responseObject获取字符串形式的数据，在转成json
        NSString *html = operation.responseString;
        NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
        id dict = [NSJSONSerialization  JSONObjectWithData:data options:0 error:nil];
        NSLog(@"获取到的数据为：%@",dict);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"error:%@",error);
        
    }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
