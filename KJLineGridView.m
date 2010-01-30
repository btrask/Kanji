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
#import "KJLineGridView.h"

#define KJCellSize 30.0f
#define KJCellPadding 1.0f

@interface KJLineGridView(Private)

- (NSCell *)_cellAtPosition:(KJLineGridPosition)position;
- (NSCell *)_preparedCellAtPosition:(KJLineGridPosition)position;
- (void)_drawCellAtPosition:(KJLineGridPosition)position;

@end

@implementation KJLineGridView

#pragma mark -KJLineGridView

@synthesize dataSource;

#pragma mark -

- (NSUInteger)numberOfHeaderColumns
{
	return [self headerCell] ? 1 : 0;
}
- (NSUInteger)numberOfColumns
{
	NSUInteger const headerColumns = [self numberOfHeaderColumns];
	return MAX(1 + headerColumns, (NSUInteger)floor(NSWidth([self frame]) / KJCellSize)) - headerColumns;
}
- (NSUInteger)numberOfLines
{
	return [[self dataSource] numberOfLinesInLineGridView:self];
}

#pragma mark -

- (NSUInteger)numberOfCellsInLine:(NSUInteger)line
{
	NSParameterAssert(line < [self numberOfLines]);
	return [[self dataSource] lineGridView:self numberOfCellsInLine:line];
}
- (NSUInteger)numberOfRowsInLine:(NSUInteger)line
{
	return (NSUInteger)ceil((CGFloat)[self numberOfCellsInLine:line] / [self numberOfColumns]);
}
- (NSUInteger)numberOfRowsBeforeLine:(NSUInteger)line
{
	NSUInteger i = 0, rows = 0;
	for(; i < line; i++) rows += [self numberOfRowsInLine:i];
	return rows;
}
- (NSUInteger)numberOfRows
{
	return [self numberOfRowsBeforeLine:[self numberOfLines]];
}

#pragma mark -

- (NSRect)frameOfLine:(NSUInteger)line
{
	NSRect const b = [self bounds];
	return NSMakeRect(
		NSMinX(b),
		NSMinY(b) + [self numberOfRowsBeforeLine:line] * KJCellSize,
		NSWidth(b),
		[self numberOfRowsInLine:line] * KJCellSize
	);
}
- (NSRect)frameOfHeaderCellForLine:(NSUInteger)line
{
	NSRect const b = [self bounds];
	return NSMakeRect(
		NSMinX(b),
		NSMinY(b) + [self numberOfRowsBeforeLine:line] * KJCellSize,
		KJCellSize,
		KJCellSize
	);
}
- (NSRect)frameOfCellAtPosition:(KJLineGridPosition)position
{
	NSRect const b = [self bounds];
	NSUInteger x = 0, y = 0;
	if(KJHeaderIndex != position.index) {
		x = position.index % [self numberOfColumns] + [self numberOfHeaderColumns];
		y = position.index / [self numberOfColumns];
	}
	return NSInsetRect(NSMakeRect(
		NSMinX(b) + x * KJCellSize,
		NSMinY(b) + [self numberOfRowsBeforeLine:position.line] * KJCellSize + y * KJCellSize,
		KJCellSize,
		KJCellSize
	), KJCellPadding, KJCellPadding);
}
- (BOOL)getCellPosition:(out KJLineGridPosition *)outPosition atPoint:(NSPoint)point
{
	NSRect const b = [self bounds];
	CGFloat const minX = NSMinX(b) + [self numberOfHeaderColumns] * KJCellSize;
	if(point.x < minX) return NO;
	KJLineGridPosition pos;
	if(![self getCellPosition:&pos atRow:(point.y - NSMinY(b)) / KJCellSize column:(point.x - minX) / KJCellSize]) return NO;
	if(![self mouse:point inRect:[self frameOfCellAtPosition:pos]]) return NO;
	if(outPosition) *outPosition = pos;
	return YES;
}
- (BOOL)getCellPosition:(out KJLineGridPosition *)outPosition atRow:(NSUInteger)targetRow column:(NSUInteger)targetCol
{
	if(targetCol >= [self numberOfColumns]) return NO;
	NSUInteger line = 0, remainingRows = targetRow;
	for(;; line++) {
		if(line >= [self numberOfLines]) return NO;
		NSUInteger const rowsInLine = [self numberOfRowsInLine:line];
		if(rowsInLine > remainingRows) break;
		remainingRows -= rowsInLine;
	}
	NSUInteger const index = remainingRows * [self numberOfColumns] + targetCol;
	if(index >= [self numberOfCellsInLine:line]) return NO;
	if(outPosition) *outPosition = (KJLineGridPosition){line, index};
	return YES;
}

