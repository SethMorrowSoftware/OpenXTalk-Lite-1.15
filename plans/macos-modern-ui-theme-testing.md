# macOS Modern UI Theme - Testing Guide

**Last Updated**: October 12, 2025  
**Related**: macos-modern-ui-theme-overview.md

---

## Testing Overview

### Test Phases

1. **Unit Testing** - Individual widget rendering
2. **Integration Testing** - Full UI stack
3. **Performance Testing** - Benchmarks and profiling
4. **Visual Testing** - Appearance verification
5. **Regression Testing** - Ensure no breakage

---

## Unit Testing

### Test Matrix

| Widget Type | Light Mode | Dark Mode | Disabled | Pressed | Focused | Retina |
|-------------|-----------|-----------|----------|---------|---------|--------|
| Push Button | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Bevel Button | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Popup Button | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Pulldown Menu | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Checkbox | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Radio Button | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Scrollbar | ✓ | ✓ | ✓ | ✓ | N/A | ✓ |
| Progress Bar | ✓ | ✓ | ✓ | N/A | N/A | ✓ |
| Slider | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Text Field | ✓ | ✓ | ✓ | N/A | ✓ | ✓ |
| Tab Control | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

### Test Procedure for Each Widget

```objc
// Test template
void test_widget(Widget_Type p_type)
{
    MCWidgetInfo t_info;
    t_info.type = p_type;
    
    // Test 1: Normal state, light mode
    set_system_appearance("Light");
    t_info.state = WTHEME_STATE_CLEAR;
    assert(draw_widget_succeeds(t_info));
    assert(no_visual_glitches());
    
    // Test 2: Normal state, dark mode
    set_system_appearance("Dark");
    assert(draw_widget_succeeds(t_info));
    assert(colors_appropriate_for_dark_mode());
    
    // Test 3: Disabled state
    t_info.state = WTHEME_STATE_DISABLED;
    assert(draw_widget_succeeds(t_info));
    assert(appears_disabled());
    
    // Test 4: Pressed state
    t_info.state = WTHEME_STATE_PRESSED;
    assert(draw_widget_succeeds(t_info));
    assert(appears_pressed());
    
    // Test 5: Focused state
    t_info.state = WTHEME_STATE_HASFOCUS;
    assert(draw_widget_succeeds(t_info));
    assert(focus_ring_visible());
    
    // Test 6: Retina rendering
    set_display_scale(2.0);
    assert(draw_widget_succeeds(t_info));
    assert(no_pixelation());
}
```

---

## Integration Testing

### Full UI Stack Tests

**Test 1: Complete Window Rendering**
```
1. Create window with all widget types
2. Render in light mode
3. Switch to dark mode
4. Verify all widgets update correctly
5. No crashes, no visual artifacts
```

**Test 2: Rapid State Changes**
```
1. Create button widget
2. Rapidly toggle states:
   - Normal → Pressed → Normal (100x)
   - Enabled → Disabled → Enabled (100x)
   - Focused → Unfocused → Focused (100x)
3. Verify no memory leaks
4. Verify consistent rendering
```

**Test 3: Window Activation**
```
1. Create window with widgets
2. Activate window
3. Deactivate window
4. Verify widget appearance updates
5. Reactivate window
6. Verify appearance correct
```

**Test 4: System Appearance Changes**
```
1. Create window with widgets
2. Change system appearance (Light → Dark)
3. Verify all widgets update immediately
4. Change back (Dark → Light)
5. Verify all widgets update correctly
```

---

## Performance Testing

### Benchmark Suite

**File**: `tests/performance/theme_benchmark.mm`

