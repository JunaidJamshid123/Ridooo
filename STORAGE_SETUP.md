# Supabase Storage Setup for Profile Pictures

## 1. Create Storage Bucket

Go to your Supabase Dashboard → Storage and create a new bucket:

**Bucket Name:** `avatars`
**Public:** ✅ Yes (check this box)

## 2. Set Storage Policies

After creating the bucket, go to the Policies tab and add these policies:

### Policy 1: Allow Authenticated Users to Upload
```sql
CREATE POLICY "Allow authenticated users to upload avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Policy 2: Allow Users to Update Their Own Avatar
```sql
CREATE POLICY "Allow users to update own avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Policy 3: Allow Users to Delete Their Own Avatar
```sql
CREATE POLICY "Allow users to delete own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Policy 4: Allow Public Read Access
```sql
CREATE POLICY "Public avatar access"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');
```

## 3. Alternative: Quick Setup via SQL Editor

Run this in Supabase SQL Editor:

```sql
-- Create the bucket (if not created via UI)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Add policies
CREATE POLICY "Allow authenticated users to upload avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Allow users to update own avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Allow users to delete own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Public avatar access"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');
```

## 4. Verify Setup

After setup, you should be able to:
- ✅ Upload profile pictures
- ✅ Update existing profile pictures
- ✅ Delete profile pictures
- ✅ View profile pictures publicly

## Features Implemented

- **Camera/Gallery Selection** - Users can choose to take a photo or pick from gallery
- **Image Compression** - Images are automatically resized to 800x800 max
- **Supabase Storage** - Images stored in secure Supabase bucket
- **Database Integration** - Image URLs saved to user profile
- **Cache Management** - Updated images reflected immediately
- **Remove Photo Option** - Users can remove their profile picture
- **Loading States** - Shows progress during upload/removal
