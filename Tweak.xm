#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

@class UIKBTree;

@interface UIKeyboardLayoutStar : UIView
- (BOOL)globeKeyDisplaysAsEmojiKey;
- (BOOL)isAlphabeticPlane;
- (BOOL)showsInternationalKey;
- (BOOL)showsDedicatedEmojiKeyAlongsideGlobeButton;
- (long long)idiom;
- (void)updateGlobeKeyDisplayString;
- (void)updateMoreAndInternationalKeys;
@end

@interface UIKBTree : NSObject
- (id)firstCachedKeyWithName:(NSString *)name;
- (BOOL)boolForProperty:(NSString *)property;
- (void)setVisible:(BOOL)visible;
- (void)setOverrideDisplayString:(NSString *)string;
- (void)updateMoreAndInternationalKeysWithOptions:(int)options;
- (NSString *)name;
@end

@interface UIKeyboardImpl : NSObject
+ (instancetype)activeInstance;
@end

static id ASEKSharedInputModeController(void) {
    Class cls = NSClassFromString(@"UIKeyboardInputModeController");
    if (!cls) {
        return nil;
    }
    return [(id)cls performSelector:@selector(sharedInputModeController)];
}

static NSArray *ASEKEnabledInputModes(void) {
    id controller = ASEKSharedInputModeController();
    if (!controller) {
        return nil;
    }
    return (NSArray *)[controller performSelector:@selector(normalizedEnabledInputModeIdentifiers)];
}

static BOOL ASEKEmojiEnabled(void) {
    NSArray *enabled = ASEKEnabledInputModes();
    return enabled == nil || [enabled containsObject:@"emoji"];
}

static BOOL ASEKIsSecureTextEntry(void) {
    Class cls = NSClassFromString(@"UIKeyboardImpl");
    id impl = cls ? [(id)cls performSelector:@selector(activeInstance)] : nil;
    if (!impl) {
        return NO;
    }
    id traits = [impl performSelector:@selector(textInputTraits)];
    if (!traits) {
        return NO;
    }
    return [[traits valueForKey:@"isSecureTextEntry"] boolValue];
}

static BOOL ASEKKeyplaneAllowsEmojiKey(UIKBTree *keyplane) {
    if (!keyplane) {
        return NO;
    }
    if (![keyplane boolForProperty:@"is-alphabetic-plane"]) {
        return NO;
    }
    if (![keyplane firstCachedKeyWithName:@"International-Key"]) {
        return NO;
    }
    if ([keyplane firstCachedKeyWithName:@"Emoji-International-Key"]) {
        return NO;
    }
    if (!ASEKEmojiEnabled()) {
        return NO;
    }
    return !ASEKIsSecureTextEntry();
}

static BOOL ASEKLayoutAllowsEmojiKey(UIKeyboardLayoutStar *layout) {
    if (layout.idiom != 0) {
        return NO;
    }
    if (![layout isAlphabeticPlane]) {
        return NO;
    }
    if ([layout showsDedicatedEmojiKeyAlongsideGlobeButton]) {
        return NO;
    }
    return ASEKKeyplaneAllowsEmojiKey([layout valueForKey:@"keyplane"]);
}

static BOOL ASEKRebuildingKeyplane;

/*
 * iOS 18 builds a live TUIKeyplaneView for some layouts and a legacy
 * UIKBKeyplaneView for others. Rebuild whichever one owns the current
 * keyplane after the native merge decision has been overridden.
 */
