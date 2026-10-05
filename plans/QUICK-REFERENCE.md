# macOS Modern UI Theme - Quick Reference

**Last Updated**: October 12, 2025

---

## At a Glance

**Goal**: Modernize LiveCode macOS UI with dark mode support  
**Target**: macOS 10.14+ (Mojave and later)  
**Effort**: 3 weeks development + 1 week testing  
**Files Changed**: 2-3 files (osxtheme.mm, mac-theme.mm, optionally mac-window.mm)  
**Performance Impact**: <5% slower (acceptable)  
**Risk**: Medium (core rendering changes, but well-planned)

---

## Key Benefits

✅ Native dark mode support (automatic)  
✅ Modern macOS appearance  
✅ User accent color support  
✅ Future-proof (uses supported APIs)  
✅ Minimal code changes  

---

## Files to Modify

### Primary: `engine/src/osxtheme.mm`
**Changes**: ~500 lines added/modified
- Add helper functions (appearance, caching)
- Replace `MCMacDrawTheme()` function
- Add modern rendering functions

### Secondary: `engine/src/mac-theme.mm`
**Changes**: ~200 lines modified
- Update `MCPlatformGetControlThemePropColor()`
- Update `get_legacy_font_name()`
- Use semantic NSColor methods

### Optional: `engine/src/mac-window.mm`
**Changes**: ~20 lines added
- Add appearance change notification
- Trigger redraw on system appearance change

---

## Core Approach

### 1. Dark Mode Detection
```objc
static NSAppearance* get_effective_appearance()
{
    NSString* t_style = [[NSUserDefaults standardUserDefaults] 
        stringForKey:@"AppleInterfaceStyle"];
    
    if ([t_style isEqualToString:@"Dark"])
        return [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    else
        return [NSAppearance appearanceNamed:NSAppearanceNameAqua];
}
```

### 2. Cell Caching
```objc
static NSMutableDictionary* s_button_cell_cache = nil;

static NSButtonCell* get_cached_button_cell(ThemeButtonKind p_kind)
{
    // Create once, reuse forever
    // ~10 cells × 1KB = 10KB total memory
}
```

### 3. Modern Rendering
```objc
// Replace HIThemeDrawButton() with:
NSButtonCell* t_cell = get_cached_button_cell(p_kind);
[t_cell drawWithFrame:t_rect inView:nil];
```

### 4. Semantic Colors
```objc
// Old: Hardcoded colors
t_color = [NSColor blackColor];

// New: Semantic colors (adapt to dark mode)
t_color = [NSColor controlTextColor];
t_color = [NSColor controlAccentColor]; // User's accent color
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
- Add dark mode detection ✓
- Add cell caching infrastructure ✓
- Update color properties ✓
- **Test**: Colors work in dark mode

### Phase 2: Buttons (Week 1-2)
- Replace button rendering ✓
- Test all button types ✓
- **Test**: Performance acceptable

### Phase 3: All Widgets (Week 2)
- Scrollbars, progress, sliders ✓
- Checkboxes, radio buttons ✓
- **Test**: All widgets work

### Phase 4: Polish (Week 3)
- Performance optimization ✓
- Comprehensive testing ✓
- **Test**: Production ready

---

## Performance Targets

| Metric | Target | Acceptable | Unacceptable |
|--------|--------|------------|--------------|
| Speed | Same as HITheme | <5% slower | >10% slower |
| Memory | <20KB | <50KB | >100KB |
| Leaks | 0 | 0 | Any |
| Frame drops | 0 | Rare | Frequent |

---

## Testing Checklist

**Before Merging**:
- [ ] All widgets render in light mode
- [ ] All widgets render in dark mode
- [ ] Performance <5% slower
- [ ] No memory leaks
- [ ] Tested on macOS 10.14, 11, 12, 13, 14
- [ ] Tested on Intel and Apple Silicon
- [ ] Retina rendering correct
- [ ] Backward compatibility OK
- [ ] Code review approved

---

## Common Issues & Solutions

### Issue: Performance too slow
**Solution**: Use direct CoreGraphics for simple widgets
```objc
// Instead of NSButtonCell for progress bars:
[[NSColor controlAccentColor] setFill];
[NSBezierPath fillRect:t_rect];
```

### Issue: Colors wrong in dark mode
**Solution**: Use semantic NSColor methods
```objc
// Wrong:
[NSColor whiteColor]

