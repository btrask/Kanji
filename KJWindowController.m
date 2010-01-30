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
#import "KJWindowController.h"

// Models
#import "KJDictionary.h"
#import "KJRadical.h"

// Controllers
#import "KJKanjiSetController.h"

// Other Sources
#import "KJFoundationAdditions.h"

@interface KJWindowController(Private)

- (void)_updateResults;

@end

@implementation KJWindowController

#pragma mark -KJWindowController

- (IBAction)changeRadicalDictionary:(id)sender
{
	[self clearRadicals:sender];
}
- (IBAction)changeKanjiDictionary:(id)sender
{
	[self _updateResults];
}
- (IBAction)toggleRadical:(id)sender
{	
	KJRadical *const radical = [[sender editingCell] representedObject];
	if([_selectedRadicals containsObject:radical]) [_selectedRadicals removeObject:radical];
	else [_selectedRadicals addObject:radical];
	[self _updateResults];
}
- (IBAction)clearRadicals:(id)sender
{
	[_selectedRadicals removeAllObjects];
	[radicalView reloadData];
	[self _updateResults];
}
- (IBAction)kanjiAction:(id)sender
{
	NSString *const kanji = [[sender editingCell] title];
	switch([[[self window] currentEvent] clickCount]) {
		case 1:
		{
			NSPasteboard *const pb = [NSPasteboard generalPasteboard];
			[pb clearContents];
			if(![pb writeObjects:[NSArray arrayWithObject:kanji]]) NSBeep();
			break;
		}
		case 2:
			if(![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://jisho.org/kanji/details/%@", kanji]]]) NSBeep();
			break;
	}
}

#pragma mark -

- (KJRadicalDictionary *)radicalDictionary
{
	return [[radicalDictionaryPopUp selectedItem] representedObject];
}
- (KJKanjiDictionary *)kanjiDictionary
{
	return [[kanjiDictionaryPopUp selectedItem] representedObject];
}

#pragma mark -KJWindowController(Private)

- (void)_updatePopUp:(NSPopUpButton *)popUp withDictionaries:(NSArray *)dictionaries
{
	[popUp removeAllItems];
	for(KJDictionary *const dict in dictionaries) {
		NSMenuItem *const item = [[[NSMenuItem alloc] initWithTitle:[dict name] action:NULL keyEquivalent:@""] autorelease];
		[item setRepresentedObject:dict];
		[[popUp menu] addItem:item];
	}
	[popUp setEnabled:[dictionaries count] > 1];
}
- (void)_updateResults
{
	NSMutableCharacterSet *const characters = [[[[_selectedRadicals anyObject] characterSet] mutableCopy] autorelease];
	for(KJRadical *const radical in _selectedRadicals) [characters formIntersectionWithCharacterSet:[radical characterSet]];
	[_resultController release];
	_resultController = [[KJKanjiSetController alloc] initWithCharacterSet:characters inDictionary:[self kanjiDictionary]];
	[resultView setDataSource:_resultController];
	[resultView reloadData];
}

#pragma mark -NSObject

- (id)init
{
	if((self = [super initWithWindowNibName:@"KJRadicalDictionary"])) {
		_selectedRadicals = [[NSMutableSet alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[_selectedRadicals release];
	[_resultController release];
	[super dealloc];
}

#pragma mark -NSObject(NSNibAwaking)

- (void)awakeFromNib
{
	[super awakeFromNib];

	[self _updatePopUp:radicalDictionaryPopUp withDictionaries:[KJRadicalDictionary dictionaries]];
	[self _updatePopUp:kanjiDictionaryPopUp withDictionaries:[KJKanjiDictionary dictionaries]];

	{
		NSButtonCell *const headerPrototype = [[[NSButtonCell alloc] init] autorelease];
		[headerPrototype setBezelStyle:NSShadowlessSquareBezelStyle];
		[headerPrototype setButtonType:NSMomentaryLightButton];
		[headerPrototype setBordered:NO];
		[headerPrototype setEnabled:NO];
		[headerPrototype setFont:[NSFont systemFontOfSize:18.0f]];
		[radicalView setHeaderCell:[[headerPrototype copy] autorelease]];
		[resultView setHeaderCell:[[headerPrototype copy] autorelease]];
	}
	{
		NSButtonCell *const radicalPrototype = [[[NSButtonCell alloc] init] autorelease];
		[radicalPrototype setBezelStyle:NSShadowlessSquareBezelStyle];
		[radicalPrototype setButtonType:NSPushOnPushOffButton];
		[radicalPrototype setFont:[NSFont systemFontOfSize:18.0f]];
		[radicalPrototype setTarget:self];
		[radicalPrototype setAction:@selector(toggleRadical:)];
		[radicalView setCell:radicalPrototype];
	}
	{
		NSButtonCell *const resultPrototype = [[[NSButtonCell alloc] init] autorelease];
		[resultPrototype setBezelStyle:NSShadowlessSquareBezelStyle];
		[resultPrototype setBordered:NO];
		[resultPrototype setTarget:self];
		[resultPrototype setAction:@selector(kanjiAction:)];
		[resultView setCell:resultPrototype];
	}

	[radicalView reloadData];
	[resultView reloadData];
}

#pragma mark -<KJLineGridViewDataSource>

- (NSUInteger)numberOfLinesInLineGridView:(KJLineGridView *)sender
{
	NSParameterAssert(sender == radicalView);
	return [[[self radicalDictionary] strokeCounts] count];
}
- (NSUInteger)lineGridView:(KJLineGridView *)sender numberOfCellsInLine:(NSUInteger)line
{
	NSParameterAssert(sender == radicalView);
	return [[[self radicalDictionary] radicalsWithStrokeCount:[[[self radicalDictionary] strokeCounts] objectAtIndex:line]] count];
}
- (void)lineGridView:(KJLineGridView *)sender prepareCell:(id)cell atPosition:(KJLineGridPosition)position
{
	NSParameterAssert(sender == radicalView);
	id const strokeCount = [[[self radicalDictionary] strokeCounts] objectAtIndex:position.line];
	BOOL const header = KJHeaderIndex == position.index;
	if(header) {
		[cell setTitle:[[self radicalDictionary] stringWithStrokeCount:strokeCount]];
	} else {
		KJRadical *const radical = [[[self radicalDictionary] radicalsWithStrokeCount:strokeCount] objectAtIndex:position.index];
		[cell setRepresentedObject:radical];
		NSString *const radicalString = [radical radicalString];
		NSImage *const radicalImage = [NSImage imageNamed:radicalString];
		[radicalImage setSize:NSMakeSize(18.0f, 18.0f)];
		[cell setTitle:radicalImage ? @"" : radicalString];
		[cell setImage:radicalImage];
		[cell setState:[_selectedRadicals containsObject:radical]];
		[cell setEnabled:![_selectedRadicals count] || [[radical characterSet] KJ_intersectsWithCharacterSet:[_resultController characterSet]]];
	}
}

#pragma mark -<NSSplitViewDelegate>

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return NSMinX([splitView bounds]) + 175.0f;
}
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return NSMaxX([splitView bounds]) - 175.0f;
}
- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
	if(![radicalView isDescendantOf:view]) return YES;
	[splitView setPosition:NSWidth([view frame]) ofDividerAtIndex:0];
	return NO;
}

#pragma mark -<NSWindowDelegate>

- (void)windowWillClose:(NSNotification *)aNotif
{
	[NSApp terminate:self];
}

@end
