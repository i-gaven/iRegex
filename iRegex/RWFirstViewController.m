//
//  RWFirstViewController.m
//  iRegex
//
//  Created by Canopus on 12/1/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//


#import "RWFirstViewController.h"

@interface RWFirstViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButton;
@property (strong, nonatomic) NSString *lastSearchString;
@property (strong, nonatomic) NSString *lastReplacementString;
@property (strong, nonatomic) NSDictionary *lastSearchOptions;
@end


@implementation RWFirstViewController


#pragma mark
#pragma mark - View life cycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = segue.identifier;
    if ([segueIdentifier isEqualToString:@"RWSearchViewControllerSegue"])
    {
        UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
        RWSearchViewController *controller = [navigationController.viewControllers objectAtIndex:0];
        controller.delegate = self;
        controller.searchString = self.lastSearchString;
        controller.searchOptions = self.lastSearchOptions;
        controller.replacementString = self.lastReplacementString;
    }
}

#pragma mark
#pragma mark - IBActions

- (IBAction)findInterestingData:(id)sender
{
    [self underlineAllDates];
    [self underlineAllTimes];
    [self underlineAllLocations];
}

#pragma mark
#pragma mark - RWSearchViewController delegate

- (void)controller:(RWSearchViewController *)controller didFinishWithSearchString:(NSString *)string options:(NSDictionary *)options replacement:(NSString *)replacement
{
    if (![string isEqualToString:self.lastSearchString] ||
        ![options isEqual:self.lastSearchOptions] ||
        ![replacement isEqualToString:self.lastReplacementString])
    {
        // Keep a reference
        self.lastSearchString = string;
        self.lastReplacementString = replacement;
        self.lastSearchOptions = options;
        
        // Do a clean up of the last time. Remove all the highlights
        [self removeAllHighlightedTextInTextView:self.textView];
        
        if (replacement)
            // Start search and replace
            [self searchAndReplaceText:string withText:replacement inTextView:self.textView options:options];
        else
            // Start the search
            [self searchText:string inTextView:self.textView options:options];
    }
}

#pragma mark
#pragma mark - Manage search to find and replace

// Search for a searchString in the given text view with search options
- (void)searchText:(NSString *)searchString inTextView:(UITextView *)textView options:(NSDictionary *)options
{
    // 1: Range of visible text
    NSRange visibleRange = [self visibleRangeOfTextView:self.textView];
    
    // 2: Get a mutable sub-range of attributed string of the text view that is visible
    NSMutableAttributedString *visibleAttributedText = [textView.attributedText attributedSubstringFromRange:visibleRange].mutableCopy;
    
    // Get the string of the attributed text
    NSString *visibleText = visibleAttributedText.string;
    
    // 3: Create a new range for the visible text. This is different
    // from visibleRange. VisibleRange is a portion of all textView that is visible, but
    // visibileTextRange is only for visibleText, so it starts at 0 and its length is
    // the length of visibleText
    NSRange visibleTextRange = NSMakeRange(0, visibleText.length);
    
    // 4: Call the convenient method to create a regex for us with the options we have
    NSRegularExpression *regex = [self regularExpressionWithString:searchString options:options];
    
    // 5: Find matches
    NSArray *matches = [regex matchesInString:visibleText options:NSMatchingProgress range:visibleTextRange];
    
    // 6: Iterate through the matches and highlight them
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        [visibleAttributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:matchRange];
    }
    
    // 7: Replace the range of the attributed string that we just highlighted
    // First, create a CFRange from the NSRange of the visible range
    CFRange visibleRange_CF = CFRangeMake(visibleRange.location, visibleRange.length);
    
    // Get a mutable copy of the attributed text of the text view
    NSMutableAttributedString *textViewAttributedString = self.textView.attributedText.mutableCopy;
    
    // Replace the visible range
    CFAttributedStringReplaceAttributedString((__bridge CFMutableAttributedStringRef)(textViewAttributedString), visibleRange_CF, (__bridge CFAttributedStringRef)(visibleAttributedText));
    
    // 8: Update UI
    textView.attributedText = textViewAttributedString;
}

// Search for a searchString and replace it with the replacementString in the given text view with search options
- (void)searchAndReplaceText:(NSString *)searchString withText:(NSString *)replacementString inTextView:(UITextView *)textView options:(NSDictionary *)options
{
    // Text before replacement
    NSString *beforeText = textView.text;
    
    // Create a range for it. We do the replacement on the whole
    // range of the text view, not only a portion of it.
    NSRange range = NSMakeRange(0, beforeText.length);
    
    // Call the convenient method to create a regex for us with the options we have
    NSRegularExpression *regex = [self regularExpressionWithString:searchString options:options];
    
    // Call the NSRegularExpression method to do the replacement for us
    NSString *afterText = [regex stringByReplacingMatchesInString:beforeText options:0 range:range withTemplate:replacementString];
    
    // Update UI
    textView.text = afterText;
}