// Right:
[NSColor controlBackgroundColor]
```

### Issue: Memory leaks
**Solution**: Verify retain/release
```objc
// Cache retains cell - don't release it
[s_cache setObject:t_cell forKey:t_key]; // Retains
// Don't call [t_cell release]
```

### Issue: Visual glitches
**Solution**: Check NSGraphicsContext state
```objc
[NSGraphicsContext saveGraphicsState];
// ... draw
[NSGraphicsContext restoreGraphicsState];
```

---

## Rollback Plan

If issues arise:

1. **Revert commits**:
   ```bash
   git revert <commit-hash>
   ```

2. **Keep HITheme fallback**:
   ```objc
   if (use_modern_theme)
       draw_modern_button();
   else
       HIThemeDrawButton(); // Fallback
   ```

3. **Add preference**:
   ```objc
   if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseModernTheme"])
       // Modern rendering
   else
       // HITheme rendering
   ```

---

## Quick Commands

### Build
```bash
cd /Users/admin/Cascade/Livecode-Community-9.6.3/livecode
xcodebuild -configuration Release
```

### Run Tests
```bash
./run_unit_tests.sh
./run_performance_tests.sh
```

### Check for Leaks
```bash
leaks --atExit -- ./LiveCode.app/Contents/MacOS/LiveCode
```

### Profile Performance
```bash
instruments -t "Time Profiler" ./LiveCode.app/Contents/MacOS/LiveCode
```

---

## Key Code Locations

### Dark Mode Detection
**File**: `osxtheme.mm`  
**Function**: `get_effective_appearance()`  
**Line**: ~40 (after includes)

### Cell Caching
**File**: `osxtheme.mm`  
**Function**: `get_cached_button_cell()`  
**Line**: ~80

### Main Rendering
**File**: `osxtheme.mm`  
**Function**: `MCMacDrawTheme()`  
**Line**: ~880 (replace entire function)

### Color Properties
**File**: `mac-theme.mm`  
**Function**: `MCPlatformGetControlThemePropColor()`  
**Line**: ~164 (replace entire function)

---

## Resources

### Documentation
- **Overview**: `plans/macos-modern-ui-theme-overview.md`
- **Code**: `plans/macos-modern-ui-theme-code.md`
- **Performance**: `plans/macos-modern-ui-theme-performance.md`
- **Testing**: `plans/macos-modern-ui-theme-testing.md`
- **Index**: `plans/INDEX.md`

### Apple Docs
- [NSAppearance](https://developer.apple.com/documentation/appkit/nsappearance)
- [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/macos/visual-design/dark-mode/)
- [NSButtonCell](https://developer.apple.com/documentation/appkit/nsbuttoncell)

---

## Decision Tree

```
Ready to implement?
├─ YES → Read overview.md, then code.md
└─ NO → Need more info?
        ├─ Performance concerns? → Read performance.md
        ├─ Testing strategy? → Read testing.md
        └─ General overview? → Read overview.md
```

---

## Success Metrics

**Functional Success**:
- ✅ Dark mode works automatically
- ✅ All widgets render correctly
- ✅ No script API changes

**Performance Success**:
- ✅ <5% slower than baseline
- ✅ <50KB memory overhead
- ✅ No leaks

**Quality Success**:
- ✅ Matches native macOS apps
- ✅ All tests pass
- ✅ Code review approved

---

## Timeline

- **Week 1**: Foundation + Buttons
- **Week 2**: All widgets
- **Week 3**: Optimization + Testing
- **Week 4**: Code review + Deployment

**Total**: ~4 weeks from start to production

---

## Contact

For questions:
1. Check relevant plan document
2. Review Apple documentation
3. Consult LiveCode core team
4. Test in isolation before asking

---

**Remember**: This is a well-planned, low-risk modernization with clear benefits and fallback options. Take it phase by phase, test thoroughly, and you'll have a modern, dark-mode-enabled LiveCode on macOS!
