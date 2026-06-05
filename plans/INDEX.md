# macOS Modern UI Theme - Complete Implementation Plan
## Document Index

**Project**: LiveCode macOS UI Modernization  
**Target**: macOS 10.14+ with Dark Mode Support  
**Status**: Planning Phase  
**Last Updated**: October 12, 2025

---

## Quick Start

1. Read **Overview** for project understanding
2. Review **Code Implementation** for exact changes needed
3. Check **Performance Guide** for optimization strategies
4. Follow **Testing Guide** before deployment

---

## Document Structure

### 1. Overview Document
**File**: `macos-modern-ui-theme-overview.md`

**Contents**:
- Executive summary
- Current state analysis
- Proposed architecture
- Implementation phases (4 phases, 3 weeks)
- Risk assessment
- Success criteria

**Read this first** to understand the full scope and approach.

---

### 2. Code Implementation
**File**: `macos-modern-ui-theme-code.md`

**Contents**:
- Complete code for all changes
- Exact file locations and line numbers
- Helper functions for caching and appearance
- Modern rendering implementations
- Compilation notes

**Use this** when ready to implement changes.

**Key Files Modified**:
- `engine/src/osxtheme.mm` (primary changes)
- `engine/src/mac-theme.mm` (color/font updates)
- `engine/src/mac-window.mm` (optional notifications)

---

### 3. Performance Optimization
**File**: `macos-modern-ui-theme-performance.md`

**Contents**:
- Performance baseline metrics
- Optimization strategies (caching, autoreleasepool, etc.)
- Benchmarking code
- Hot path identification
- Memory optimization
- Decision trees for optimization choices

**Use this** to ensure performance targets are met.

**Key Metrics**:
- Target: <5% slower than HITheme
- Memory: <50KB for caches
- No memory leaks

---

### 4. Testing Guide
**File**: `macos-modern-ui-theme-testing.md`

**Contents**:
- Unit testing procedures
- Integration testing
- Performance testing
- Visual testing (light/dark mode)
- Regression testing
- Automated CI/CD setup

**Use this** before merging changes.

**Test Matrix**: All widgets × (Light/Dark × States × Retina)

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
**Files**: `osxtheme.mm`, `mac-theme.mm`

**Tasks**:
- Add dark mode detection
- Add appearance management
- Update color properties
- Add cell caching infrastructure

**Deliverable**: Dark mode colors work, no functional changes

---

### Phase 2: Button Rendering (Week 1-2)
**Files**: `osxtheme.mm`

**Tasks**:
- Replace HITheme button drawing with NSButtonCell
- Implement cell caching
- Test all button types
- Benchmark performance

**Deliverable**: All buttons render with modern appearance

---

### Phase 3: All Widgets (Week 2)
**Files**: `osxtheme.mm`

**Tasks**:
- Implement scrollbar rendering (NSScroller)
- Implement progress bar (direct draw)
- Implement slider (keep HITheme or modernize)
- Implement checkboxes/radio buttons
- Test all widgets

**Deliverable**: Complete widget set modernized

---

### Phase 4: Optimization & Testing (Week 3)
**Files**: All

**Tasks**:
- Performance profiling
- Optimize hot paths
- Comprehensive testing
- Visual verification
- Documentation

**Deliverable**: Production-ready implementation

---

## Key Technical Decisions

### 1. Rendering Approach
**Decision**: Hybrid approach
- Complex widgets: Cached NSButtonCell
- Simple widgets: Direct CoreGraphics
- Some widgets: Keep HITheme (if working well)

**Rationale**: Balance between modern appearance and performance

---

### 2. Caching Strategy
**Decision**: Global cell cache with no eviction

**Implementation**:
```objc
static NSMutableDictionary<NSNumber*, NSButtonCell*>* s_button_cell_cache;
```

**Rationale**: 
- Minimal memory (~15KB total)
- Maximum performance
- Simple implementation

---

### 3. Dark Mode Detection
**Decision**: Cache appearance, update on system change

**Implementation**:
```objc
static NSAppearance* s_cached_appearance;
static void update_appearance_cache() { /* ... */ }
```

