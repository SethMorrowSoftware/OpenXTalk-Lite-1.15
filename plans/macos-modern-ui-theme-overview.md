# macOS Modern UI Theme Implementation Plan
## Overview & Architecture

**Last Updated**: October 12, 2025  
**Target macOS**: 10.14 (Mojave) and later  
**Status**: Planning Phase  
**Estimated Effort**: 2-3 weeks development + 1 week testing

---

## Executive Summary

This plan details the modernization of LiveCode's macOS UI theme system to support:
- ✅ macOS 10.14+ modern appearance
- ✅ Automatic dark mode support
- ✅ User accent color preferences
- ✅ Modern AppKit rendering instead of deprecated HITheme
- ✅ Performance parity with current implementation

### Key Benefits
- Native dark mode support (no manual color management)
- Modern UI appearance matching system apps
- Future-proof using supported AppKit APIs
- Minimal code changes (2-3 files)

### Key Constraints
- Minimum target: macOS 10.14 (no backward compatibility needed)
- Performance: <5% overhead acceptable
- No breaking changes to LiveCode script API

---

## Current State Analysis

### Architecture Overview

**Theme Rendering Pipeline**:
```
Button/Widget → MCButton::draw() → MCTheme::drawwidget() 
    → MCNativeTheme::drawwidget() → MCMacDrawTheme() 
    → HIThemeDrawButton() [CoreGraphics]
```

### Files Involved

| File | Purpose | Lines | Complexity |
|------|---------|-------|------------|
| `engine/src/osxtheme.mm` | Main theme rendering | 1294 | High |
| `engine/src/mac-theme.mm` | Colors & fonts | 391 | Medium |
| `engine/src/buttondraw.cpp` | Button drawing logic | 2051 | High |
| `engine/src/mctheme.h` | Theme interface | 277 | Low |
| `engine/src/osxtheme.h` | macOS theme header | 115 | Low |

### Current Rendering Methods

**HITheme API Usage** (deprecated but functional):
- `HIThemeDrawButton()` - All button types
- `HIThemeDrawTrack()` - Scrollbars, sliders, progress
- `HIThemeDrawFrame()` - Text fields, list boxes
- `HIThemeDrawTab()` - Tab controls
- `HIThemeDrawGroupBox()` - Group boxes

**Widget Type Mapping**:
```cpp
// osxtheme.mm:439-441
case WTHEME_TYPE_PULLDOWN:
    themebuttonkind = kThemeBevelButton;  // Maps to HITheme constant
    break;
```

### Dark Mode Status

**Current**: ❌ No dark mode support
- Colors are hardcoded or use legacy NSColor methods
- No NSAppearance context management
- HITheme doesn't respect system appearance

**Font Handling**:
```cpp
// mac-theme.mm:43-48
if (MCmajorosversion < MCOSVersionMake(10,10,0))
    return @"Lucida Grande";
else if (MCmajorosversion > MCOSVersionMake(10,11,0))
    return @"San Francisco";
else
    return @"Helvetica Neue";
```

---

## Proposed Architecture

### New Rendering Pipeline

```
Button/Widget → MCButton::draw() → MCTheme::drawwidget() 
    → MCNativeTheme::drawwidget() → MCMacDrawTheme() 
    → [Set NSAppearance context]
    → draw_modern_button() [NSButtonCell - cached]
    → [Restore appearance]
```

### Key Changes

1. **Appearance Management** (new)
   - Detect system dark mode state
   - Set NSAppearance before rendering
   - Cache appearance to avoid repeated checks

2. **Cell Caching** (new)
   - Cache NSButtonCell, NSScroller, etc. instances
   - Reuse cells across draw calls
   - Minimal memory overhead (~20KB)

3. **Modern Color API** (modified)
   - Use semantic NSColor methods
   - Automatic dark mode adaptation
   - User accent color support

4. **Hybrid Rendering** (new)
   - Complex widgets: cached NSButtonCell
   - Simple widgets: direct CoreGraphics
   - Optimal performance for each widget type

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Dark mode detection and appearance management

**Files Modified**: 
- `osxtheme.mm` (add helper functions)
- `mac-theme.mm` (update colors)

**Deliverables**:
- Dark mode detection working
- Appearance context management
- Updated color properties
- All existing functionality preserved

**Risk**: Low (additive changes only)

### Phase 2: Button Rendering (Week 1-2)
**Goal**: Modern button rendering with cached cells

**Files Modified**:
- `osxtheme.mm` (replace button drawing)

**Deliverables**:
- Push buttons render with NSButtonCell
- Bevel buttons render with NSButtonCell
- Popup/pulldown buttons render correctly
- Cell caching implemented
- Performance benchmarked

