//
//  ABNetClient.h
//  iOS Client
//
//  Created by Aaron Bratcher on 06/28/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABNetConnection.h"

@protocol ABNetClientDelegate;


@interface ABNetClient : NSObject<NSNetServiceDelegate,NSNetServiceBrowserDelegate,ABNetConnectionDelegate> {

}

@property (nonatomic,strong) id<ABNetClientDelegate> delegate;
@property (nonatomic,strong) NSMutableArray* serviceList;
@property (readonly,strong) NSNetService* netService;
@property (nonatomic,strong) ABNetConnection* netConnection;

- (id) initWithDelegate:(id <ABNetClientDelegate>) clientDelegate;
- (void) startSearchingWithType:(NSString*) type domain: (NSString*) domain;
- (void) stopSearching;
- (BOOL) connectToService:(NSNetService*) service;
- (void) disconnect;

@end





@protocol ABNetClientDelegate <NSObject>

@optional

- (void) netClient:(ABNetClient*) client didNotSearch:(NSDictionary *)errorInfo;
- (void) netClient:(ABNetClient*) client serviceAdded:(NSNetService*)service;
- (void) netClient:(ABNetClient *)client serviceRemoved:(NSNetService*)service;
- (void) netClientDidStopSearching:(ABNetClient*) client;

- (void) netClientDidConnect:(ABNetClient*) client withConnection:(ABNetConnection*) connection toService:(NSNetService*) netService;
- (void) netClientDidDisconnect:(ABNetClient*) client;

- (void) netClient:(ABNetClient*) client didReceiveMessage:(NSString*) message ofType:(NSString*) type atConnection:(ABNetConnection*) connection;
- (void) netClientDidWriteData:(ABNetClient*) client;
@end