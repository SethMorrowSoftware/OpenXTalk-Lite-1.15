# macOS Modern UI Theme - Code Implementation
## Complete Code Changes with File Locations

**Last Updated**: October 12, 2025  
**Related**: macos-modern-ui-theme-overview.md

---

## File 1: engine/src/osxtheme.mm

### Location: Top of file (after includes, around line 40)

**Add new helper functions for appearance and cell caching:**

```objc
// ============================================================================
// MODERN THEME SUPPORT (macOS 10.14+)
// ============================================================================

// Cache for NSButtonCell instances
static NSMutableDictionary<NSNumber*, NSButtonCell*>* s_button_cell_cache = nil;
static NSMutableDictionary<NSNumber*, NSScroller*>* s_scroller_cache = nil;

// Appearance state cache
static NSAppearance* s_cached_appearance = nil;
static BOOL s_is_dark_mode = NO;
static NSInteger s_appearance_generation = 0;

// Get current system appearance (dark/light mode)
static NSAppearance* get_effective_appearance()
{
    NSString* t_appearance_name = [[NSUserDefaults standardUserDefaults] 
        stringForKey:@"AppleInterfaceStyle"];
    
    if ([t_appearance_name isEqualToString:@"Dark"])
        return [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    else
        return [NSAppearance appearanceNamed:NSAppearanceNameAqua];
}

// Update appearance cache (only when system changes)
static void update_appearance_cache()
{
    NSInteger t_current_gen = [NSApp effectiveAppearance].hash;
    
    if (t_current_gen != s_appearance_generation)
    {
        s_appearance_generation = t_current_gen;
        
        NSString* t_style = [[NSUserDefaults standardUserDefaults] 
            stringForKey:@"AppleInterfaceStyle"];
        s_is_dark_mode = [t_style isEqualToString:@"Dark"];
        
        s_cached_appearance = get_effective_appearance();
    }
}

// Configure NSButtonCell based on HITheme button kind
static void configure_button_cell(NSButtonCell* p_cell, ThemeButtonKind p_kind)
{
    switch (p_kind)
    {
        case kThemePushButton:
            [p_cell setBezelStyle:NSBezelStyleRounded];
            [p_cell setButtonType:NSButtonTypeMomentaryPushIn];
            break;
            
        case kThemeBevelButton:
            [p_cell setBezelStyle:NSBezelStyleRegularSquare];
            [p_cell setButtonType:NSButtonTypeMomentaryPushIn];
            break;
            
        case kThemePopupButton:
            [p_cell setBezelStyle:NSBezelStyleRounded];
            [p_cell setButtonType:NSButtonTypeMomentaryPushIn];
            // Note: Popup indicator handled separately
            break;
            
        case kThemeCheckBox:
            [p_cell setButtonType:NSButtonTypeSwitch];
            break;
            
        case kThemeRadioButton:
            [p_cell setButtonType:NSButtonTypeRadio];
            break;
            
        case kThemeComboBox:
            [p_cell setBezelStyle:NSBezelStyleRounded];
            [p_cell setButtonType:NSButtonTypeMomentaryPushIn];
            break;
            
        default:
            [p_cell setBezelStyle:NSBezelStyleRounded];
            [p_cell setButtonType:NSButtonTypeMomentaryPushIn];
            break;
    }
}

// Get cached button cell (creates if needed)
static NSButtonCell* get_cached_button_cell(ThemeButtonKind p_kind)
{
    if (s_button_cell_cache == nil)
        s_button_cell_cache = [[NSMutableDictionary alloc] init];
    
    NSNumber* t_key = @(p_kind);
    NSButtonCell* t_cell = [s_button_cell_cache objectForKey:t_key];
    
    if (t_cell == nil)
    {
        t_cell = [[NSButtonCell alloc] init];
        configure_button_cell(t_cell, p_kind);
        [s_button_cell_cache setObject:t_cell forKey:t_key];
    }
    
    return t_cell;
}

// Draw button using modern NSButtonCell
static void draw_modern_button(MCThemeDrawInfo& p_info, CGContextRef p_context)
{
    NSButtonCell* t_cell = get_cached_button_cell(p_info.button.info.kind);
    
    // Set cell state
    [t_cell setEnabled:p_info.button.info.state != kThemeStateInactive];
    [t_cell setHighlighted:p_info.button.info.state == kThemeStatePressed];
    [t_cell setState:p_info.button.info.value == kThemeButtonOn ? 
                     NSControlStateValueOn : NSControlStateValueOff];
    
    // Handle default button adornment
    if (p_info.button.info.adornment == kThemeAdornmentDefault)
        [t_cell setKeyEquivalent:@"\r"]; // Makes it default button
    else
        [t_cell setKeyEquivalent:@""];
    
    // Create NSGraphicsContext from CGContext
    NSGraphicsContext* t_ns_context = [NSGraphicsContext 
        graphicsContextWithCGContext:p_context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:t_ns_context];
    
    // Convert HIRect to NSRect
    NSRect t_rect = NSMakeRect(p_info.button.bounds.origin.x,
                               p_info.button.bounds.origin.y,
                               p_info.button.bounds.size.width,
                               p_info.button.bounds.size.height);
    
    // Draw the button
    [t_cell drawWithFrame:t_rect inView:nil];
    
    [NSGraphicsContext restoreGraphicsState];
}

// Draw scrollbar using modern NSScroller
static void draw_modern_scrollbar(MCThemeDrawInfo& p_info, CGContextRef p_context)
{
    // Get or create cached scroller
    if (s_scroller_cache == nil)
        s_scroller_cache = [[NSMutableDictionary alloc] init];
    
    NSNumber* t_key = @(p_info.scrollbar.horizontal ? 1 : 0);
    NSScroller* t_scroller = [s_scroller_cache objectForKey:t_key];
    
    if (t_scroller == nil)
    {
        t_scroller = [[NSScroller alloc] init];
        [t_scroller setScrollerStyle:NSScrollerStyleLegacy]; // Or NSScrollerStyleOverlay
        [s_scroller_cache setObject:t_scroller forKey:t_key];
    }
    
    // Configure scroller
    CGFloat t_knob_proportion = 
        (CGFloat)p_info.scrollbar.info.trackInfo.scrollbar.viewsize / 
        (CGFloat)p_info.scrollbar.info.max;
    [t_scroller setKnobProportion:t_knob_proportion];
    
    CGFloat t_knob_position = 
        (CGFloat)p_info.scrollbar.info.value / 
        (CGFloat)p_info.scrollbar.info.max;
    [t_scroller setDoubleValue:t_knob_position];
    
    [t_scroller setEnabled:p_info.scrollbar.info.enableState == kThemeTrackActive];
    
    // Create NSGraphicsContext
    NSGraphicsContext* t_ns_context = [NSGraphicsContext 
        graphicsContextWithCGContext:p_context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:t_ns_context];
    
    NSRect t_rect = NSMakeRect(p_info.scrollbar.info.bounds.origin.x,
                               p_info.scrollbar.info.bounds.origin.y,
                               p_info.scrollbar.info.bounds.size.width,
                               p_info.scrollbar.info.bounds.size.height);
    
    [t_scroller drawKnobSlotInRect:t_rect highlight:NO];
    [t_scroller drawKnob];
    
    [NSGraphicsContext restoreGraphicsState];
}

// Draw progress bar using direct CoreGraphics (simple and fast)
static void draw_modern_progress(MCThemeDrawInfo& p_info, CGContextRef p_context)
{
    NSGraphicsContext* t_ns_context = [NSGraphicsContext 
        graphicsContextWithCGContext:p_context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:t_ns_context];
    
    NSRect t_rect = NSMakeRect(p_info.progress.info.bounds.origin.x,
                               p_info.progress.info.bounds.origin.y,
                               p_info.progress.info.bounds.size.width,
                               p_info.progress.info.bounds.size.height);
    
    // Draw track
    [[NSColor controlColor] setFill];
    NSBezierPath* t_track = [NSBezierPath bezierPathWithRoundedRect:t_rect 
                                                            xRadius:3.0 
                                                            yRadius:3.0];
    [t_track fill];
    
    // Draw progress
    if (p_info.progress.info.value > p_info.progress.info.min)
    {
        CGFloat t_progress = (CGFloat)(p_info.progress.info.value - p_info.progress.info.min) / 
                            (CGFloat)(p_info.progress.info.max - p_info.progress.info.min);
        
        NSRect t_fill_rect = t_rect;
        t_fill_rect.size.width *= t_progress;
        
        [[NSColor controlAccentColor] setFill]; // User's accent color
        NSBezierPath* t_fill = [NSBezierPath bezierPathWithRoundedRect:t_fill_rect 
                                                               xRadius:3.0 
                                                               yRadius:3.0];
        [t_fill fill];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}
```

