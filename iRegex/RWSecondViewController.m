//
//  RWSecondViewController.m
//  iRegex
//
//  Created by Canopus on 12/1/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import "RWSecondViewController.h"

@interface RWSecondViewController () <UITextFieldDelegate>
@property (strong, nonatomic) NSArray *textFields;
@property (retain, nonatomic) NSArray *validations;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *middleInitialTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthTextField;
@end


@implementation RWSecondViewController

#pragma mark
#pragma mark - View life cycle

- (void)viewDidLoad
{
    // Keep an array of text field to make it
    // first responder upon tapping on next button
	self.textFields = @[self.firstNameTextField,
                        self.middleInitialTextField,
                        self.lastNameTextField,
                        self.dateOfBirthTextField,
                        ];
    
    // Array of regex to validate each field
    // TODO: To be implemented from tutorial.
    // self.validations = nil;
    self.validations = @[@"^[a-z]{1,10}$",  // First name
                         @"^[a-z]$",        // Middle initial
                         @"^[a-z']{2,10}$", // Last name
                         @"^(0[1-9]|1[012])[-/.](0[1-9]|[12][0-9]|3[01])[-/.](19|20)\\d\\d$", // Date of birth
                         ];
    // For convenience, if user double tapps anywhere on the view
    // we want to dismiss the keyboard
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognized:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:doubleTap];
    
    [super viewDidLoad];
}

#pragma mark
#pragma mark - IBActions

- (IBAction)doubleTapGestureRecognized:(id)sender
{
    [self.textFields makeObjectsPerformSelector:@selector(resignFirstResponder)];
}

#pragma mark
#pragma mark - UITextField delegates

// Called when user taps next button
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Validate
    [self validateTextField:textField];
    
    // Find the next text field to make it the first responder
    // and scroll the table view to make that text field visible
    UITextField *nextTextField = [self nextTextFieldAfterTextField:textField];
    
    // To make it visible, find the UITableViewCell that hosts
    // the text field and scroll to that
    UITableViewCell *cell = (UITableViewCell *)nextTextField.superview.superview;
    CGRect cellFrame = cell.frame;
    [self.tableView scrollRectToVisible:cellFrame animated:YES];
    
    // Make it first responder
    [nextTextField becomeFirstResponder];
    
    return YES;
}

// Called when user taps on clear button
- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    // We are going to return YES and clear out
    // but the field is not cleared yet. Because for correct validation
    // icon on the right side of the text field, we need the text field to
    // have a cleat text, so we set it manually to nil.
    textField.text = nil;
    
    // Validate
    [self validateTextField:textField];
    
    return YES;
}

// Called when user taps on a different text field and
// this text field resigns
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Validate
    [self validateTextField:textField];
}

#pragma mark
#pragma mark - Helper methods

// Return a pointer to the next text field that should become
// the next responder
- (UITextField *)nextTextFieldAfterTextField:(UITextField *)textField
{
    // Index of current text field
    NSInteger index = [self.textFields indexOfObject:textField];
    
    // Find the next textfield. If we reach the end of array
    // of text fields, go to the first one
    if (index < self.textFields.count - 1)
        index ++;
    else
        index = 0;
    
    // Return the next text field
    UITextField *nextTextField = [self.textFields objectAtIndex:index];
    return nextTextField;
}

// Trim the input string by removing leading and trailing white spaces
// and return the result
- (NSString *)stringTrimmedForLeadingAndTrailingWhiteSpacesFromString:(NSString *)string
{
    NSString *leadingTrailingWhiteSpacesPattern = @"(?:^\\s+)|(?:\\s+$)";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:leadingTrailingWhiteSpacesPattern options:NSRegularExpressionCaseInsensitive error:NULL];
    
    NSRange stringRange = NSMakeRange(0, string.length);
    NSString *trimmedString = [regex stringByReplacingMatchesInString:string options:NSMatchingReportProgress range:stringRange withTemplate:@"$1"];
    
    return trimmedString;
}

#pragma mark
#pragma mark - Validation

- (void)validateTextField:(UITextField *)textField
{
    // We don't want to do validation on empty string.
    // This is out design here. If you intend to invalidate
    // empty fields -- i.e. fields are required, you can also
    // do the validation on empty string.
    NSString *text = textField.text;
    
    // We use the right view of the text field for feedback
    UIImageView *rightView = (UIImageView *)textField.rightView;
    
    // If user completely deletes a field, we don't want to display anything
    if (!text.length)
    {
        rightView = nil;
        textField.rightViewMode = UITextFieldViewModeNever;
    }
    else
    {
        // We have a text...
        // Before we start, in our design, we want to ignore leading and trailing whitespaces,
        // so trim the text field text and remove leading and trailing whitespaces and update UI
        NSString *trimmedText = [self stringTrimmedForLeadingAndTrailingWhiteSpacesFromString:text];
        textField.text = trimmedText;
        
        // Do the validation on the trimmed text
        // First, find the index of the text field so that we can match it
        // with its validation pattern
        NSInteger index = [self.textFields indexOfObject:textField];
        
        // Get the validation pattern
        NSString *validationPattern = [self.validations objectAtIndex:index];
        
        // By default, the right view is nil. If it is nil, it means it the first time
        // we are doing validation on this field, so create an image view and put it there.
        if (!rightView)
        {
            // Create an image view that fits the right view size
            rightView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
            textField.rightView = rightView;
        }
        
        // Perform the validation
        BOOL didValidate = [self validateString:trimmedText withPattern:validationPattern];
        
        // Base on whether it validates or not, provide a feedback in UI
        if (didValidate)
        {
            rightView.image = [UIImage imageNamed:@"checkmark.png"];
            textField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
        else
        {
            rightView.image = [UIImage imageNamed:@"exclamation.png"];
            textField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
    }
}

// Validate the input string with the given pattern and
// return the result as a boolean
- (BOOL)validateString:(NSString *)string withPattern:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSAssert(regex, @"Unable to create regular expression");
    
    NSRange textRange = NSMakeRange(0, string.length);
    NSRange matchRange = [regex rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:textRange];
    
    BOOL didValidate = NO;
    
    // Did we find a matching range
    if (matchRange.location != NSNotFound)
        didValidate = YES;
    
    return didValidate;
}

@end
