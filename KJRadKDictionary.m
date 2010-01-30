/* Copyright (c) 2010, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
	* The names of its contributors may be used to endorse or promote products
	  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY BEN TRASK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN TRASK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "KJRadKDictionary.h"

// Models
#import "KJRadical.h"

enum {
	KJRadKIndicator,
	KJRadKRadical,
	KJRadKStrokeCount,
	KJRadKRadicalInfo,
};

@interface KJRadKDictionary(Private)

- (BOOL)_getCharacterSet:(out NSMutableCharacterSet **)outCharSet forLine:(NSString *)line;

@end

@implementation KJRadKDictionary

#pragma mark -KJRadKDictionar(Private)

- (BOOL)_getCharacterSet:(out NSMutableCharacterSet **)outCharSet forLine:(NSString *)line
{
	if(![line hasPrefix:@"$"]) return NO;
	*outCharSet = [[[NSMutableCharacterSet alloc] init] autorelease];
	NSArray *const components = [line componentsSeparatedByString:@" "];
	KJRadical *const radical = [[[KJRadical alloc] init] autorelease];
	[radical setRadicalString:[components objectAtIndex:KJRadKRadical]];
	NSString *const strokeCountString = [components objectAtIndex:KJRadKStrokeCount];
	[radical setStrokeCount:[strokeCountString integerValue]];
	[radical setCharacterSet:*outCharSet];
	NSMutableArray *radicals = [_radicalsByStrokeCount objectForKey:strokeCountString];
	if(!radicals) {
		radicals = [NSMutableArray array];
		[_radicalsByStrokeCount setObject:radicals forKey:strokeCountString];
		[_strokeCounts addObject:strokeCountString];
	}
	[radicals addObject:radical];
	return YES;
}

#pragma mark -KJRadicalDictionary(KJAbstract)

- (NSArray *)strokeCounts
{
	return [[_strokeCounts copy] autorelease];
}
- (NSArray *)radicalsWithStrokeCount:(id)count
{
	return [[[_radicalsByStrokeCount objectForKey:count] copy] autorelease];
}
- (NSString *)stringWithStrokeCount:(id)count
{
	return count;
}

#pragma mark -KJDictionary(KJAbstract)

- (id)initWithPath:(NSString *)path encoding:(NSStringEncoding)encoding
{
	if(!(self = [super init])) return nil;
	NSString *const file = [NSString stringWithContentsOfFile:path encoding:encoding error:NULL];
	if(!file) {
		[self release];
		return nil;
	}
	_strokeCounts = [[NSMutableArray alloc] init];
	_radicalsByStrokeCount = [[NSMutableDictionary alloc] init];
	NSMutableCharacterSet *characters = nil;
	for(NSString *const line in [file componentsSeparatedByString:@"\n"]) {
		if([line hasPrefix:@"#"]) continue;
		if(![self _getCharacterSet:&characters forLine:line]) [characters addCharactersInString:line];
	}
	return self;
}

#pragma mark -NSObject

- (void)dealloc
{
	[_strokeCounts release];
	[_radicalsByStrokeCount release];
	[super dealloc];
}

@end
