//
//  OnePasswordAction.m
//  OnePassword
//
//  Created by Patrick Robertson on 15/01/2010.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// 'form' means UUID

#import "OnePasswordAction.h"


@implementation OnePasswordAction

- (QSObject *)goAndFill:(QSObject *)dObject{
	
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	//If there's multiple forms to fill
	if ([[dObject stringValue] isEqualToString:@"combined objects"])
	{		
		// for each object - do exactly the same thing as for single objects
		for (QSObject *goAndFillObject in [dObject objectForCache:kQSObjectComponents])
		{
			[self writePlistAndFill:goAndFillObject];
		}	
		// If we only have one form to fill / one object
	} 
	else {
		// single object -- same as for multiple objects
		[self writePlistAndFill:dObject];
	}
	
	return nil;
}

- (QSObject *)viewInOnePwd:(QSObject *)dObject {
	
	//If there's multiple forms to fill
	if ([[dObject stringValue] isEqualToString:@"combined objects"])
	{
		NSLog(@"Cannot operate on multiple web forms :(");
		// A nice noise to let the user know something is wrong
		NSBeep();
	}
	else {
		
		DLog(@"Trying to open...");
		DLog(@"dObject label: %@", [dObject label]);
		DLog(@"dObject form key: %@", [dObject objectForMeta:@"form"]);
		NSString *command = @"defaults write ws.agile.1Password findUUID ";
		command = [command stringByAppendingString:[dObject objectForMeta:@"form"]];
		DLog(@"command: %@", command);
		
		// load the script from a resource by fetching its URL from within our bundle
		NSString *path=[[NSBundle bundleForClass:[self class]]pathForResource:@"RevealIn1Pwd" ofType:@"scpt"];
		if (path != nil)
		{
			NSDictionary* scptErrors = [NSDictionary dictionary];
			NSAppleScript* appleScript =
			[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&scptErrors];
			if (appleScript != nil)
			{
				// create the first parameter
				NSAppleEventDescriptor* firstParameter = [NSAppleEventDescriptor descriptorWithString:[dObject label]];
				NSAppleEventDescriptor* secondParameter = [NSAppleEventDescriptor descriptorWithString:command];
				
				// create and populate the list of parameters
				NSAppleEventDescriptor* parameters = [NSAppleEventDescriptor listDescriptor];
				[parameters insertDescriptor:firstParameter atIndex:1];
				[parameters insertDescriptor:secondParameter atIndex:2];
				
				
				// create the AppleEvent target
				ProcessSerialNumber psn = {0, kCurrentProcess};
				NSAppleEventDescriptor* target =
				[NSAppleEventDescriptor
				 descriptorWithDescriptorType:typeProcessSerialNumber
				 bytes:&psn
				 length:sizeof(ProcessSerialNumber)];
				
				// create an NSAppleEventDescriptor with the script's method name to call,
				// this is used for the script statement: "on show_message(user_message)"
				// Note that the routine name must be in lower case.
				NSAppleEventDescriptor* handler =
				[NSAppleEventDescriptor descriptorWithString:
				 [@"reveal_in_1pwd" lowercaseString]];
				
				// create the event for an AppleScript subroutine,
				// set the method name and the list of parameters
				NSAppleEventDescriptor* event =
				[NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
														 eventID:kASSubroutineEvent
												targetDescriptor:target
														returnID:kAutoGenerateReturnID
												   transactionID:kAnyTransactionID];
				[event setParamDescriptor:handler forKeyword:keyASSubroutineName];
				[event setParamDescriptor:parameters forKeyword:keyDirectObject];
				
				// call the event in AppleScript
				if (![appleScript executeAppleEvent:event error:&scptErrors])
				{
					NSLog(@"%@",scptErrors);
					// report any errors from 'errors'
				}
				
				[appleScript release];
			}
			else
			{
				NSLog(@"%@",scptErrors);
				// report any errors from 'errors'
			}
		}
	}
	
	return nil;
}

-(void)writePlistAndFill:(QSObject *)dObject
{		
	
	NSWorkspace * ws = [NSWorkspace sharedWorkspace];
	
	// get the data
	//NSDictionary *dataDict = [dObject dataDictionary];
	
	// Create the path to the fill folder for the 1Pwd extension
	NSString *path = [@"~/Library/Application Support/1Password/Fill" stringByExpandingTildeInPath];
	path = [path stringByAppendingPathComponent:[dObject objectForMeta:@"locationKey"]];
	path = [path stringByAppendingPathExtension:@"plist"];		
	
	//NSLog(@"dataDict: %@",dataDict );
	
	//			Put the reqired data into a dict (for plist creation)
	NSDictionary *plistDict = [NSDictionary dictionaryWithObjectsAndKeys:[dObject objectForMeta:@"form"], @"form", 
							   [dObject name], @"location", 
							   [NSDate date], @"timestamp", nil];
	
	// Write the plist to the Fill folder
	[plistDict writeToFile:path atomically:YES];
	
	// Open the URL
	[ws openURL:[NSURL URLWithString:[dObject name]]];
	
}



//-(QSObject *)trashForm:(QSObject *)dObject
//{
//	NSString *keychainPath= (NSString *)CFPreferencesCopyAppValue((CFStringRef)@"AgileKeychainLocation",(CFStringRef) @"ws.agile.1Password");
//	keychainPath = [keychainPath stringByAppendingPathComponent:@"data/default"];
//
//	//If there's multiple forms to fill
//	if ([[dObject stringValue] isEqualToString:@"combined objects"])
//	{		
//		// for each object - do exactly the same thing as for single objects
//		for (QSObject *goAndFillObject in [dObject objectForCache:kQSObjectComponents])
//		{
//			
//		}	
//		// If we only have one form to fill / one object
//	} 
//	else {
//		// single object -- same as for multiple objects
//	}
//	
//	return nil;
//}
//
//}
@end
