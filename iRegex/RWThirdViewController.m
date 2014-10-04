//
//  RWThirdViewController.m
//  iRegex
//
//  Created by Canopus on 12/23/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import "RWThirdViewController.h"

// TODO: To be implemented from tutorial.
#define kSocialSecuityNumberPattern @"^\\d{3}[-]\\d{2}[-]\\d{4}$"


@interface RWThirdViewController() <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *SSNTextField;
@end

@implementation RWThirdViewController


#pragma mark
#pragma mark - View life cycle

- (void)viewDidLoad
{
    [self.SSNTextField becomeFirstResponder];
    
    // For convenience, if user double tapps anywhere on the view
    // we want to dismiss the keyboard
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognized:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:doubleTap];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self validateTextField:self.SSNTextField];
    
    [super viewWillAppear:animated];
}

#pragma mark
#pragma mark - IBActions

- (IBAction)doubleTapGestureRecognized:(id)sender
{
    [self.SSNTextField resignFirstResponder];
}

- (IBAction)textFieldTextDidChange:(id)sender
{
    [self validateTextField:self.SSNTextField];
}

#pragma mark
#pragma mark - UITextField delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *text = textField.text;
    NSInteger length = text.length;
    BOOL shouldReplace = YES;
    
    if (![string isEqualToString:@""])
    {
        switch (length)
        {
            case 3:
            case 6:
                textField.text = [text stringByAppendingString:@"-"];
                break;
                
            default:
                break;
        }
        if (length > 10) shouldReplace = NO;
    }
    else
    {
        switch (length) {
            case 5:
            case 8:
                textField.text = [text substringWithRange:NSMakeRange(0, length-1)];
                break;
                
            default:
                break;
        }
    }
    
    return shouldReplace;
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
    }
    else
    {
        // By default, the right view is nil. If it is nil, it means it the first time
        // we are doing validation on this field, so create an image view and put it there.
        if (!rightView)
        {
            // Create an image view that fits the right view size
            rightView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
            textField.rightView = rightView;
        }
        
        // Perform the validation
        BOOL didValidate = [self validateString:text withPattern:kSocialSecuityNumberPattern];
        
        // Base on whether it validates or not, provide a feedback in UI
        if (didValidate)
        {
            rightView.image = [UIImage imageNamed:@"checkmark.png"];
            textField.rightViewMode = UITextFieldViewModeAlways;
        }
        else
        {
            rightView.image = [UIImage imageNamed:@"exclamation.png"];
            textField.rightViewMode = UITextFieldViewModeAlways;
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
