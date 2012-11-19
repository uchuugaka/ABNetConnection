//
//  ABNetServer.m
//  iOS Client
//
//  Created by Aaron Bratcher on 06/28/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ABNetServer.h"

@interface ABNetServer()
@property(nonatomic,retain) GCDAsyncSocket* serverSocket;
@property(readwrite) NSNetService* netService;

@end

@implementation ABNetServer


#pragma mark -
#pragma mark base

- (id) init {
	return [self initWithDelegate:nil];
}

- (id) initWithDelegate:(id<ABNetServerDelegate>)serverDelegate {
	self = [super init];
	if (self) {
		self.delegate = serverDelegate;
		self.connections = [[NSMutableArray alloc] init];
		self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	
	return self;
}


- (void) startPublishingWithName:(NSString*) name type:(NSString*) type domain: (NSString*) domain {
	int port; 
	
	if ([self.serverSocket acceptOnPort:0 error:NULL]) {
		port = [self.serverSocket localPort];
		if (port == 0) {
			if(self.delegate && [self.delegate respondsToSelector:@selector(netServerDidNotPublish:)])
				[self.delegate netServerDidNotPublish:self];
		}
		else {
			self.netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:port];
			
			if(self.netService != nil) {
				self.netService.delegate = self;
				[self.netService publishWithOptions:NSNetServiceNoAutoRename];
			} else {
				[self stopPublishing];
				if(self.delegate && [self.delegate respondsToSelector:@selector(netServerDidNotPublish:)])
					[self.delegate netServerDidNotPublish:self];
			}
		}
	}
}


- (void) stopPublishing {
	if(self.netService) {
		[self.netService stop];
		[self.serverSocket disconnect];
		self.netService = nil;
	}
}

- (void) disconnect:(ABNetConnection *)connection {
	[connection disconnect];
}

- (void) disconnectAll {
	[self.connections makeObjectsPerformSelector:@selector(disconnect)];

	if (self.delegate && [self.delegate respondsToSelector:@selector(netServerDidDisconnectAll:)]) {
		[self.delegate netServerDidDisconnectAll:self];
	}
}


#pragma mark -
#pragma mark AsyncSocketDelegate
- (void) socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	ABNetConnection* connection = [[ABNetConnection alloc] initWithSocket:newSocket];
	newSocket.delegate = connection;
	connection.delegate = self;
	[newSocket readDataWithTimeout:-1 tag:0];

	[self.connections addObject:connection];

	if (self.delegate && [self.delegate respondsToSelector:@selector(netServer:didAcceptConnection:)]) {
		[self.delegate netServer:self didAcceptConnection:connection];
	}	
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

	NSLog(@"server received data");
}


#pragma mark -
#pragma mark NSNetServiceDelegate
- (void)netServiceDidPublish:(NSNetService *)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netServerDidPublish:)])
		[self.delegate netServerDidPublish:self];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	if(self.delegate && [self.delegate respondsToSelector:@selector(netServerDidNotPublish:)])
		[self.delegate netServerDidNotPublish:self];
}

- (void)netServiceDidStop:(NSNetService *)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netServerDidStopPublishing:)]) {
		[self.delegate netServerDidStopPublishing:self];
	}
}



#pragma mark -
#pragma mark netConnectionDelegate

- (void) netConnection:(ABNetConnection*) connection didReceiveMessage:(NSString *)message ofType:(NSString *)type {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netServer:didReceiveMessage:ofType:atConnection:)]) {
		[self.delegate netServer:self didReceiveMessage:message ofType:type atConnection:connection];
	}
}

- (void) didWriteDataToConnection:(ABNetConnection*) connection {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netServerDidWriteData:)]) {
		[self.delegate netServerDidWriteData:self];
	}
}

- (void) netConnectionDidDisconnect:(ABNetConnection *)connection {
	NSLog(@"server disconnected");
	if ([self.connections containsObject:connection]) {
		[self.connections removeObject:connection];
	}
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(netServer:didDisconnect:)]) {
		[self.delegate netServer:self didDisconnect:connection];
	}
}

@end
