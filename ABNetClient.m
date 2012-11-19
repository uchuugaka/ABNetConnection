//
//  ABNetClient.m
//  iOS Client
//
//  Created by Aaron Bratcher on 06/28/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ABNetClient.h"

@interface ABNetClient()
@property (nonatomic,strong) 	NSNetServiceBrowser* serviceBrowser;
@property (readwrite) NSNetService* netService;
@end

@implementation ABNetClient 

#pragma mark -
#pragma mark base

- (id)init
{
	return [self initWithDelegate:nil];
}

- (id) initWithDelegate:(id <ABNetClientDelegate>) clientDelegate {
	self = [super init];
	if (self) {
		self.delegate = clientDelegate;
		self.serviceList = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void) dealloc {
	if (self.serviceBrowser) {
		[self stopSearching];
	}
}

- (void) startSearchingWithType:(NSString*) type domain: (NSString*) domain {
	self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[self.serviceBrowser setDelegate: self];
	[self.serviceBrowser searchForServicesOfType:type inDomain:domain];
}

- (void) stopSearching {
	if (self.serviceBrowser) {
		[self.serviceBrowser stop];
		self.serviceBrowser.delegate = nil;
		self.serviceBrowser = nil;
	}
}

- (BOOL) connectToService:(NSNetService*) service {
	NSError *error = nil;
	ABNetConnection* newConnection = [[ABNetConnection alloc] init];
	
	GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] initWithDelegate:newConnection delegateQueue:dispatch_get_main_queue()];
	[socket connectToAddress:service.addresses.lastObject error:&error];
	if (!error) {
		newConnection.delegate = self;
		newConnection.socket = socket;
		self.netConnection = newConnection;
		self.netService = service;
		if (self.delegate && [self.delegate respondsToSelector:@selector(netClientDidConnect:withConnection:toService:)]) {
			[self.delegate netClientDidConnect:self withConnection:self.netConnection toService:service];
		}
		[socket readDataWithTimeout:-1 tag:0];
	}
	
	return !error;
}

- (void) disconnect {
	[self.netConnection disconnect];
	self.netConnection = nil;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(netClientDidDisconnect:)]) {
		[self.delegate netClientDidDisconnect:self];
	}
}

#pragma mark -
#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	[self.serviceList addObject:netService];
	netService.delegate = self;
	[netService resolveWithTimeout:5.0];
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netClient:serviceAdded:)]) {
		[self.delegate netClient:self serviceAdded:netService];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	if ([self.serviceList containsObject:netService]) {
		[self.serviceList removeObject:netService];
	}
	
	if (!moreServicesComing && self.delegate && [self.delegate respondsToSelector:@selector(netClient:serviceRemoved:)]) {
		[self.delegate netClient:self serviceRemoved:netService];
	}
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser {

	if (self.delegate && [self.delegate respondsToSelector:@selector(netClientDidStopSearching:)]) {
		[self.delegate netClientDidStopSearching:self];
	}
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict {
	[self.serviceList removeObject:netService];
}

#pragma mark -
#pragma mark ABNetConnectionDelegate
- (void) netConnection:(ABNetConnection*) connection didReceiveMessage:(NSString *)message ofType:(NSString *)type {	
	if(self.delegate && [self.delegate respondsToSelector:@selector(netClient:didReceiveMessage:ofType:atConnection:)])
		[self.delegate netClient:self didReceiveMessage:message ofType:type atConnection:connection];
}

- (void) didWriteDataToConnection:(ABNetConnection*) connection {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netClientDidWriteData:)]) {
		[self.delegate netClientDidWriteData:self];
	}
}

- (void) netConnectionDidDisconnect:(ABNetConnection*) connection {
	NSLog(@"client disconnected");
	if (self.delegate && [self.delegate respondsToSelector:@selector(netClientDidDisconnect:)]) {
		[self.delegate netClientDidDisconnect:self];
	}
}


@end
