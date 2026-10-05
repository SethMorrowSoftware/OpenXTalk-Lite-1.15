# Field Antialiasing Control - Implementation Plan

**Last Updated**: October 12, 2025  
**Status**: Planning Phase  
**Requested Feature**: Add `antialiased` property to field objects

---

## Feature Request

Add ability to control text antialiasing per field:

```livecode
set the antialiased of field "test" to false
```

**Benefits**:
- Improved performance for fields with thousands of lines
- User control over text rendering quality vs performance
- Default remains `true` (current behavior)

---

## Current Architecture Analysis

### Text Rendering Pipeline

**Flow**: Field → Block → Font → Graphics Context → Platform Drawing

1. **Field drawing** (`field.cpp:2452`):
   ```cpp
   void MCField::draw(MCDC *dc, const MCRectangle& p_dirty, bool p_isolated, bool p_sprite)
   ```

2. **Block text drawing** (`block.cpp:1090`):
   ```cpp
   dc->drawtext_substring(x, y, parent->GetInternalStringRef(), t_range, 
                         m_font, image == True, kMCDrawTextBreak, 
                         is_rtl() ? kMCDrawTextDirectionRTL : kMCDrawTextDirectionLTR);
   ```

3. **Graphics context** (`graphicscontext.cpp:1435`):
   ```cpp
   void MCGraphicsContext::drawtext_substring(coord_t x, int2 y, MCStringRef p_string, 
                                              MCRange p_range, MCFontRef p_font, ...)
   {
       MCFontDrawTextSubstring(m_gcontext, x, y, p_string, p_range, p_font, ...);
   }
   ```

4. **Font drawing** (`font.cpp:596`):
   ```cpp
   void MCFontDrawTextSubstring(MCGContextRef p_gcontext, coord_t x, coord_t y, ...)
   {
       MCFontDrawTextCallback(p_font, p_text, p_range, &ctxt);
   }
   ```

5. **Platform text rendering** (`font.cpp:574`):
   ```cpp
   static void MCFontDrawTextCallback(...)
   {
       MCGContextDrawPlatformText(ctxt->m_gcontext, ctxt->x, ctxt->y, ...);
   }
   ```

### Antialiasing Control Points

**Current antialiasing control** (`graphicscontext.cpp:389-393`):
```cpp
void MCGraphicsContext::setquality(uint1 p_quality)
{
    if (!m_force_antialiasing)
        MCGContextSetShouldAntialias(m_gcontext, p_quality == QUALITY_SMOOTH);
}
```

**Key function**: `MCGContextSetShouldAntialias()`
- Controls antialiasing for the graphics context
- Used for graphics/shapes, not currently per-field

---

## Implementation Approach

### Option 1: Field-Level Property (Recommended)

**Add new field property**:
- Property name: `antialiased` (boolean)
- Default value: `true`
- Stored in field flags

**Files to Modify**:

#### 1. `engine/src/field.h` (Line ~200-250)
Add flag to field class:
```cpp
// In MCField class private section, around line 247
bool m_recompute : 1;
bool m_antialiased : 1;  // NEW: Control text antialiasing
```

#### 2. `engine/src/field.cpp` (Constructor, around line 258)
Initialize flag:
```cpp
MCField::MCField()
{
    // ... existing initialization ...
    m_recompute = false;
    m_antialiased = true;  // NEW: Default to antialiased
    keyboard_type = kMCInterfaceKeyboardTypeNone;
}
```

#### 3. `engine/src/field.cpp` (Copy constructor, around line 347)
Copy flag:
```cpp
MCField::MCField(const MCField &fref) : MCControl(fref)
{
    // ... existing copying ...
    m_recompute = false;
    m_antialiased = fref.m_antialiased;  // NEW: Copy antialiased state
}
```

#### 4. `engine/src/parsedef.h` (Property definitions)
Add property constant:
```cpp
// Around line with other P_ definitions
P_ANTIALIASED,  // NEW
```

#### 5. `engine/src/field.cpp` (Property table, around line 100)
Add to property table:
```cpp
static MCPropertyInfo kProperties[] =
{
    // ... existing properties ...
    DEFINE_RW_OBJ_PROPERTY(P_ANTIALIASED, Bool, Field, Antialiased)
    // ... more properties ...
};
```

#### 6. `engine/src/exec-interface-field.cpp` (New file or existing)
Add getter/setter:
```cpp
void MCField::GetAntialiased(MCExecContext& ctxt, bool& r_antialiased)
{
    r_antialiased = m_antialiased;
}

void MCField::SetAntialiased(MCExecContext& ctxt, bool p_antialiased)
{
    if (m_antialiased == p_antialiased)
        return;
    
    m_antialiased = p_antialiased;
    
    // Trigger redraw
    if (opened)
        layer_redrawall();
}
```

#### 7. `engine/src/field.cpp` (Drawing code, around line 2540)
Pass antialiasing state to drawing context:
```cpp
void MCField::draw(MCDC *dc, const MCRectangle& p_dirty, bool p_isolated, bool p_sprite)
{
    // ... existing code ...
    
    // NEW: Set antialiasing before drawing text
    if (!m_antialiased)
        dc->setquality(QUALITY_DEFAULT);  // Disable antialiasing
    
    drawrect(dc, dirty);
    
    // NEW: Restore antialiasing
    if (!m_antialiased)
        dc->setquality(QUALITY_SMOOTH);   // Re-enable antialiasing
    
    // ... rest of drawing ...
}
```

#### 8. `engine/src/field.cpp` (Save/Load)
Persist property in stack file:
```cpp
// In MCField::save() - add to extended properties
// In MCField::load() - read from extended properties
```

---

### Option 2: Graphics Context Scope (Alternative)

**Temporarily override antialiasing during field draw**:

