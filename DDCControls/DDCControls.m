//
//  DDCControls.m
//  BrightnessMenulet
//
//  Created by Kalvin Loc on 9/17/14.
//
//

#import "DDCControls.h"

@implementation DDCControls

+ (DDCControls*)singleton {
    static dispatch_once_t pred = 0;
    static DDCControls* shared;
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}

// EDID credits to https://github.com/kfix/ddcctl
- (NSString*)EDIDString:(char*)string {
    NSString *temp = [[NSString alloc] initWithBytes:string length:13 encoding:NSASCIIStringEncoding];
    return ([temp rangeOfString:@"\n"].location != NSNotFound) ? [[temp componentsSeparatedByString:@"\n"] objectAtIndex:0] : temp;
}

- (struct DDCReadCommand)readDisplay:(CGDirectDisplayID)display_id controlValue:(int)control {
    struct DDCReadCommand read_command = (struct DDCReadCommand) { .control_id = control };

    if (!DDCRead(display_id, &read_command)) {
#ifdef DEBUG
        NSLog(@"readDisplay:%u controlValue: failed need to retry...", display_id);
#endif
    }

    return read_command;
}

- (void)changeDisplay:(CGDirectDisplayID)display_id control:(int)control withValue:(int)value {
    struct DDCWriteCommand write_command = (struct DDCWriteCommand) { .control_id = control, .new_value = value };

    if (!DDCWrite(display_id, &write_command)) {
#ifdef DEBUG
        NSLog(@"writeDisplay:%u withValue: failed need to retry...", display_id);
#endif
    }
}

- (void)refreshScreens {
    NSLog(@"DDCControls: Refreshing Screens");
    NSMutableArray* newScreens = [NSMutableArray array];
    
    for (NSScreen* screen in [NSScreen screens]) {
        // Must call unsignedIntValue to get val
        NSNumber* screenNumber = screen.deviceDescription[@"NSScreenNumber"];

        // Fetch Monitor info via EDID
        struct EDID edid = {};
        NSString* name;
        NSString* serial;
        
        if (EDIDTest([screenNumber unsignedIntValue], &edid)) {
            for (union descriptor *des = edid.descriptors; des < edid.descriptors + sizeof(edid.descriptors); des++) {
                switch (des->text.type) {
                    case 0xFF:
                        serial = [self EDIDString:des->text.data];
                        break;
                    case 0xFC:
                        name = [self EDIDString:des->text.data];
                        break;
                }
            }
        }

        // don't want to manage invalid screen or integrated LCD
        if (!name || [name isEqualToString:@"Color LCD"] || [name isEqualToString:@"iMac"])
            continue;

        // Build screen instance
        NSLog(@"DDCControls: Found %@ - %@", name, screenNumber);
        Screen* screen = [[Screen alloc] initWithModel:name screenID:[screenNumber unsignedIntValue] serial:serial];
        [screen refreshValues];

        [newScreens addObject:screen];
    }

    _screens = [newScreens copy];

    if ([newScreens count] == 0)
        NSLog(@"DDCControls: No screens found");
}

- (void)refreshScreenValues{
    [_screens makeObjectsPerformSelector:@selector(refreshValues)];
}

- (Screen*)screenForDisplayName:(NSString*)name {
    for (Screen* screen in _screens)
        if ([screen.model isEqualToString:name])
            return screen;
    
    return nil;
}

- (Screen*)screenForDisplayID:(CGDirectDisplayID)display_id {
    for (Screen* screen in _screens)
        if (screen.screenNumber == display_id)
            return screen;
    
    return nil;
}

@end