```objc
#include <mach/mach_time.h>

static double measure_draw_time(void (^p_block)(void))
{
    static mach_timebase_info_data_t timebase;
    if (timebase.denom == 0)
        mach_timebase_info(&timebase);
    
    uint64_t t_start = mach_absolute_time();
    p_block();
    uint64_t t_end = mach_absolute_time();
    
    uint64_t t_elapsed_ns = ((t_end - t_start) * timebase.numer) / timebase.denom;
    return t_elapsed_ns / 1000000.0; // Convert to milliseconds
}

void benchmark_all_widgets()
{
    printf("Widget Performance Benchmark\n");
    printf("============================\n\n");
    
    // Benchmark each widget type
    double t_button_time = measure_draw_time(^{
        for (int i = 0; i < 1000; i++)
            draw_push_button();
    });
    printf("Push Button: %.3f ms/draw (1000 iterations)\n", t_button_time / 1000.0);
    
    double t_scrollbar_time = measure_draw_time(^{
        for (int i = 0; i < 1000; i++)
            draw_scrollbar();
    });
    printf("Scrollbar: %.3f ms/draw (1000 iterations)\n", t_scrollbar_time / 1000.0);
    
    // ... test all widget types
    
    printf("\nTotal frame time (all widgets): %.3f ms\n", 
           (t_button_time + t_scrollbar_time + ...) / 1000.0);
}
```

**Run Benchmark**:
```bash
# Build with optimizations
xcodebuild -configuration Release

# Run benchmark
./LiveCode.app/Contents/MacOS/LiveCode --run-benchmark theme_performance

# Compare with baseline
./compare_benchmarks.sh baseline.txt current.txt
```

### Performance Acceptance Criteria

- **Individual widget draw**: <1ms per widget
- **Total frame time**: <16ms (60 FPS) for typical UI
- **Memory usage**: <50KB for all caches
- **No memory leaks**: 0 leaks after 10,000 draws

---

## Visual Testing

### Screenshot Comparison

**Tool**: Create visual regression test suite

```bash
#!/bin/bash
# capture_screenshots.sh

# Set light mode
osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
sleep 1

# Capture all widgets in light mode
./LiveCode.app/Contents/MacOS/LiveCode --capture-widgets light_mode/

# Set dark mode
osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
sleep 1

# Capture all widgets in dark mode
./LiveCode.app/Contents/MacOS/LiveCode --capture-widgets dark_mode/

# Compare with baseline
./compare_screenshots.sh baseline/ current/
```

### Manual Visual Inspection

**Checklist for each widget**:

Light Mode:
- [ ] Colors match system appearance
- [ ] Borders crisp and clear
- [ ] Text readable
- [ ] Shadows appropriate
- [ ] No pixelation on Retina
- [ ] Matches native macOS apps

Dark Mode:
- [ ] Background appropriately dark
- [ ] Text has good contrast
- [ ] Borders visible but subtle
- [ ] Shadows work in dark context
- [ ] No color inversion issues
- [ ] Matches native macOS apps in dark mode

### Accent Color Testing

Test with all macOS accent colors:
- Blue (default)
- Purple
- Pink
- Red
- Orange
- Yellow
- Green
- Graphite

**Procedure**:
```
1. System Preferences → General → Accent Color → [Color]
2. Launch LiveCode
3. Create button with focus
4. Verify focus ring uses accent color
5. Create progress bar
6. Verify progress fill uses accent color
7. Repeat for all accent colors
```

---

## Regression Testing

### Existing Functionality Tests

**Test 1: LiveCode Script Compatibility**
```livecode
-- Verify all button properties still work
on testButtonProperties
   create button "Test"
   set the style of button "Test" to "standard"
   assert the style of button "Test" is "standard"
   
   set the style of button "Test" to "menu"
   assert the style of button "Test" is "menu"
   
   set the menuMode of button "Test" to "pulldown"
   assert the menuMode of button "Test" is "pulldown"
   
   -- Test all button styles
   repeat for each item tStyle in "standard,menu,checkbox,radiobutton"
      set the style of button "Test" to tStyle
      assert the style of button "Test" is tStyle
   end repeat
end testButtonProperties
```

**Test 2: Event Handling**
```livecode
-- Verify button events still fire
on testButtonEvents
   create button "Test"
   
   global gMouseDownFired, gMouseUpFired
   put false into gMouseDownFired
   put false into gMouseUpFired
   
   set the script of button "Test" to \
      "on mouseDown" & return & \
      "   global gMouseDownFired" & return & \
      "   put true into gMouseDownFired" & return & \
      "end mouseDown" & return & \
      "on mouseUp" & return & \
      "   global gMouseUpFired" & return & \
      "   put true into gMouseUpFired" & return & \
      "end mouseUp"
   
   simulate click on button "Test"
   
   assert gMouseDownFired is true
   assert gMouseUpFired is true
end testButtonEvents
```

