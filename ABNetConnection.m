//
//  ABNetConnection.m
//  iOS Client
//
//  Created by Aaron Bratcher on 06/28/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ABNetConnection.h"


@implementation ABNetConnection {
	NSString* lastMessage;
	NSString* lastType;
	NSTimer* resendTimer;
	int resendSeconds;

	NSTimer* disconnectTimer;
}


#pragma mark - base

- (id)init
{
	return [self initWithSocket:nil];
}

- (id) initWithSocket:(GCDAsyncSocket *)initSocket {
	self = [super init];
	if(self) {
		self.socket = initSocket;
		
		if(initSocket)
			_connected = YES;
	}
	
	return self;
}

- (void) dealloc {
	if (self.socket)
		[self disconnect];
}

- (void) setSocket:(GCDAsyncSocket *)socket {
	_socket = socket;
	_connected = YES;
}


- (void) writeMessage:(NSString*) message ofType:(NSString*) type {
	NSString* rawPacket = [NSString stringWithFormat:@"%@///%@\n",type,message];
	[self.socket writeData:[rawPacket dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];

	NSMutableString* log = [[NSMutableString alloc] init];
	[log setString:@"Message type ("];
	[log appendString:type];
	[log appendString:@") sent: "];
	[log appendString:message];
	
	NSLog(log);

}

- (void) writeMessage:(NSString *)message ofType:(NSString *)type withRewriteTimeout:(int) seconds {
	if (seconds > 0) {
		lastMessage = [message copy];
		lastType = [type copy];
		resendSeconds = seconds;
		
		resendTimer = [NSTimer scheduledTimerWithTimeInterval:resendSeconds         // Ticks once per second
			target:self   // Contains the function you want to call
			selector:@selector(resendLastMessage) 
			userInfo:nil
			repeats:NO];
	}

	[self writeMessage:lastMessage ofType:lastType];
}

- (void) writeMessage:(NSString *)message ofType:(NSString *)type withDisconnectTimeout:(int) seconds {
	if (seconds > 0) {
		lastMessage = [message copy];
		lastType = [type copy];
		
		disconnectTimer = [NSTimer scheduledTimerWithTimeInterval:seconds         // Ticks once per second
																	  target:self   // Contains the function you want to call
																	selector:@selector(timeoutDisconnect)
																	userInfo:nil
																	 repeats:NO];
	}
	
	[self writeMessage:lastMessage ofType:lastType];
}

- (void) resendLastMessage {
	resendTimer = [NSTimer scheduledTimerWithTimeInterval:resendSeconds         // Ticks once per second
																  target:self   // Contains the function you want to call
																selector:@selector(resendLastMessage) 
																userInfo:nil
																 repeats:NO];
	[self writeMessage:lastMessage ofType:lastType];
}

- (void) timeoutDisconnect {
	[self disconnect];
}


- (void) disconnect {
	[self.socket disconnect];
	_connected = NO;
}


#pragma mark - AsyncSocketDelegate

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if(resendTimer && resendTimer.isValid) {
		[resendTimer invalidate];
		resendTimer = nil;
	}
	
	if(disconnectTimer && disconnectTimer.isValid) {
		[disconnectTimer invalidate];
		disconnectTimer = nil;
	}
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(netConnection:didReceiveMessage:ofType:)]) {
		NSString* packet = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];		
		NSArray* messages = [packet componentsSeparatedByString:@"\n"];
		for (NSString* message in messages) {
			if ([message length] == 0) {
				break;
			}
			
			NSArray* parts = [message componentsSeparatedByString:@"///"];
			
			NSMutableString* log = [[NSMutableString alloc] init];
			[log setString:@"Message type ("];
			[log appendString:parts[0]];
			[log appendString:@") received: "];
			[log appendString:parts[1]];
			
			NSLog(log);
			
			[self.delegate netConnection: self didReceiveMessage:parts[1] ofType:parts[0]];
		}
	}
	[sock readDataWithTimeout:-1 tag:0];
}

- (void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	if (self.delegate && [self.delegate respondsToSelector:@selector(netConnectionDidWriteData:)]) {
		[self.delegate didWriteDataToConnection:self];
	}
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
	_connected = NO;
	if (self.delegate && [self.delegate respondsToSelector:@selector(netConnectionDidDisconnect:)]) {
		[self.delegate netConnectionDidDisconnect:self];
	}
}




@end
