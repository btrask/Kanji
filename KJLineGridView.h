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
@protocol KJLineGridViewDataSource;

typedef struct {
	NSUInteger line;
	NSUInteger index;
} KJLineGridPosition;

enum {
	KJHeaderIndex = NSUIntegerMax,
};

static BOOL KJEqualPositions(KJLineGridPosition a, KJLineGridPosition b)
{
	return a.line == b.line && a.index == b.index;
}

@interface KJLineGridView : NSControl
{
	@private
	IBOutlet id<KJLineGridViewDataSource> dataSource;
	id _headerCell;
	id _editingCell;
	KJLineGridPosition _editingPosition;
}

@property(assign) id<KJLineGridViewDataSource> dataSource;

- (NSUInteger)numberOfHeaderColumns;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfLines;

- (NSUInteger)numberOfCellsInLine:(NSUInteger)line;
- (NSUInteger)numberOfRowsInLine:(NSUInteger)line;
- (NSUInteger)numberOfRowsBeforeLine:(NSUInteger)line;
- (NSUInteger)numberOfRows;

- (NSRect)frameOfLine:(NSUInteger)line;
- (NSRect)frameOfCellAtPosition:(KJLineGridPosition)position;
- (BOOL)getCellPosition:(out KJLineGridPosition *)outPosition atPoint:(NSPoint)point;
- (BOOL)getCellPosition:(out KJLineGridPosition *)outPosition atRow:(NSUInteger)targetRow column:(NSUInteger)targetCol;

@property(retain) id headerCell;
@property(readonly) id editingCell;

- (void)reloadData;

@end

@protocol KJLineGridViewDataSource <NSObject>

@required
- (NSUInteger)numberOfLinesInLineGridView:(KJLineGridView *)sender;
- (NSUInteger)lineGridView:(KJLineGridView *)sender numberOfCellsInLine:(NSUInteger)line;
- (void)lineGridView:(KJLineGridView *)sender prepareCell:(id)cell atPosition:(KJLineGridPosition)position;

@end