**Files to Modify**:

#### 1. `engine/src/graphicscontext.h`
Add methods:
```cpp
class MCGraphicsContext : public MCDC
{
    // ... existing ...
    
    void pushantialias(bool p_enabled);  // NEW
    void popantialias();                  // NEW
    
private:
    bool m_saved_antialias;               // NEW
};
```

#### 2. `engine/src/graphicscontext.cpp`
Implement push/pop:
```cpp
void MCGraphicsContext::pushantialias(bool p_enabled)
{
    m_saved_antialias = MCGContextGetShouldAntialias(m_gcontext);
    MCGContextSetShouldAntialias(m_gcontext, p_enabled);
}

void MCGraphicsContext::popantialias()
{
    MCGContextSetShouldAntialias(m_gcontext, m_saved_antialias);
}
```

#### 3. `engine/src/field.cpp`
Use in drawing:
```cpp
void MCField::draw(MCDC *dc, ...)
{
    // ... existing code ...
    
    if (!m_antialiased)
        dc->pushantialias(false);
    
    drawrect(dc, dirty);
    
    if (!m_antialiased)
        dc->popantialias();
}
```

---

## Performance Considerations

### Expected Performance Impact

**With antialiasing disabled**:
- **Text rendering**: 30-50% faster
- **Large fields** (1000+ lines): Noticeable improvement during scrolling
- **Small fields**: Minimal difference

**Trade-offs**:
- Disabled: Faster but jagged text edges
- Enabled: Slower but smooth text

### When to Disable

**Good use cases**:
- Log viewers with thousands of lines
- Data tables with frequent updates
- Terminal-style output
- Performance-critical applications

**Bad use cases**:
- User-facing text (looks poor)
- Small amounts of text (no benefit)
- High-DPI displays (antialiasing more important)

---

## Testing Plan

### Unit Tests

```livecode
-- Test 1: Default value
create field "test"
assert the antialiased of field "test" is true

-- Test 2: Set to false
set the antialiased of field "test" to false
assert the antialiased of field "test" is false

-- Test 3: Set to true
set the antialiased of field "test" to true
assert the antialiased of field "test" is true

-- Test 4: Persistence
set the antialiased of field "test" to false
save stack
close stack
open stack
assert the antialiased of field "test" is false
```

### Visual Tests

1. Create field with large text
2. Set `antialiased` to `false`
3. Verify text appears non-antialiased (jagged edges)
4. Set `antialiased` to `true`
5. Verify text appears smooth

### Performance Tests

```livecode
-- Create field with 10,000 lines
repeat with i = 1 to 10000
   put "Line " & i & return after field "test"
end repeat

-- Test with antialiasing ON
put the milliseconds into tStart
repeat 100
   scroll field "test" down 10
end repeat
put the milliseconds - tStart into tTimeOn

-- Test with antialiasing OFF
set the antialiased of field "test" to false
put the milliseconds into tStart
repeat 100
   scroll field "test" down 10
end repeat
put the milliseconds - tStart into tTimeOff

put "Time with AA:" && tTimeOn && "ms" & return
put "Time without AA:" && tTimeOff && "ms" & return
put "Improvement:" && round((1 - tTimeOff/tTimeOn) * 100) & "%"
```

---

## Implementation Checklist

### Phase 1: Core Implementation
- [ ] Add `m_antialiased` flag to `field.h`
- [ ] Initialize in constructors
- [ ] Add property constant to `parsedef.h`
- [ ] Add to property table
- [ ] Implement getter/setter in `exec-interface-field.cpp`
- [ ] Modify `draw()` to respect flag

### Phase 2: Persistence
- [ ] Add to save/load methods
- [ ] Test stack file compatibility

### Phase 3: Testing
- [ ] Unit tests for property get/set
- [ ] Visual verification tests
- [ ] Performance benchmarks
- [ ] Cross-platform testing (macOS, Windows, Linux)

### Phase 4: Documentation
- [ ] Add to LiveCode dictionary
- [ ] Add to release notes
- [ ] Create example stacks

---

## Platform-Specific Notes

### macOS
- Uses CoreText for text rendering
- Antialiasing controlled via `CGContextSetShouldAntialias()`
- Works with Retina displays

### Windows
- Uses GDI+ or DirectWrite
- Antialiasing controlled via graphics context
- May need platform-specific code

### Linux
- Uses Pango/Cairo
- Antialiasing controlled via Cairo context
- Should work consistently

---

## Alternative Approaches Considered

### 1. Global Preference
**Rejected**: Too coarse-grained, users want per-field control

### 2. Stack-Level Property
**Rejected**: Not granular enough for mixed-use cases

### 3. Automatic Based on Field Size
**Rejected**: Users should have explicit control

---

## Risks & Mitigation

### Risk: Performance Not Improved Enough
**Mitigation**: Benchmark before/after, document expected gains

### Risk: Visual Quality Too Poor
**Mitigation**: Make it opt-in, default to antialiased

### Risk: Platform Inconsistencies
**Mitigation**: Test on all platforms, handle edge cases

---

## Success Criteria

✅ Property can be set/get via LiveCode script  
✅ Visual difference observable (antialiased vs non-antialiased)  
✅ Performance improvement measurable (>20% for large fields)  
✅ Property persists in stack files  
✅ Works on macOS, Windows, Linux  
✅ No regressions in existing functionality  

---

## Estimated Effort

- **Core implementation**: 4-6 hours
- **Testing**: 2-3 hours
- **Documentation**: 1-2 hours
- **Total**: 1-2 days

---

## Next Steps

1. Review this plan with team
2. Create feature branch: `feature/field-antialiasing`
3. Implement core functionality
4. Add unit tests
5. Performance benchmark
6. Cross-platform testing
7. Documentation
8. Merge to main

