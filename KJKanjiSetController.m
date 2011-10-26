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
#import "KJKanjiSetController.h"

// Models
#import "KJDictionary.h"

// Other Sources
#import "KJFoundationAdditions.h"

static NSComparisonResult KJSortKanjiStringsByGrade(NSString *a, NSString *b, KJKanjiDictionary *dict)
{
	return (NSInteger)[dict gradeForCharacter:[a characterAtIndex:0]] - (NSInteger)[dict gradeForCharacter:[b characterAtIndex:0]];
}

@implementation KJKanjiSetController

#pragma mark -KJKanjiSetController

- (id)initWithCharacterSet:(NSCharacterSet *)characterSet inDictionary:(KJKanjiDictionary *)dictionary
{
	if(!(self = [super init])) return nil;
	_characterSet = [characterSet retain];
	_dictionary = [dictionary retain];
	_kanjiStringByStrokeCount = [[NSMutableDictionary alloc] init];
	NSUInteger i = 0;
	NSString *const allCharacters = [characterSet KJ_stringWithCharacters];
	for(; i < [allCharacters length]; i++) {
		unichar const character = [allCharacters characterAtIndex:i];
		NSUInteger const strokeCount = [dictionary strokeCountForCharacter:character];
		NSNumber *const strokeCountNumber = [NSNumber numberWithUnsignedInteger:strokeCount];
		NSMutableArray *characters = [_kanjiStringByStrokeCount objectForKey:strokeCountNumber];
		if(!characters) {
			characters = [NSMutableArray array];
			[_kanjiStringByStrokeCount setObject:characters forKey:strokeCountNumber];
		}
		[characters addObject:[NSString stringWithFormat:@"%C", character]];
	}
	for(NSMutableArray *const characters in [_kanjiStringByStrokeCount allValues]) [characters sortUsingFunction:(NSInteger (*)(id, id, void *))KJSortKanjiStringsByGrade context:_dictionary];
	_strokeCounts = [[[_kanjiStringByStrokeCount allKeys] sortedArrayUsingSelector:@selector(compare:)] copy];
	return self;
}
@synthesize characterSet = _characterSet;

#pragma mark -NSObject

- (void)dealloc
{
	[_characterSet release];
	[_dictionary release];
	[_strokeCounts release];
	[_kanjiStringByStrokeCount release];
	[super dealloc];
}

#pragma mark -<KJLineGridViewDataSource>

- (NSUInteger)numberOfLinesInLineGridView:(KJLineGridView *)sender
{
	return [_strokeCounts count];
}
- (NSUInteger)lineGridView:(KJLineGridView *)sender numberOfCellsInLine:(NSUInteger)line
{
	return [[_kanjiStringByStrokeCount objectForKey:[_strokeCounts objectAtIndex:line]] count];
}
- (void)lineGridView:(KJLineGridView *)sender prepareCell:(id)cell atPosition:(KJLineGridPosition)position
{
	static NSMutableParagraphStyle *paragraphStyle;
	if(!paragraphStyle) {
		paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
	}
	NSNumber *const strokeCount = [_strokeCounts objectAtIndex:position.line];
	if(KJHeaderIndex == position.index) [cell setTitle:[strokeCount stringValue]];
	else {
		NSString *const characterString = [[_kanjiStringByStrokeCount objectForKey:strokeCount] objectAtIndex:position.index];
		NSUInteger const grade = [_dictionary gradeForCharacter:[characterString characterAtIndex:0]];
		[cell setAttributedTitle:[[[NSAttributedString alloc] initWithString:characterString attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:18.0f], NSFontAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			[[NSColor textColor] colorWithAlphaComponent:NSNotFound == grade ? 0.4f : 1.0f - 0.5f * (CGFloat)log10(grade)], NSForegroundColorAttributeName,
			nil]] autorelease]];
	}
}

@end
