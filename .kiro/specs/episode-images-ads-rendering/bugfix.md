# Episode Images & Ads Rendering Bugfix Requirements

## Introduction

Writers are uploading images to episodes via the episode editor and publishing them, but the images and banner ads are not displaying in the episode reader. Images are successfully stored in Supabase storage at the expected paths (novels/{novelId}/episodes/{episodeId}/image_{timestamp}.ext) and content blocks are saved to Firestore with proper storagePath and url fields. The reader has logic to regenerate URLs from storage paths if needed, but images and ads are still not rendering in the UI. This prevents readers from seeing visual content and advertisements that writers have added to episodes.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a writer publishes an episode with embedded images THEN the images do not appear in the episode reader despite being successfully stored in Supabase
1.2 WHEN a writer publishes an episode with banner ads THEN the ads do not appear in the episode reader despite being configured
1.3 WHEN the episode reader renders content blocks with type "image" THEN the images fail to render even though Firestore contains the storagePath and url fields
1.4 WHEN the episode reader renders content blocks with type "ad" THEN the ads fail to render even though the ad block is stored

### Expected Behavior (Correct)

2.1 WHEN a writer publishes an episode with embedded images THEN the images SHALL display correctly in the episode reader using the storagePath and public URL from Supabase
2.2 WHEN a writer publishes an episode with banner ads THEN the ads SHALL display correctly in the episode reader in the configured positions
2.3 WHEN the episode reader renders content blocks with type "image" THEN the images SHALL render visually in the correct layout position using the stored URL or regenerated public URL
2.4 WHEN the episode reader renders content blocks with type "ad" THEN the ads SHALL render visually in the correct layout position

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the episode reader renders text content blocks THEN the text SHALL CONTINUE TO display correctly without changes
3.2 WHEN the episode reader renders PDF content blocks THEN the PDFs SHALL CONTINUE TO display correctly as before
3.3 WHEN the episode editor saves content blocks without images or ads THEN the save operation SHALL CONTINUE TO work correctly
3.4 WHEN a writer uploads images via the episode editor THEN the images SHALL CONTINUE TO be stored in Supabase at the correct path
3.5 WHEN the episode repository retrieves blocks from Firestore THEN the blocks SHALL CONTINUE TO be deserialized correctly with all fields intact
