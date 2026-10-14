# Episode Images & Ads Rendering Bugfix Design

## Overview

Episode images and banner ads are not rendering in the episode reader despite being successfully uploaded to Supabase storage and saved to Firestore with proper URLs. Images are correctly stored at `novels/{novelId}/episodes/{episodeId}/image_{timestamp}.ext` paths, and content blocks are serialized with `storagePath` and `url` fields. The reader page has logic to regenerate public URLs from storage paths if needed. The bug appears to be in how images and ads are being displayed in the reader's content block rendering logic, with potential issues in URL resolution, widget rendering, or conditional visibility.

## Glossary

- **Bug_Condition (C)**: Content blocks with type "image" or "ad" are saved to Firestore and retrieved by the reader, but fail to render visually in the UI
- **Property (P)**: When content blocks with image or ad types are encountered during reader rendering, they should display correctly with proper URLs and visual layout
- **Preservation**: All text and PDF content rendering must remain unchanged; upload and storage operations must continue working; serialization/deserialization must remain intact
- **_buildContentBlocks()**: The switch statement in `episode_reader_page.dart` that renders each content block based on its type
- **AppAdaptiveImage**: The widget used to display images from URLs with fallback handling
- **ReaderInlineBannerAd**: The widget used to render inline banner advertisements
- **readingBlocks**: The list of content blocks passed to `_buildContentBlocks()` for rendering

## Bug Details

### Bug Condition

The bug manifests when the episode reader calls `_buildContentBlocks()` with a list containing blocks of type `ContentBlockType.image` or `ContentBlockType.ad`. The reader code contains the logic to handle these types, but images and ads are not appearing in the rendered output. Potential root causes:

1. **URL Resolution Failure**: The image URL is not correctly resolved from storagePath/url fields, or the resolved URL is invalid/inaccessible
2. **Conditional Logic Failure**: The switch case for image/ad blocks is not being executed or has an early return before widgets are added
3. **Widget Rendering Failure**: The widgets are created but not added to the widget list, or visibility conditions prevent rendering
4. **Data Retrieval Failure**: The blocks are not being retrieved from Firestore with proper URL/storagePath data intact
5. **Ad Service Failure**: AdService is returning false for shouldShowAdsFor(), causing ads to render as SizedBox.shrink()

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type ContentBlockEntity
  OUTPUT: boolean
  
  RETURN (input.type = ContentBlockType.image OR input.type = ContentBlockType.ad)
         AND block exists in readingBlocks list
         AND block is passed to _buildContentBlocks() method
         AND block does not render as a visible widget in the UI