#pragma mark
#pragma mark - Helper methods

// Create a regular expression with given string and options
- (NSRegularExpression *)regularExpressionWithString:(NSString *)string options:(NSDictionary *)options
{
    // Create a regular expression
    BOOL isCaseSensitive = [[options objectForKey:kRWSearchCaseSensitiveKey] boolValue];
    BOOL isWholeWords = [[options objectForKey:kRWSearchWholeWordsKey] boolValue];
    
    NSError *error = NULL;
    NSRegularExpressionOptions regexOptions = isCaseSensitive ? 0 : NSRegularExpressionCaseInsensitive;
    
    NSString *placeholder = isWholeWords ? @"\\b%@\\b" : @"%@";
    NSString *pattern = [NSString stringWithFormat:placeholder, string];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:regexOptions error:&error];
    if (error)
    {
        NSLog(@"Couldn't create regex with given string and options");
    }
    
    return regex;
}

// Return range of text in text view that is visible
- (NSRange)visibleRangeOfTextView:(UITextView *)textView
{
    CGRect bounds = textView.bounds;
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    NSRange visibleRange = NSMakeRange([textView offsetFromPosition:textView.beginningOfDocument toPosition:start],
                                       [textView offsetFromPosition:start toPosition:end]);
    return visibleRange;
}

// Compare the two ranges and return YES if range1 contains range2
bool NSRangeContainsRange (NSRange range1, NSRange range2)
{
    BOOL contains = NO;
    if (range1.location < range2.location && range1.location+range1.length > range2.length+range2.location)
    {
        contains = YES;
    }
    return contains;
}

// Remove all highlighted text (the background color) of NSAttributedString
// in a given UITextView
- (void)removeAllHighlightedTextInTextView:(UITextView *)textView
{
    NSMutableAttributedString *mutableAttributedString = self.textView.attributedText.mutableCopy;
    NSRange wholeRange = NSMakeRange(0, mutableAttributedString.length);
    [mutableAttributedString addAttribute:NSBackgroundColorAttributeName value:[UIColor clearColor] range:wholeRange];
    textView.attributedText = mutableAttributedString.copy;
}

#pragma mark
#pragma mark - Find interesting data

- (void)underlineAllDates
{
    NSError *error = NULL;
    NSString *pattern = @"(\\d{1,2}[-/.]\\d{1,2}[-/.]\\d{1,2})|(Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)\\s*\\d{1,2}(st|nd|rd|th)?+[,]\\s*\\d{4}";
    NSString *string = self.textView.text;
    NSRange range = NSMakeRange(0, string.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:NSMatchingProgress range:range];
    [self highlightMatches:matches];
}

- (void)underlineAllTimes
{
    NSError *error = NULL;
    NSString *pattern = @"\\d{1,2}\\s*(pm|am)";
    NSString *string = self.textView.text;
    NSRange range = NSMakeRange(0, string.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:NSMatchingProgress range:range];
    [self highlightMatches:matches];
}

- (void)underlineAllLocations
{
    NSError *error = NULL;
    NSString *pattern = @"[a-zA-Z]+[,]\\s*([A-Z]{2})";
    NSString *string = self.textView.text;
    NSRange range = NSMakeRange(0, string.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [regex matchesInString:string options:NSMatchingProgress range:range];
    [self highlightMatches:matches];
}

// Matches is an array with object of type NSTextCheckingResult
- (void)highlightMatches:(NSArray *)matches
{
    __block NSMutableAttributedString *mutableAttributedString = self.textView.attributedText.mutableCopy;
    
    [matches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[NSTextCheckingResult class]])
        {
            NSTextCheckingResult *match = (NSTextCheckingResult *)obj;
            NSRange matchRange = match.range;
            [mutableAttributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:matchRange];
            [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:matchRange];
        }
    }];
    
    self.textView.attributedText = mutableAttributedString.copy;
}

// Called when the user finishes scrolling the content
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (CGPointEqualToPoint(velocity, CGPointZero))
    {
        if (self.lastSearchString && self.lastSearchOptions && !self.lastReplacementString)
            [self searchText:self.lastSearchString inTextView:self.textView options:self.lastSearchOptions];
    }
}

// Called when the scroll view has ended decelerating the scrolling movement
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.lastSearchString && self.lastSearchOptions && !self.lastReplacementString)
        [self searchText:self.lastSearchString inTextView:self.textView options:self.lastSearchOptions];
}

@end