### Location: Replace MCMacDrawTheme function (line 880-1084)

**Replace entire function with:**

```objc
void MCMacDrawTheme(MCThemeDrawType p_type, MCThemeDrawInfo& p_info, 
                    CGContextRef p_context, bool p_hidpi)
{
    @autoreleasepool
    {
        CGContextRef t_context = p_context;
        
        // Update and set appearance for dark mode support
        update_appearance_cache();
        NSAppearance* t_saved_appearance = [NSAppearance currentAppearance];
        [NSAppearance setCurrentAppearance:s_cached_appearance];
        
        switch(p_type)
        {
            case THEME_DRAW_TYPE_SLIDER:
            {
                // Keep existing HITheme code for sliders (complex widget)
                HIThemeTrackDrawInfo t_info;
                t_info.version = 0;
                t_info.kind = p_info.slider.info.kind;
                t_info.bounds = p_info.slider.info.bounds;
                t_info.min = p_info.slider.info.min;
                t_info.max = p_info.slider.info.max;
                t_info.value = p_info.slider.info.value;
                t_info.reserved = 0;
                t_info.attributes = p_info.slider.info.attributes;
                t_info.enableState = p_info.slider.info.enableState;
                t_info.filler1 = 0;
                t_info.trackInfo.slider.thumbDir = p_info.slider.info.trackInfo.slider.thumbDir;
                t_info.trackInfo.slider.pressState = p_info.slider.info.trackInfo.slider.pressState;
                
                if (p_info.slider.count > 0)
                    HIThemeDrawTrackTickMarks(&t_info, p_info.slider.count, t_context, kHIThemeOrientationNormal);
                
                t_info.bounds.origin.y += 1;
                HIThemeDrawTrack(&t_info, NULL, t_context, kHIThemeOrientationNormal);
            }
            break;
            
            case THEME_DRAW_TYPE_SCROLLBAR:
            {
                // Use modern NSScroller
                draw_modern_scrollbar(p_info, t_context);
            }
            break;
            
            case THEME_DRAW_TYPE_PROGRESS:
            {
                // Use direct drawing for performance
                draw_modern_progress(p_info, t_context);
            }
            break;
            
            case THEME_DRAW_TYPE_BUTTON:
            {
                // Use modern NSButtonCell
                draw_modern_button(p_info, t_context);
            }
            break;
            
            case THEME_DRAW_TYPE_GROUP:
            {
                // Keep existing HITheme code
                HIRect t_rect;
                HIThemeGroupBoxDrawInfo t_info;
                
                t_rect.origin.x = p_info.group.bounds.left;
                t_rect.origin.y = p_info.group.bounds.top;
                t_rect.size.width = p_info.group.bounds.right - p_info.group.bounds.left;
                t_rect.size.height = p_info.group.bounds.bottom - p_info.group.bounds.top;
                
                t_info.version = 0;
                t_info.state = p_info.group.state;
                t_info.kind = p_info.group.is_secondary ? 
                             kHIThemeGroupBoxKindSecondary : kHIThemeGroupBoxKindPrimary;
                
                HIThemeDrawGroupBox(&t_rect, &t_info, t_context, kHIThemeOrientationNormal);
            }
            break;
            
            case THEME_DRAW_TYPE_FRAME:
            {
                // Keep existing HITheme code
                HIRect t_bounds;
                HIThemeFrameDrawInfo t_info;
                
                t_bounds.origin.x = p_info.frame.bounds.left;
                t_bounds.origin.y = p_info.frame.bounds.top;
                t_bounds.size.width = p_info.frame.bounds.right - p_info.frame.bounds.left;
                t_bounds.size.height = p_info.frame.bounds.bottom - p_info.frame.bounds.top;
                
                t_info.version = 0;
                t_info.kind = p_info.frame.is_list ? kHIThemeFrameListBox : kHIThemeFrameTextFieldSquare;
                t_info.state = p_info.frame.state;
                t_info.isFocused = false;
                
                HIThemeDrawFrame(&t_bounds, &t_info, t_context, kHIThemeOrientationNormal);
            }
            break;
            
            case THEME_DRAW_TYPE_TAB:
            {
                // Keep existing HITheme code
                HIRect t_bounds;
                HIThemeTabDrawInfo t_info;
                
                t_bounds.origin.x = p_info.tab.bounds.left;
                t_bounds.origin.y = p_info.tab.bounds.top;
                t_bounds.size.width = p_info.tab.bounds.right - p_info.tab.bounds.left;
                t_bounds.size.height = p_info.tab.bounds.bottom - p_info.tab.bounds.top;
                
                t_info.version = 1;
                t_info.direction = kThemeTabNorth;
                t_info.size = kHIThemeTabSizeNormal;
                
                if (p_info.tab.is_hilited)
                    t_info.style = (p_info.tab.is_disabled ? kThemeTabFrontInactive : kThemeTabFront);
                else if (p_info.tab.is_disabled)
                    t_info.style = kThemeTabNonFrontInactive;
                else
                    t_info.style = (p_info.tab.is_pressed ? kThemeTabNonFrontPressed : kThemeTabNonFront);
                
                t_info.adornment = kHIThemeTabAdornmentNone;
                t_info.kind = kHIThemeTabKindNormal;
                
                if (p_info.tab.is_first && p_info.tab.is_last)
                    t_info.position = kHIThemeTabPositionOnly;
                else if (p_info.tab.is_first)
                {
                    t_info.adornment = kHIThemeTabAdornmentTrailingSeparator;
                    t_info.position = kHIThemeTabPositionFirst;
                }
                else if (p_info.tab.is_last)
                    t_info.position = kHIThemeTabPositionLast;
                else
                {
                    t_info.adornment = kHIThemeTabAdornmentTrailingSeparator;
                    t_info.position = kHIThemeTabPositionMiddle;
                }
                
                HIThemeDrawTab(&t_bounds, &t_info, t_context, kHIThemeOrientationNormal, NULL);
            }
            break;
            
            case THEME_DRAW_TYPE_TAB_PANE:
            {
                // Keep existing HITheme code
                HIRect t_bounds;
                HIThemeTabPaneDrawInfo t_info;
                
                p_info.tab_pane.bounds.top += 1;
                t_bounds.origin.x = p_info.tab_pane.bounds.left;
                t_bounds.origin.y = p_info.tab_pane.bounds.top;
                t_bounds.size.width = p_info.tab_pane.bounds.right - p_info.tab_pane.bounds.left;
                t_bounds.size.height = p_info.tab_pane.bounds.bottom - p_info.tab_pane.bounds.top;
                
                t_info.version = 1;
                t_info.state = p_info.tab_pane.state;
                t_info.direction = kThemeTabNorth;
                t_info.size = kHIThemeTabSizeNormal;
                t_info.kind = kHIThemeTabKindNormal;
                t_info.adornment = kHIThemeTabPaneAdornmentNormal;
                
                HIThemeDrawTabPane(&t_bounds, &t_info, t_context, kHIThemeOrientationNormal);
            }
            break;
            
            case THEME_DRAW_TYPE_BACKGROUND:
            {
                // Keep existing HITheme code
                HIRect t_bounds;
                HIThemeBackgroundDrawInfo t_info;
                
                t_bounds.origin.x = p_info.background.bounds.left;
                t_bounds.origin.y = p_info.background.bounds.top;
                t_bounds.size.width = p_info.background.bounds.right - p_info.background.bounds.left;
                t_bounds.size.height = p_info.background.bounds.bottom - p_info.background.bounds.top;
                
                t_info.version = 0;
                t_info.state = p_info.background.state;
                t_info.kind = kThemeBackgroundMetal;
                
                HIThemeDrawBackground(&t_bounds, &t_info, t_context, kHIThemeOrientationNormal);
            }
            break;
            
            case THEME_DRAW_TYPE_FOCUS_RECT:
            {
                // Keep existing HITheme code
                HIRect t_bounds;
                t_bounds.origin.x = p_info.focus_rect.bounds.left;
                t_bounds.origin.y = p_info.focus_rect.bounds.top;
                t_bounds.size.width = p_info.focus_rect.bounds.right - p_info.focus_rect.bounds.left;
                t_bounds.size.height = p_info.focus_rect.bounds.bottom - p_info.focus_rect.bounds.top;
                
                HIThemeDrawFocusRect(&t_bounds, p_info.focus_rect.focused, t_context, kHIThemeOrientationNormal);
            }
            break;
            
            case THEME_DRAW_TYPE_MENU:
            case THEME_DRAW_TYPE_GTK:
                MCUnreachable();
                break;
        }
        
        // Restore appearance
        [NSAppearance setCurrentAppearance:t_saved_appearance];
    }
}
```

