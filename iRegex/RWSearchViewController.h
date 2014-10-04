//
//  RWSearchViewController.h
//  iRegex
//
//  Created by Canopus on 12/10/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


// Search options keys
// The values of these keys are BOOL
#define kRWSearchCaseSensitiveKey    @"RWSearchCaseSensitiveKey"
#define kRWSearchWholeWordsKey       @"RWSearchWholeWordsKey"
#define KRWReplacementKey            @"RWReplacementKey"

@protocol RWSearchViewControllerDelegate;


@interface RWSearchViewController : UITableViewController

@property (weak, nonatomic) id <RWSearchViewControllerDelegate> delegate;

// If you start off with a default or previous
// search string, pass it in
@property (strong, nonatomic) NSString *searchString;

@property (strong, nonatomic) NSDictionary *searchOptions;

@property (strong, nonatomic) NSString *replacementString;

@end


@protocol RWSearchViewControllerDelegate <NSObject>

// Return self, the search string and the search options and replacement string (if any)
// If there is no replacement string, it will be nil.
- (void)controller:(RWSearchViewController *)controller didFinishWithSearchString:(NSString *)string options:(NSDictionary *)options replacement:(NSString *)replacement;

@end