**Test 3: Backward Compatibility**
```livecode
-- Test that old stacks still work
on testOldStackCompatibility
   open stack "OldStack.livecode" -- Stack from LC 9.x
   
   -- Verify all buttons render
   repeat for each line tButton in the buttons of this card
      assert the visible of button tButton is true
      assert the rect of button tButton is not empty
   end repeat
   
   -- Verify all controls interactive
   repeat for each line tControl in the controls of this card
      assert the enabled of control tControl is true
   end repeat
end testOldStackCompatibility
```

---

## Platform Testing

### macOS Version Matrix

Test on all supported macOS versions:

| macOS Version | Code Name | Test Status |
|---------------|-----------|-------------|
| 10.14 | Mojave | Required |
| 10.15 | Catalina | Required |
| 11.x | Big Sur | Required |
| 12.x | Monterey | Required |
| 13.x | Ventura | Required |
| 14.x | Sonoma | Required |

### Hardware Testing

Test on different hardware:
- Intel Mac (non-Retina)
- Intel Mac (Retina)
- Apple Silicon Mac (M1/M2)
- External displays (various resolutions)

---

## Automated Testing

### Continuous Integration

**File**: `.github/workflows/theme-tests.yml`

```yaml
name: Theme Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Build LiveCode
      run: |
        xcodebuild -configuration Release
    
    - name: Run Unit Tests
      run: |
        ./run_unit_tests.sh
    
    - name: Run Performance Tests
      run: |
        ./run_performance_tests.sh
    
    - name: Check for Memory Leaks
      run: |
        leaks --atExit -- ./LiveCode.app/Contents/MacOS/LiveCode --run-tests
    
    - name: Upload Test Results
      uses: actions/upload-artifact@v2
      with:
        name: test-results
        path: test-results/
```

---

## Bug Reporting Template

When issues are found:

```markdown
## Theme Rendering Issue

**Widget Type**: [Button/Scrollbar/etc.]
**macOS Version**: [10.14/10.15/etc.]
**Appearance**: [Light/Dark]
**Display**: [Retina/Non-Retina]

**Expected Behavior**:
[Description]

**Actual Behavior**:
[Description]

**Screenshot**:
[Attach screenshot]

**Steps to Reproduce**:
1. 
2. 
3. 

**Performance Impact**:
- Draw time: [X ms]
- Memory usage: [X KB]

**Suggested Fix**:
[If known]
```

---

## Test Sign-Off Checklist

Before merging to main branch:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Performance within acceptable range (<5% slower)
- [ ] No memory leaks detected
- [ ] Visual inspection complete (light mode)
- [ ] Visual inspection complete (dark mode)
- [ ] All accent colors tested
- [ ] Tested on macOS 10.14, 10.15, 11, 12, 13, 14
- [ ] Tested on Intel and Apple Silicon
- [ ] Tested on Retina and non-Retina displays
- [ ] Backward compatibility verified
- [ ] LiveCode script API unchanged
- [ ] Documentation updated
- [ ] Code review complete

---

## Rollback Criteria

Rollback changes if:

- [ ] >10% performance regression
- [ ] Memory leaks detected
- [ ] Visual glitches in any widget
- [ ] Crashes or hangs
- [ ] Backward compatibility broken
- [ ] Dark mode doesn't work correctly
- [ ] Retina rendering issues

---

## Post-Release Monitoring

After release, monitor for:

1. **User Reports**
   - Visual issues
   - Performance complaints
   - Crashes related to theme rendering

2. **Analytics** (if available)
   - Frame rate during UI interaction
   - Memory usage patterns
   - Crash reports

3. **Follow-up Testing**
   - Test on new macOS releases
   - Test with new hardware
   - Regression testing with each LC update