---

## File 2: engine/src/mac-theme.mm

### Location: Update color properties (line 164-378)

**Replace MCPlatformGetControlThemePropColor function:**

```objc
bool MCPlatformGetControlThemePropColor(MCPlatformControlType p_type, 
                                        MCPlatformControlPart p_part, 
                                        MCPlatformControlState p_state, 
                                        MCPlatformThemeProperty p_which, 
                                        MCColor& r_color)
{
    bool t_found = false;
    NSColor *t_color = nil;
    bool t_is_pattern = false;
    
    switch (p_which)
    {
        case kMCPlatformThemePropertyTextColor:
        {
            t_found = true;
            if (p_state & kMCPlatformControlStateDisabled)
            {
                t_color = [NSColor disabledControlTextColor];
            }
            else
            {
                switch (p_type)
                {
                    case kMCPlatformControlTypeInputField:
                    {
                        if (p_state & kMCPlatformControlStateSelected)
                            t_color = [NSColor selectedTextColor];
                        else
                            t_color = [NSColor textColor];
                        break;
                    }
                    
                    case kMCPlatformControlTypeTabPane:
                    case kMCPlatformControlTypeTabButton:
                    {
                        // Use modern semantic color
                        t_color = [NSColor controlTextColor];
                        break;
                    }
                    
                    case kMCPlatformControlTypeMenu:
                    case kMCPlatformControlTypeOptionMenu:
                    case kMCPlatformControlTypePopupMenu:
                    case kMCPlatformControlTypePulldownMenu:
                    case kMCPlatformControlTypeList:
                    {
                        if (p_state & kMCPlatformControlStateSelected
                            && p_state & kMCPlatformControlStateWindowActive)
                        {
                            if (p_type == kMCPlatformControlTypeList)
                                t_color = [NSColor alternateSelectedControlTextColor];
                            else
                                t_color = [NSColor selectedMenuItemTextColor];
                            break;
                        }
                        /* FALLTHROUGH */
                    }
                    
                    default:
                        t_color = [NSColor controlTextColor];
                        break;
                }
            }
            break;
        }
        
        case kMCPlatformThemePropertyBackgroundColor:
        {
            t_found = true;
            if (p_state & kMCPlatformControlStateSelected)
            {
                switch (p_type)
                {
                    case kMCPlatformControlTypeInputField:
                        t_color = [NSColor selectedTextBackgroundColor];
                        break;
                    
                    case kMCPlatformControlTypeMenu:
                    case kMCPlatformControlTypeOptionMenu:
                    case kMCPlatformControlTypePopupMenu:
                    case kMCPlatformControlTypePulldownMenu:
                        // Modern semantic color
                        t_color = [NSColor selectedContentBackgroundColor];
                        break;
                    
                    case kMCPlatformControlTypeList:
                        if (p_state & kMCPlatformControlStateWindowActive)
                            t_color = [NSColor alternateSelectedControlColor];
                        else
                            t_color = [NSColor secondarySelectedControlColor];
                        break;
                    
                    default:
                        t_color = [NSColor selectedControlColor];
                        break;
                }
            }
            
            // Handle non-selected controls
            if (t_color == nil)
            {
                switch (p_type)
                {
                    case kMCPlatformControlTypeInputField:
                    case kMCPlatformControlTypeList:
                        t_color = [NSColor textBackgroundColor];
                        break;
                    
                    case kMCPlatformControlTypeTooltip:
                        t_color = [NSColor toolTipColor];
                        t_found = t_color != nil;
                        break;
                    
                    case kMCPlatformControlTypeWindow:
                        if (p_state & kMCPlatformControlStateCompatibility)
                        {
                            return false;
                        }
                        /* FALLTHROUGH */
                    
                    case kMCPlatformControlTypeMessageBox:
                        t_is_pattern = true;
                        t_color = [NSColor windowBackgroundColor];
                        break;
                    
                    default:
                        t_is_pattern = true;
                        // Modern semantic color
                        t_color = [NSColor controlBackgroundColor];
                        break;
                }
            }
            
            break;
        }
        
        case kMCPlatformThemePropertyBorderColor:
        {
            t_found = true;
            // Use semantic separator color for modern look
            t_color = [NSColor separatorColor];
            break;
        }
        
        case kMCPlatformThemePropertyShadowColor:
        {
            t_found = true;
            if (p_type == kMCPlatformControlTypeWindow || 
                p_type == kMCPlatformControlTypeMessageBox)
                t_color = [NSColor shadowColor];
            else
                t_color = [NSColor controlShadowColor];
            break;
        }
        
        case kMCPlatformThemePropertyFocusColor:
        {
            t_found = true;
            // Use user's accent color for focus ring
            t_color = [NSColor controlAccentColor];
            break;
        }
        
        case kMCPlatformThemePropertyTopEdgeColor:
        case kMCPlatformThemePropertyLeftEdgeColor:
        {
            t_found = true;
            t_color = [NSColor controlLightHighlightColor];
            break;
        }
        
        case kMCPlatformThemePropertyBottomEdgeColor:
        case kMCPlatformThemePropertyRightEdgeColor:
        {
            t_found = true;
            t_color = [NSColor controlShadowColor];
            break;
        }
        
        default:
            break;
    }
    
    if (t_found && t_color != nil)
    {
        if (t_is_pattern)
        {
            // Patterns not fully supported, use highlight color
            t_color = [[NSColor controlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        }
        else
        {
            t_color = [t_color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        }
        
        r_color.red = [t_color redComponent] * 65535;
        r_color.green = [t_color greenComponent] * 65535;
        r_color.blue = [t_color blueComponent] * 65535;
    }
    
    return t_found;
}
```