static void ASEKRebuildKeyplaneView(UIKeyboardLayoutStar *layout) {
    if (ASEKRebuildingKeyplane) {
        return;
    }

    UIKBTree *keyplane = nil;
    @try {
        keyplane = [layout valueForKey:@"keyplane"];
    } @catch (__unused NSException *exception) {
        return;
    }
    if (!ASEKKeyplaneAllowsEmojiKey(keyplane)) {
        return;
    }

    ASEKRebuildingKeyplane = YES;

    id liveView = nil;
    @try {
        liveView = [layout valueForKey:@"liveKeyplaneView"];
    } @catch (__unused NSException *exception) {
    }

    BOOL rebuilt = NO;

    if (liveView && [liveView respondsToSelector:@selector(resetLayoutAndApplyKeyplane:)]) {
        Class keyplaneClass = NSClassFromString(@"TUIKeyplane");
        id tuiKeyplane = nil;
        if (keyplaneClass && [keyplaneClass respondsToSelector:@selector(keyplaneFromKBTree:)]) {
            tuiKeyplane = [keyplaneClass performSelector:@selector(keyplaneFromKBTree:)
                                              withObject:keyplane];
        }
        if (tuiKeyplane) {
            [liveView performSelector:@selector(resetLayoutAndApplyKeyplane:)
                           withObject:tuiKeyplane];
            rebuilt = YES;
        }
    }

    if (!rebuilt && liveView && [liveView respondsToSelector:@selector(setKeyplane:)]) {
        [liveView performSelector:@selector(setKeyplane:) withObject:keyplane];
        rebuilt = YES;
    }

    if (!rebuilt) {
        id legacyView = nil;
        @try {
            legacyView = [layout valueForKey:@"keyplaneView"];
        } @catch (__unused NSException *exception) {
        }
        if (legacyView && [legacyView respondsToSelector:@selector(setKeyplane:)]) {
            [legacyView performSelector:@selector(setKeyplane:) withObject:keyplane];
        }
    }

    [layout setNeedsLayout];
    [layout setNeedsDisplay];

    ASEKRebuildingKeyplane = NO;
}

static BOOL (*ASEKOrigGlobe)(id, SEL);
static BOOL (*ASEKOrigShowsInternational)(id, SEL);
static void (*ASEKOrigGlobeDisplay)(id, SEL);
static void (*ASEKOrigUpdateMoreLayout)(id, SEL);
static void (*ASEKOrigUpdateMoreTree)(id, SEL, int);
static BOOL (*ASEKOrigShouldMergeKey)(id, SEL, id);

static BOOL ASEKHookedShouldMergeKey(id self, SEL _cmd, id key) {
    if (key && [key respondsToSelector:@selector(name)]) {
        NSString *name = [key name];
        if ([name isEqualToString:@"International-Key"] ||
            [name isEqualToString:@"Emoji-International-Key"]) {
            if (ASEKEmojiEnabled() && !ASEKIsSecureTextEntry()) {
                return NO;
            }
        }
    }
    return ASEKOrigShouldMergeKey ? ASEKOrigShouldMergeKey(self, _cmd, key) : NO;
}

static BOOL ASEKHookedGlobe(id self, SEL _cmd) {
    BOOL original = ASEKOrigGlobe ? ASEKOrigGlobe(self, _cmd) : NO;
    return ASEKLayoutAllowsEmojiKey((UIKeyboardLayoutStar *)self) ? YES : original;
}

static BOOL ASEKHookedShowsInternational(id self, SEL _cmd) {
    BOOL original = ASEKOrigShowsInternational ? ASEKOrigShowsInternational(self, _cmd) : NO;

    if (ASEKLayoutAllowsEmojiKey((UIKeyboardLayoutStar *)self)) {
        MSHookIvar<BOOL>((UIKeyboardLayoutStar *)self, "_showIntlKey") = YES;

        UIKBTree *keyplane = [self valueForKey:@"keyplane"];
        UIKBTree *key = [keyplane firstCachedKeyWithName:@"International-Key"];
        if (key) {
            [key setVisible:YES];
            [key setOverrideDisplayString:@"emoji"];
        }
        return YES;
    }

    return original;
}