**Rationale**:
- Avoid repeated system calls
- Automatic updates via notifications
- Minimal overhead

---

### 4. Backward Compatibility
**Decision**: No backward compatibility needed

**Rationale**: Minimum target is macOS 10.14 (Mojave)

**Impact**: Can remove all version checks for <10.14

---

## Success Criteria Summary

✅ **Functional**:
- All widgets render correctly in light mode
- All widgets render correctly in dark mode
- User accent colors respected
- No LiveCode script API changes

✅ **Performance**:
- <5% slower than current HITheme
- <50KB additional memory
- No memory leaks
- No frame drops during normal use

✅ **Quality**:
- Matches native macOS appearance
- Retina/HiDPI rendering correct
- All tests pass
- Code review approved

---

## Risk Mitigation

### High Risk: Performance Regression
**Mitigation**:
- Cell caching (primary optimization)
- Autoreleasepool management
- Direct drawing for simple widgets
- Comprehensive benchmarking

**Fallback**: Keep HITheme code path as option

---

### Medium Risk: Visual Differences
**Mitigation**:
- Extensive visual testing
- Screenshot comparison
- Manual verification on all macOS versions

**Fallback**: Fine-tune cell configuration or use custom drawing

---

### Low Risk: Memory Leaks
**Mitigation**:
- Proper retain/release
- Instruments testing
- Automated leak detection in CI

**Fallback**: Reduce cache size or use direct drawing

---

## Code Review Checklist

Before approving implementation:

- [ ] All code follows LiveCode style guidelines
- [ ] No memory leaks (verified with Instruments)
- [ ] Performance benchmarks within acceptable range
- [ ] All unit tests pass
- [ ] Visual inspection complete
- [ ] Documentation updated
- [ ] Backward compatibility verified
- [ ] Edge cases handled
- [ ] Error handling appropriate
- [ ] Code comments clear and helpful

---

## Deployment Plan

### 1. Feature Branch
```bash
git checkout -b feature/macos-modern-theme
```

### 2. Incremental Implementation
- Commit after each phase
- Tag stable points
- Keep main branch stable

### 3. Testing Gates
- Phase 1: Unit tests must pass
- Phase 2: Performance tests must pass
- Phase 3: Integration tests must pass
- Phase 4: All tests must pass

### 4. Merge to Main
```bash
# After all tests pass and code review approved
git checkout main
git merge --no-ff feature/macos-modern-theme
git tag v9.7.0-modern-theme
```

---

## Maintenance Plan

### Regular Testing
- Test on new macOS releases (beta program)
- Test with new hardware
- Regression testing with each LiveCode update

### Performance Monitoring
- Track performance metrics over time
- Watch for degradation
- Optimize as needed

### User Feedback
- Monitor bug reports
- Collect user feedback on appearance
- Iterate based on real-world usage

---

## References

### Apple Documentation
- [NSAppearance](https://developer.apple.com/documentation/appkit/nsappearance)
- [NSButtonCell](https://developer.apple.com/documentation/appkit/nsbuttoncell)
- [NSScroller](https://developer.apple.com/documentation/appkit/nsscroller)
- [NSColor](https://developer.apple.com/documentation/appkit/nscolor)
- [Dark Mode Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/visual-design/dark-mode/)

### LiveCode Documentation
- Theme system architecture
- Widget rendering pipeline
- Platform abstraction layer

---

## Contact & Questions

For questions about this plan:
1. Review the relevant document section
2. Check Apple documentation
3. Consult with LiveCode core team
4. Test proposed changes in isolation

---

## Version History

- **v1.0** (2025-10-12): Initial comprehensive plan
  - Overview document
  - Code implementation guide
  - Performance optimization guide
  - Testing procedures
  - Complete roadmap

---

## Next Steps

1. ✅ Review this index
2. ✅ Read overview document
3. ⏳ Team review and approval
4. ⏳ Create feature branch
5. ⏳ Begin Phase 1 implementation
6. ⏳ Iterate through phases
7. ⏳ Deploy to production

**Estimated Timeline**: 3-4 weeks from start to production
