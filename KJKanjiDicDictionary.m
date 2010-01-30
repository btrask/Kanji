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
#import "KJKanjiDicDictionary.h"

@interface KJKanjiDicDictionary(Private)

- (void *)_kanjiCharacterForLine:(NSString *)line;
- (void *)_numberWithIdentifier:(NSString *)ident forLine:(NSString *)line;

@end

@implementation KJKanjiDicDictionary

#pragma mark -KJKanjiDicDictionary(Private)

- (void *)_kanjiCharacterForLine:(NSString *)line
{
	return (void *)(uintptr_t)[line characterAtIndex:0];
}
- (void *)_numberWithIdentifier:(NSString *)ident forLine:(NSString *)line
{
	NSRange const startRange = [line rangeOfString:[NSString stringWithFormat:@" %@", ident] options:NSLiteralSearch];
	if(NSNotFound == startRange.location) return (void *)(uintptr_t)NSNotFound;
	NSUInteger const length = [line length];
	NSRange endRange = [line rangeOfString:@" " options:NSLiteralSearch range:NSMakeRange(NSMaxRange(startRange), length - NSMaxRange(startRange))];
	if(NSNotFound == endRange.location) endRange = NSMakeRange(length, 0);
	return (void *)(uintptr_t)[[line substringWithRange:NSMakeRange(NSMaxRange(startRange), endRange.location - NSMaxRange(startRange))] integerValue];
}

#pragma mark -KJKanjiDictionary(KJAbstract)

- (NSUInteger)strokeCountForCharacter:(unichar)character
{
	return (uintptr_t)CFDictionaryGetValue(_strokeCountByCharacter, (void *)(uintptr_t)character);
}
- (NSUInteger)gradeForCharacter:(unichar)character
{
	return (uintptr_t)CFDictionaryGetValue(_gradeByCharacter, (void *)(uintptr_t)character);
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
	_strokeCountByCharacter = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	_gradeByCharacter = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	for(NSString *const line in [file componentsSeparatedByString:@"\n"]) {
		if(![line length] || [line hasPrefix:@"#"]) continue;
		CFDictionaryAddValue(_strokeCountByCharacter, [self _kanjiCharacterForLine:line], [self _numberWithIdentifier:@"S" forLine:line]);
		CFDictionaryAddValue(_gradeByCharacter, [self _kanjiCharacterForLine:line], [self _numberWithIdentifier:@"G" forLine:line]);
	}
	return self;
}

#pragma mark -NSObject

- (void)dealloc
{
	CFRelease(_strokeCountByCharacter);
	CFRelease(_gradeByCharacter);
	[super dealloc];
}

@end
