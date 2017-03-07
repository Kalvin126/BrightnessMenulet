//
//  MainMenuController.m
//  BrightnessMenulet
//
//  Created by Kalvin Loc on 10/10/14.
//
//

#import "Screen.h"

#import "MainMenuController.h"
#import "PreferencesController.h"

@interface MainMenuController ()

@property PreferencesController* preferencesController;

@property (weak) IBOutlet NSMenuItem *autoBrightnessItem;

@end

@implementation MainMenuController

- (void)refreshMenuScreens {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [controls refreshScreens];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupDisplayLabels];
        });
    });
}

- (void)setupDisplayLabels {
    while(!(self.itemArray[0].isSeparatorItem))                // Remove all current display menu items
        [self removeItemAtIndex:0];

    if([controls.screens count] == 0){
        // No screen connected, so disable outlets
        NSMenuItem* noDispItem = [[NSMenuItem alloc] init];
        noDispItem.title = @"No displays found";
        
        [self insertItem:noDispItem atIndex:0];

        if(lmuCon.monitoring)
            [lmuCon stopMonitoring];
        return;
    }

    // add new outlets for screens
    for(Screen* screen in controls.screens){
        NSString* title = [NSString stringWithFormat:@"%@", screen.model];
        NSMenuItem* scrDesc = [[NSMenuItem alloc] init];
        scrDesc.title = title;
        scrDesc.enabled = NO;

        NSSlider* slider = [[NSSlider alloc] initWithFrame:NSRectFromCGRect(CGRectMake(18, 0, 100, 20))];
        slider.target = self;
        slider.action = @selector(sliderUpdate:);
        slider.tag = screen.screenNumber;
        slider.minValue = 0;
        slider.maxValue = screen.maxBrightness;
        slider.integerValue = screen.currentBrightness;
        
        NSTextField* brightLevelLabel = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(118, 0, 30, 19))];
        brightLevelLabel.backgroundColor = [NSColor clearColor];
        brightLevelLabel.alignment = NSTextAlignmentLeft;
        [[brightLevelLabel cell] setTitle:[NSString stringWithFormat:@"%ld", (long)screen.currentBrightness]];
        [[brightLevelLabel cell] setBezeled:NO];
        
        NSMenuItem* scrSlider = [[NSMenuItem alloc] init];
        
        NSView* view = [[NSView alloc] initWithFrame:NSRectFromCGRect(CGRectMake(0, 0, 140, 20))];
        [view addSubview:slider];
        [view addSubview:brightLevelLabel];
        
        [scrSlider setView:view];
        [self insertItem:scrSlider atIndex:0];
        [self insertItem:scrDesc atIndex:0];

        [screen.brightnessOutlets addObjectsFromArray:@[ slider, brightLevelLabel ]];
    }
}

- (IBAction)toggledAutoBrightness:(NSMenuItem*)sender {
    if(sender.state == NSOffState){
        [sender setState:NSOnState];
        [lmuCon startMonitoring];
    }else{
        [sender setState:NSOffState];
        [lmuCon stopMonitoring];
    }
}

- (IBAction)preferences:(id)sender {
    if(!_preferencesController)
        _preferencesController = [[PreferencesController alloc] init];

    [_preferencesController showWindow];
}

- (void)sliderUpdate:(NSSlider*)slider {
    [[controls screenForDisplayID:slider.tag] setBrightness:[slider integerValue] byOutlet:slider];
}

- (IBAction)quit:(id)sender {
    exit(1);
}

#pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [controls refreshScreenValues];
    });
}

#pragma mark - LMUDelegate

- (void)LMUControllerDidStartMonitoring {
    [_autoBrightnessItem setState:NSOnState];
}

- (void)LMUControllerDidStopMonitoring {
    [_autoBrightnessItem setState:NSOffState];
}

@end
