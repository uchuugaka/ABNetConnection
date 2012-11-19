//
//  ABNetConnection.h
//  iOS Client
//
//  Created by Aaron Bratcher on 06/28/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "ABRecordset.h"

@protocol ABNetConnectionDelegate;


@interface ABNetConnection : NSObject<GCDAsyncSocketDelegate>

@property (strong, nonatomic) id<ABNetConnectionDelegate> delegate;
@property (strong, nonatomic) GCDAsyncSocket* socket;
@property (assign) BOOL connected;


- (id)initWithSocket:(GCDAsyncSocket*) initSocket;
- (void) writeMessage:(NSString*) message ofType:(NSString*) type;
- (void) writeMessage:(NSString *)message ofType:(NSString *)type withRewriteTimeout:(int) seconds;
- (void) writeMessage:(NSString *)message ofType:(NSString *)type withDisconnectTimeout:(int) seconds;
- (void) disconnect;

@end





@protocol ABNetConnectionDelegate <NSObject>

- (void) netConnection:(ABNetConnection*) connection didReceiveMessage:(NSString*) message ofType:(NSString*) type;
- (void) didWriteDataToConnection:(ABNetConnection*) connection;
- (void) netConnectionDidDisconnect:(ABNetConnection*) connection;

@end