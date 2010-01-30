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
#import "KJFoundationAdditions.h"

@implementation NSCharacterSet(KJFoundationAdditions)

- (BOOL)KJ_intersectsWithCharacterSet:(NSCharacterSet *)set
{
	NSData *const d1 = [self bitmapRepresentation];
	NSData *const d2 = [set bitmapRepresentation];
	NSUInteger const length = [d1 length];
	if([d2 length] != length) return NO;
	NSUInteger i = 0;
	uint8_t const *const b1 = [d1 bytes];
	uint8_t const *const b2 = [d2 bytes];
	for(; i < length; i++) if(b1[i] & b2[i]) return YES;
	return NO;
}
- (NSString *)KJ_stringWithCharacters
{
	NSMutableString *const string = [NSMutableString string];
	NSData *const data = [self bitmapRepresentation];
	uint8_t const *const bytes = [data bytes];
	NSUInteger const length = [data length];
	NSUInteger i = 0;
	for(; i < length; i++) {
		if(!bytes[i]) continue;
		#define CHECK(bit) if(bytes[i] & (1 << (bit))) [string appendFormat:@"%C", (unichar)(i * 8 + (bit))];
		CHECK(0)
		CHECK(1)
		CHECK(2)
		CHECK(3)
		CHECK(4)
		CHECK(5)
		CHECK(6)
		CHECK(7)
	}
	return string;
}

@end
