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
#import "KJDictionary.h"

@implementation KJDictionary

#pragma mark +NSObject

+ (void)initialize
{
	if([KJDictionary class] != self) return;
	NSArray *const dictInfos = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"KJDictionaries"];
	for(NSDictionary *const info in dictInfos) {
		Class const class = NSClassFromString([info objectForKey:@"KJDictionaryClass"]);
		NSString *const path = [info objectForKey:@"KJDictionaryResourceName"];
		NSNumber *const encoding = [info objectForKey:@"KJDictionaryEncoding"];
		if(!class || !path || !encoding) continue;
		KJDictionary *const dict = [[[class alloc] initWithPath:[[NSBundle mainBundle] pathForResource:path ofType:nil] encoding:[encoding unsignedIntegerValue]] autorelease];
		[dict setName:[info objectForKey:@"KJDictionaryName"]];
		[dict addToDictionaryList];
	}
}

#pragma mark -KJDictionary

@synthesize name = _name;

#pragma mark -NSObject

- (void)dealloc
{
	[_name release];
	[super dealloc];
}

@end

static NSMutableArray *KJRadicalDictionaries;

@implementation KJRadicalDictionary

#pragma mark +KJDictionary(KJAbstract)

+ (NSArray *)dictionaries
{
	return [[KJRadicalDictionaries copy] autorelease];
}

#pragma mark -KJDictionary(KJAbstract)

- (void)addToDictionaryList
{
	if(!KJRadicalDictionaries) KJRadicalDictionaries = [[NSMutableArray alloc] init];
	NSAssert([KJRadicalDictionaries indexOfObjectIdenticalTo:self] == NSNotFound, @"Can't add dictionary more than once.");
	[KJRadicalDictionaries addObject:self];
}

@end

static NSMutableArray *KJKanjiDictionaries;

@implementation KJKanjiDictionary

#pragma mark +KJDictionary(KJAbstract)

+ (NSArray *)dictionaries
{
	return [[KJKanjiDictionaries copy] autorelease];
}

#pragma mark -KJDictionary(KJAbstract)

- (void)addToDictionaryList
{
	if(!KJKanjiDictionaries) KJKanjiDictionaries = [[NSMutableArray alloc] init];
	NSAssert([KJKanjiDictionaries indexOfObjectIdenticalTo:self] == NSNotFound, @"Can't add dictionary more than once.");
	[KJKanjiDictionaries addObject:self];
}

@end
