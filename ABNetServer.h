//
//  ABNetServer.h
//  iOS Client
//
//  Created by Aaron Bratcher on 06/28/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABNetConnection.h"

@protocol ABNetServerDelegate;

@interface ABNetServer : NSObject<NSNetServiceDelegate,ABNetConnectionDelegate,GCDAsyncSocketDelegate> {

	
}

@property (nonatomic,strong) id<ABNetServerDelegate> delegate;
@property (nonatomic,strong) NSMutableArray* connections;
@property (readonly, strong) 	NSNetService* netService;

- (id) initWithDelegate:(id <ABNetServerDelegate>) serverDelegate;
- (void) startPublishingWithName:(NSString*) name type:(NSString*) type domain: (NSString*) domain;
- (void) stopPublishing;
- (void) disconnect:(ABNetConnection*) connection;
- (void) disconnectAll;

@end





@protocol ABNetServerDelegate <NSObject>

@optional
- (void)netServerDidNotPublish:(ABNetServer*)server;
- (void)netServerDidPublish:(ABNetServer*)server;
- (void)netServerDidStopPublishing:(ABNetServer*)server;

- (void)netServer:(ABNetServer*)server didAcceptConnection:(ABNetConnection*) connection;
- (void)netServer:(ABNetServer*)server didDisconnect:(ABNetConnection*) connection;
- (void)netServerDidDisconnectAll:(ABNetServer*)server;

- (void)netServer:(ABNetServer*)server didReceiveMessage:(NSString *) message ofType:(NSString*) type atConnection:(ABNetConnection*) connection;
- (void)netServerDidWriteData:(ABNetServer*) server;
@end