**Risk**: Medium (core rendering change)

### Phase 3: All Widgets (Week 2)
**Goal**: Complete widget set modernized

**Files Modified**:
- `osxtheme.mm` (all widget types)

**Deliverables**:
- Scrollbars (NSScroller)
- Progress bars (NSLevelIndicator or direct draw)
- Sliders (NSSliderCell)
- Checkboxes/Radio (NSButtonCell)
- Text fields (NSTextFieldCell)
- Tab controls (modern rendering)

**Risk**: Medium (extensive changes)

### Phase 4: Optimization & Testing (Week 3)
**Goal**: Performance optimization and comprehensive testing

**Deliverables**:
- Performance profiling complete
- Hot path optimizations applied
- Comprehensive test suite
- Dark mode switching tested
- Retina/HiDPI verified
- Memory leak testing

**Risk**: Low (polish phase)

---

## Performance Strategy

### Target Metrics
- **Baseline**: Current HITheme performance
- **Acceptable**: <5% slower than baseline
- **Goal**: Match or exceed baseline

### Optimization Techniques

1. **Cell Caching**: Eliminate allocation overhead
2. **Autoreleasepool**: Prevent memory bloat
3. **Appearance Caching**: Minimize system calls
4. **Direct Drawing**: For simple widgets
5. **Batching**: Minimize context switches (if needed)

### Benchmarking Plan

```objc
#ifdef DEBUG_THEME_PERFORMANCE
static void benchmark_draw(const char* p_name, void (^p_block)(void))
{
    CFAbsoluteTime t_start = CFAbsoluteTimeGetCurrent();
    p_block();
    CFAbsoluteTime t_elapsed = (CFAbsoluteTimeGetCurrent() - t_start) * 1000.0;
    
    if (t_elapsed > 1.0) // Log if > 1ms
        NSLog(@"Theme draw '%s' took %.2fms", p_name, t_elapsed);
}
#endif
```

**Metrics to Track**:
- Individual widget draw time
- Total frame render time
- Memory allocations per draw
- Autoreleasepool pressure

---

## Testing Strategy

### Unit Testing
- Each widget type renders correctly
- State changes (pressed, disabled, etc.)
- Dark/light mode switching
- Retina/non-Retina displays

### Integration Testing
- Full UI stack rendering
- Rapid redraw scenarios (scrolling)
- Window activation/deactivation
- System appearance changes

### Performance Testing
- Benchmark suite comparing old vs new
- Memory leak detection (Instruments)
- CPU profiling (Instruments)
- Frame rate during animation

### Visual Testing
- Screenshot comparison (light vs dark)
- Manual verification on macOS 10.14, 10.15, 11, 12, 13, 14
- Accent color variations (blue, purple, pink, etc.)

---

## Risk Assessment

### High Risk Items
- **Performance regression**: Mitigated by caching and profiling
- **Visual differences**: Acceptable if modern appearance is goal
- **Retina rendering**: NSButtonCell handles automatically

### Medium Risk Items
- **Memory leaks**: Mitigated by proper retain/release and testing
- **Thread safety**: All drawing on main thread (existing constraint)
- **Edge cases**: Comprehensive testing required

### Low Risk Items
- **API availability**: All APIs available on macOS 10.14+
- **Backward compatibility**: Not required (10.14 minimum)
- **Breaking changes**: No LiveCode script API changes

---

## Rollback Strategy

### If Performance Unacceptable
1. Keep HITheme code path as fallback
2. Add preference to switch rendering mode
3. Optimize hot paths with direct drawing

### If Visual Issues
1. Fine-tune cell configuration
2. Add custom drawing for problematic widgets
3. Hybrid approach (some HITheme, some AppKit)

### If Memory Issues
1. Reduce cache size
2. Implement cache eviction
3. Use direct drawing instead of cells

---

## Success Criteria

✅ All UI widgets render correctly in light mode  
✅ All UI widgets render correctly in dark mode  
✅ Performance within 5% of baseline  
✅ No memory leaks detected  
✅ No visual regressions in existing functionality  
✅ User accent colors respected  
✅ Retina/HiDPI rendering correct  
✅ System appearance changes handled gracefully  

---

## Next Steps

1. Review this plan with team
2. Create feature branch: `feature/macos-modern-theme`
3. Begin Phase 1 implementation
4. Set up performance benchmarking infrastructure
5. Create test plan document

---

## Related Documents

- `macos-modern-ui-theme-code.md` - Complete code implementation
- `macos-modern-ui-theme-testing.md` - Testing procedures
- `macos-modern-ui-theme-performance.md` - Performance optimization details