#pragma mark -

@synthesize headerCell = _headerCell;
@synthesize editingCell = _editingCell;

#pragma mark -

- (void)reloadData
{
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

#pragma mark -KJLineGridView(Private)

- (NSCell *)_cellAtPosition:(KJLineGridPosition)position
{
	if(KJHeaderIndex == position.index) return [self headerCell];
	if(_editingCell && KJEqualPositions(position, _editingPosition)) return _editingCell;
	return [self cell];
}
- (NSCell *)_preparedCellAtPosition:(KJLineGridPosition)position
{
	NSCell *const cell = [self _cellAtPosition:position];
	[[self dataSource] lineGridView:self prepareCell:cell atPosition:position];
	return cell;
}
- (void)_drawCellAtPosition:(KJLineGridPosition)position
{
	NSRect const frame = [self frameOfCellAtPosition:position];
	if([self needsToDrawRect:frame]) [[self _preparedCellAtPosition:position] drawWithFrame:frame inView:self];
}

#pragma mark -NSControl

- (void)sizeToFit
{
	NSSize const s = [self frame].size;
	[self setFrameSize:NSMakeSize(s.width, [self numberOfRows] * KJCellSize)];
}

#pragma mark -NSView

- (BOOL)isFlipped
{
	return YES;
}
- (void)drawRect:(NSRect)aRect
{
	NSUInteger line = 0;
	for(; line < [self numberOfLines]; line++) {
		if([self headerCell]) [self _drawCellAtPosition:(KJLineGridPosition){line, KJHeaderIndex}];
		NSUInteger index = 0;
		for(; index < [self numberOfCellsInLine:line]; index++) [self _drawCellAtPosition:(KJLineGridPosition){line, index}];
	}
}
- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
	[super resizeWithOldSuperviewSize:oldSize];
	[self sizeToFit];
}

#pragma mark -NSResponder

- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (void)mouseDown:(NSEvent *)firstEvent
{
	[[self window] makeFirstResponder:self];
	if(![self getCellPosition:&_editingPosition atPoint:[self convertPoint:[firstEvent locationInWindow] fromView:nil]]) return;
	_editingCell = [[[self _preparedCellAtPosition:_editingPosition] copy] autorelease];
	NSRect const frame = [self frameOfCellAtPosition:_editingPosition];
	if([[_editingCell class] prefersTrackingUntilMouseUp]) {
		[_editingCell trackMouse:firstEvent inRect:frame ofView:self untilMouseUp:YES];
		_editingCell = nil;
		return;
	}
	NSEvent *latestEvent = firstEvent;
	do {
		if([self mouse:[self convertPoint:[latestEvent locationInWindow] fromView:nil] inRect:frame]) {
			[_editingCell highlight:YES withFrame:frame inView:self];
			if([_editingCell trackMouse:latestEvent inRect:frame ofView:self untilMouseUp:NO]) break;
			[_editingCell highlight:NO withFrame:frame inView:self];
		}
		latestEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
	} while([latestEvent type] != NSLeftMouseUp);
	[[self window] discardEventsMatchingMask:NSAnyEventMask beforeEvent:latestEvent];
	[_editingCell highlight:NO withFrame:frame inView:self];
	_editingCell = nil;
}

#pragma mark -NSObject

- (void)dealloc
{
	[_headerCell release];
	[super dealloc];
}

#pragma mark -NSObject(NSNibAwaking)

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self sizeToFit];
}

@end