static void ASEKHookedUpdateMoreLayout(id self, SEL _cmd) {
    if (ASEKOrigUpdateMoreLayout) {
        ASEKOrigUpdateMoreLayout(self, _cmd);
    }

    UIKeyboardLayoutStar *layout = (UIKeyboardLayoutStar *)self;
    if (!ASEKLayoutAllowsEmojiKey(layout)) {
        return;
    }

    MSHookIvar<BOOL>(layout, "_showIntlKey") = YES;

    UIKBTree *keyplane = [layout valueForKey:@"keyplane"];
    UIKBTree *key = [keyplane firstCachedKeyWithName:@"International-Key"];
    if (key) {
        [key setVisible:YES];
        [key setOverrideDisplayString:@"emoji"];
    }

    if ([keyplane respondsToSelector:@selector(updateMoreAndInternationalKeysWithOptions:)]) {
        [keyplane updateMoreAndInternationalKeysWithOptions:1];
    }

    ASEKRebuildKeyplaneView(layout);
}

static void ASEKHookedUpdateMoreTree(id self, SEL _cmd, int options) {
    if (ASEKKeyplaneAllowsEmojiKey((UIKBTree *)self)) {
        options |= 1;
    }
    if (ASEKOrigUpdateMoreTree) {
        ASEKOrigUpdateMoreTree(self, _cmd, options);
    }
}

static void ASEKHookedGlobeDisplay(id self, SEL _cmd) {
    if (ASEKOrigGlobeDisplay) {
        ASEKOrigGlobeDisplay(self, _cmd);
    }

    UIKeyboardLayoutStar *layout = (UIKeyboardLayoutStar *)self;
    if (!ASEKLayoutAllowsEmojiKey(layout)) {
        return;
    }

    UIKBTree *keyplane = [layout valueForKey:@"keyplane"];
    UIKBTree *key = [keyplane firstCachedKeyWithName:@"International-Key"];
    if (!key) {
        return;
    }
    [key setOverrideDisplayString:@"emoji"];
    [key setVisible:YES];
}

static void ASEKInstallHooks(void) {
    static BOOL installed;
    static int attempts;

    if (installed) {
        return;
    }

    Class layoutClass = NSClassFromString(@"UIKeyboardLayoutStar");
    Class treeClass = NSClassFromString(@"UIKBTree");
    if (!layoutClass || !treeClass) {
        attempts++;
        if (attempts < 200) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                           dispatch_get_main_queue(), ^{
                ASEKInstallHooks();
            });
        }
        return;
    }

    installed = YES;

    MSHookMessageEx(layoutClass, @selector(globeKeyDisplaysAsEmojiKey),
                    (IMP)ASEKHookedGlobe, (IMP *)&ASEKOrigGlobe);
    MSHookMessageEx(layoutClass, @selector(showsInternationalKey),
                    (IMP)ASEKHookedShowsInternational, (IMP *)&ASEKOrigShowsInternational);
    MSHookMessageEx(layoutClass, @selector(updateGlobeKeyDisplayString),
                    (IMP)ASEKHookedGlobeDisplay, (IMP *)&ASEKOrigGlobeDisplay);
    MSHookMessageEx(layoutClass, @selector(updateMoreAndInternationalKeys),
                    (IMP)ASEKHookedUpdateMoreLayout, (IMP *)&ASEKOrigUpdateMoreLayout);
    MSHookMessageEx(layoutClass, @selector(shouldMergeKey:),
                    (IMP)ASEKHookedShouldMergeKey, (IMP *)&ASEKOrigShouldMergeKey);
    MSHookMessageEx(treeClass, @selector(updateMoreAndInternationalKeysWithOptions:),
                    (IMP)ASEKHookedUpdateMoreTree, (IMP *)&ASEKOrigUpdateMoreTree);
}

%ctor {
    ASEKInstallHooks();
    for (int i = 0; i < 100; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                       dispatch_get_main_queue(), ^{
            ASEKInstallHooks();
        });
    }
}