### Location: Update font selection (line 40-49)

**Replace get_legacy_font_name function:**

```objc
// Returns the system font name
static NSString* get_legacy_font_name()
{
    // For macOS 10.14+, always use system font
    // This automatically adapts to user preferences and system version
    return [[NSFont systemFontOfSize:[NSFont systemFontSize]] familyName];
}
```

---

## File 3: engine/src/mac-window.mm (Optional - for appearance notifications)

### Location: Add to window initialization (find appropriate location in window setup)

**Add appearance change notification observer:**

```objc
// Add to window initialization
[[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(systemAppearanceDidChange:)
    name:NSSystemColorsDidChangeNotification
    object:nil];

// Add handler method
- (void)systemAppearanceDidChange:(NSNotification*)notification
{
    // Force appearance cache update
    extern void update_appearance_cache();
    update_appearance_cache();
    
    // Trigger redraw
    [self setNeedsDisplay:YES];
}
```

---

## Compilation Notes

1. **Minimum macOS SDK**: 10.14
2. **Deployment target**: 10.14
3. **Required frameworks**: AppKit (already linked)
4. **Compiler flags**: No changes needed

---

## Testing Checklist

- [ ] All button types render correctly
- [ ] Scrollbars render and respond to interaction
- [ ] Progress bars animate smoothly
- [ ] Dark mode switching works
- [ ] Light mode still works
- [ ] Retina displays render correctly
- [ ] User accent colors respected
- [ ] No memory leaks (run Instruments)
- [ ] Performance within 5% of baseline

---

## Rollback Instructions

If issues arise, revert these changes:

1. Restore original `MCMacDrawTheme()` function from git
2. Restore original `MCPlatformGetControlThemePropColor()` function
3. Remove helper functions at top of osxtheme.mm
4. Remove notification observer from mac-window.mm

The changes are isolated and can be reverted cleanly.