END FUNCTION
```

### Examples

**Example 1 - Image Not Displaying:**
- Writer adds image to episode with caption "Character Portrait"
- Image is uploaded to Supabase: `novels/novel-123/episodes/ep-456/image_1699564800000.jpg`
- Firestore stores block with: `type: "image"`, `storagePath: "novels/novel-123/episodes/ep-456/image_1699564800000.jpg"`, `url: "https://...supabase...image_1699564800000.jpg"`, `caption: "Character Portrait"`
- Episode is published
- Reader opens episode but image does not appear where it should
- Expected: Image displays with caption, but actual: empty space or missing widget

**Example 2 - Ad Not Displaying:**
- Writer adds ad placement block to episode
- Firestore stores block with: `type: "ad"`, `placement: "inline"`, `id: "ad-slot-789"`
- Episode is published
- Reader opens episode but ad does not appear
- Expected: Ad widget renders with AdMob banner or test placeholder in debug mode, but actual: no visual output

**Example 3 - Mixed Content:**
- Episode has: [text block] → [image block] → [text block] → [ad block] → [text block]
- Reader displays all text blocks correctly
- Image and ad blocks are completely missing from rendered output
- Expected: All content displays sequentially, but actual: only text blocks appear

**Example 4 - Edge Case with Invalid URL:**
- Image URL is stored as local device path (e.g., `/sdcard/image.jpg`) instead of Supabase URL
- storagePath is valid: `novels/novel-123/episodes/ep-456/image_1699564800000.jpg`
- Expected: Reader should regenerate public URL from storagePath and display image
- Actual: Image fails to display because of invalid local path URL

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Text content blocks must continue to render with correct font, size, and styling
- PDF content blocks must continue to render with Syncfusion PDF viewer
- Episode metadata (title, chapter number, word count) must display correctly
- Navigation between chapters must continue to work
- Reader settings (font size, line height, theme) must continue to work
- Image and PDF uploads to Supabase must continue to succeed
- Content block serialization to Firestore must remain intact with all fields preserved
- Non-buggy episodes without images/ads must display correctly

**Scope:**
All content blocks of type `text` and `pdf`, and all non-image/ad related functionality, should be completely unaffected by this fix. The fix should only add missing rendering logic for image and ad blocks without modifying existing working behavior.

## Hypothesized Root Cause

Based on code analysis, the most likely issues are:

1. **URL Resolution Fallback Not Working**: The code checks if `imageUrl.startsWith('http')` after trying to regenerate from storagePath. If regeneration returns empty string or fails, the condition prevents widget creation. The fallback logic at line ~200 may not handle all URL formats correctly.

2. **Block Not Reaching Switch Statement**: The blocks passed to `_buildContentBlocks()` might not include image/ad blocks. Check if `ctrl.readingBlocks` filtering is excluding them or if deserialization is losing the block type information.

3. **JSON Deserialization Type Mismatch**: The `ContentBlockType.values.firstWhere()` in `ContentBlockModel.fromJson()` might not find the matching type enum if the JSON stores the type name differently than `type.name` format.

4. **Ad Service Configuration**: `AdService().shouldShowAdsFor()` might be returning false for all users, or AdService initialization is failing in release build.

5. **Async Image Loading Issue**: `AppAdaptiveImage` might require async URL resolution that hasn't completed when the widget is built, especially in release builds with network latency.

## Correctness Properties

Property 1: Bug Condition - Image and Ad Block Rendering

_For any_ content block where the type is image or ad (isBugCondition returns true), the fixed _buildContentBlocks method SHALL render the appropriate widget (ClipRRect with AppAdaptiveImage for images, or ReaderInlineBannerAd for ads) and add it to the returned widget list, making it visible in the episode reader UI.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation - Other Content Blocks and Operations

_For any_ content block where the type is NOT image or ad (isBugCondition returns false), and for all non-image/ad related operations (uploads, serialization, text/PDF rendering), the fixed code SHALL produce exactly the same behavior as the original code, preserving all existing functionality without changes.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Fix Implementation

### Changes Required

Assuming the root cause is URL resolution failure or conditional logic issues in `_buildContentBlocks()`:

**File**: `lib/features/reader/pages/episode_reader_page.dart`

**Method**: `_buildContentBlocks()`

**Specific Changes**:

1. **URL Resolution Enhancement**: Add more robust URL validation and fallback logic for image blocks
   - Check if URL is empty or invalid after regeneration
   - Implement fallback chain: `block.url` → `regenerated from storagePath` → skip rendering
   - Log warnings for debugging when URL resolution fails

2. **Image Widget Rendering**: Ensure image widgets are properly added to the list with correct conditions
   - Verify the `imageUrl.startsWith('http')` check is working correctly
   - Add explicit logging to confirm widgets are being created
   - Verify ClipRRect and AppAdaptiveImage are properly constructed

3. **Ad Block Rendering**: Verify ad blocks reach the `ContentBlockType.ad` case
   - Add logging to confirm ad blocks are being processed
   - Verify ReaderInlineBannerAd widget is created with correct parameters
   - Check userRole is being passed correctly

4. **Block Type Deserialization**: Verify block types are correctly deserialized from Firestore
   - Check ContentBlockModel.fromJson() is correctly mapping type strings
   - Verify blocks list is not being filtered before reaching _buildContentBlocks()
   - Add logging at data retrieval layer to confirm block types

5. **Widget List Population**: Ensure all created widgets are added to the final list
   - Verify no early returns before widget list modification
   - Check for any filtering or conditional skips affecting image/ad blocks

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code by creating test episodes with images and ads, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Create integration tests that simulate opening episodes with image and ad blocks, and assert that the widgets appear in the rendered output. Run these tests on the UNFIXED code to observe failures and understand the root cause.

**Test Cases**:
1. **Episode with Single Image**: Open episode containing one image block, verify image widget is created and rendered (will fail on unfixed code)
2. **Episode with Single Ad**: Open episode containing one ad block, verify ad widget is created and rendered (will fail on unfixed code)
3. **Episode with Mixed Blocks**: Open episode with text→image→text→ad→text sequence, verify all blocks render in correct order (will fail on unfixed code)
4. **Episode with Invalid Image URL**: Open episode where image URL is local path instead of HTTP URL, verify fallback regeneration works (may fail on unfixed code)

**Expected Counterexamples**:
- Image widgets are not appearing in rendered output despite blocks existing in data
- Ad widgets show as SizedBox.shrink() or loading spinner instead of actual ads
- Mixed content episodes show text but gaps where images/ads should be
- Possible causes: URL resolution failure, conditional skip logic, widget list not updated, AdService blocking ads

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL block IN blocks WHERE isBugCondition(block) DO
  widgets := _buildContentBlocks_fixed(blocks)
  ASSERT block is rendered as widget in widgets list
  ASSERT widget is properly visible in UI
  ASSERT widget type matches block type (Image or Ad)
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL block IN blocks WHERE NOT isBugCondition(block) DO
  ASSERT _buildContentBlocks_original(blocks) = _buildContentBlocks_fixed(blocks)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking:
- Generate episodes with varying combinations of text and PDF blocks
- Verify text and PDF rendering remains identical before and after fix
- Test edge cases: empty blocks, very long text, multiple PDFs

**Test Plan**: Observe behavior on UNFIXED code first for text and PDF blocks, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Text Block Preservation**: Create episodes with various text blocks, verify they render identically before and after fix
2. **PDF Block Preservation**: Create episodes with PDF blocks, verify they render identically before and after fix
3. **Upload Preservation**: Verify image/PDF uploads to Supabase continue to succeed after fix
4. **Serialization Preservation**: Verify content block serialization to Firestore remains unchanged
5. **Episode Navigation**: Verify chapter navigation still works correctly after fix

### Unit Tests

- Test image URL resolution with valid HTTP URL
- Test image URL resolution with Supabase storage path fallback
- Test image URL resolution with invalid/empty paths
- Test ad block widget creation for different user roles
- Test mixed content block rendering order

### Property-Based Tests

- Generate random episodes with random block combinations
- Verify image blocks render when valid URLs are present
- Verify ad blocks render when user role allows ads
- Verify text blocks continue to render unchanged
- Test that block order is preserved in rendered output

### Integration Tests

- Test full episode reader flow with image blocks
- Test full episode reader flow with ad blocks
- Test opening episodes with mixed content
- Test switching between episodes with different block types
- Test reader settings (font size, theme) don't break image/ad rendering
