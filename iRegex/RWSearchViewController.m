//
//  RWSearchViewController.m
//  iRegex
//
//  Created by Canopus on 12/10/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import "RWSearchViewController.h"


@interface RWSearchViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UITextField *replaceTextField;
@property (weak, nonatomic) IBOutlet UISwitch *replaceSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *caseSensitiveSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *wholeWordsSwitch;
@property (strong, nonatomic) NSMutableDictionary *options;
@end


@implementation RWSearchViewController

#pragma mark
#pragma mark - View life cycle

- (void)viewDidLoad
{
    self.searchTextField.text = self.searchString;
    if (!self.searchString)
    {
        // Pop the keyboard if there is no previous search string
        [self.searchTextField becomeFirstResponder];
    }
    
    if (self.searchOptions)
    {
        // Adjust based on the last search options
        self.options = self.searchOptions.mutableCopy;
        self.replaceTextField.text = self.replacementString;
        
        BOOL isCaseSensitive = [[self.options objectForKey:kRWSearchCaseSensitiveKey] boolValue];
        [self.caseSensitiveSwitch setOn:isCaseSensitive];
        
        BOOL isWholeWords = [[self.options objectForKey:kRWSearchWholeWordsKey] boolValue];
        [self.wholeWordsSwitch setOn:isWholeWords];
        
        BOOL isReplace = [[self.options objectForKey:KRWReplacementKey] boolValue];
        [self.replaceSwitch setOn:isReplace];
        self.replaceTextField.enabled = isReplace;
    }
    else
    {
        // Initialize the options dictonary
        self.options = [NSMutableDictionary dictionary];
        
        // Give it the default values
        NSNumber *isCaseSensitive = [NSNumber numberWithBool:self.caseSensitiveSwitch.isOn];
        [self.options setObject:isCaseSensitive forKey:kRWSearchCaseSensitiveKey];
        
        NSNumber *isMatchWord = [NSNumber numberWithBool:self.wholeWordsSwitch.isOn];
        [self.options setObject:isMatchWord forKey:kRWSearchWholeWordsKey];
        
        NSNumber *isReplace = [NSNumber numberWithBool:self.replaceSwitch.isOn];
        [self.options setObject:isReplace forKey:KRWReplacementKey];
        self.replaceTextField.enabled = isReplace.boolValue;
    }
    
    // Dismiss the keyboard if user double taps on the background
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimissKeyboard:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:doubleTap];
    
    [super viewDidLoad];
}

#pragma mark
#pragma mark - IBActions

- (IBAction)closeButtonTapped:(id)sender
{
    // Dismiss the view controller
    [self dismissViewControllerAnimated:YES completion:^{
        
        // Notify the delegate
        if (self.searchString && self.searchOptions)
            [self.delegate controller:self didFinishWithSearchString:self.searchString options:self.searchOptions replacement:self.replacementString];
        
    }];
}

- (IBAction)searchButtonTapped:(id)sender
{
    self.searchString = self.searchTextField.text;
    
    if (self.replaceTextField.enabled)
        self.replacementString = self.replaceTextField.text;
    
    self.searchOptions = self.options.copy;
    [self closeButtonTapped:nil];
}

// By default search is case insensitive. If the switch is
// on, search is case sensitive.
- (IBAction)caseSensitiveSearchSwitchToggled:(id)sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    NSNumber *isCaseSensitive = [NSNumber numberWithBool:theSwitch.isOn];
    [self.options setObject:isCaseSensitive forKey:kRWSearchCaseSensitiveKey];
}

- (IBAction)wholeWordsSwitchToggled:(id)sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    NSNumber *isMatchWord = [NSNumber numberWithBool:theSwitch.isOn];
    [self.options setObject:isMatchWord forKey:kRWSearchWholeWordsKey];
}

- (IBAction)replaceSwitchToggled:(id)sender
{
    UISwitch *theSwitch = (UISwitch *)sender;
    NSNumber *isReplace = [NSNumber numberWithBool:theSwitch.isOn];
    [self.options setObject:isReplace forKey:KRWReplacementKey];
    
    self.replaceTextField.enabled = theSwitch.isOn;
    
    // When user turns off the replacement string, and there is value
    // in self.replacementString, we don't want to pass it back to the
    // delegate.
    if (!theSwitch.isOn)
    {
        self.replacementString = nil;
        self.replaceTextField.text = nil;
    }
}

- (IBAction)dimissKeyboard:(id)sender
{
    [self.searchTextField resignFirstResponder];
}

#pragma mark
#pragma mark - UITextField delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.searchTextField])
        self.searchString = textField.text;
    else if ([textField isEqual:self.replaceTextField])
        self.replacementString = textField.text;
    
    // Dismiss the keyboard
    [textField resignFirstResponder];
    
    return YES;
}

@end
