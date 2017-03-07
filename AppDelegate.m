//
//  AppDelegate.m
//  BrightnessMenulet
//
//  Created by Kalvin Loc on 10/10/14.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property NSStatusItem *statusItem;

@property (strong) IBOutlet MainMenuController *mainMenu;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Set Menulet Icon
    NSBundle *bundle = [NSBundle mainBundle];
    NSImage *statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon" ofType:@"png"]];
    NSImage *statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-alt" ofType:@"png"]];
    statusImage.template = YES; // Set icon as template for dark mode
    statusHighlightImage.template = YES;

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    _statusItem.image = statusImage;
    _statusItem.alternateImage = statusHighlightImage;
    _statusItem.toolTip = @"Brightness Menulet";
    _statusItem.highlightMode = YES;
    _statusItem.menu = _mainMenu;

    // init _mainMenu
    [_mainMenu refreshMenuScreens];
    _mainMenu.delegate = _mainMenu;

    lmuCon.delegate = _mainMenu;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:@"LMUUpdateInterval"])
        [defaults setFloat:0.5 forKey:@"LMUUpdateInterval"];

    if([defaults boolForKey:@"autoBrightOnStartup"])
        [lmuCon startMonitoring];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification {
    NSLog(@"AppDelegate: DidChangeScreenParameters");

    [_mainMenu refreshMenuScreens];
}

@end
