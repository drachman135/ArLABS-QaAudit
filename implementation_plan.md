# Implementation Plan — Background Music System & Admin Dashboard

This plan outlines the design, architecture, database schemas, styling, and JavaScript logic to implement a complete production-ready **Background Music System** integrated with **Supabase Database & Storage**, along with a dedicated **Admin Dashboard (`admin.html`)**.

## User Review Required

> [!IMPORTANT]
> - **Supabase Settings Table**: We will use a database table named `invitation_settings` (or `music_settings`) to store dynamic music properties:
>   - `background_music_url` (text, URL of the MP3/M4A hosted on Supabase Storage).
>   - `music_enabled` (boolean).
>   - `music_volume` (float, range 0.0 to 1.0).
>   - `loading_duration` (integer, range 2000 to 4000 ms).
>   - `music_updated_at` (timestamp).
> - **Supabase Storage Bucket**: We will require a bucket named `music` configured with **Public Access** so the guest client can download and play the audio files without authentication.
> - **Graceful degradation**: If Supabase configuration is missing or a network error occurs, the website will skip audio playback silently and transition to the invitation page normally, with no console errors or broken interfaces.
> - **Transition Flow**: The music will play *only* after loading is complete, synchronized with the fade-in of the main invitation.
> - **Admin Credentials**: The admin dashboard will read Supabase configurations from a shared configuration module or allow setting them dynamically in a settings form (saved in `localStorage` for ease of use).

---

## Proposed Schema & Config Setup

### 1. Database Table Structure
Create a table in Supabase called `invitation_settings`:
```sql
CREATE TABLE invitation_settings (
    id SERIAL PRIMARY KEY,
    background_music_url TEXT,
    music_enabled BOOLEAN DEFAULT TRUE,
    music_volume FLOAT DEFAULT 0.4,
    loading_duration INTEGER DEFAULT 3000,
    music_updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial default setting row
INSERT INTO invitation_settings (id, background_music_url, music_enabled, music_volume, loading_duration)
VALUES (1, NULL, TRUE, 0.4, 3000);
```

### 2. Storage Bucket
Create a storage bucket in Supabase named `music` and set it as **Public**.

---

## Proposed Changes

### Configuration Setup

#### [NEW] [supabase.js](file:///d:/aezakmi/website/big-wheels-birthday/js/supabase.js)
Define a central configuration module to initialize the Supabase client:
- Define `SUPABASE_URL` and `SUPABASE_ANON_KEY` placeholders.
- Handle fallback initialization if properties are unset.

---

### Invitation Interface & Logic

#### [MODIFY] [index.html](file:///d:/aezakmi/website/big-wheels-birthday/index.html)
- Import Supabase JS CDN script inside the `<head>` tag.
- Append a modern floating button (`#floating-music-btn`) with sound icons (`🔊` / `🔇`) inside the body:
  ```html
  <button id="floating-music-btn" class="floating-music-btn" aria-label="Jeda Musik" aria-pressed="false">
      <span class="music-icon">🔊</span>
  </button>
  ```

#### [MODIFY] [style.css](file:///d:/aezakmi/website/big-wheels-birthday/css/style.css)
- Style the floating music control:
  - Fixed position at the bottom-right (or bottom-left on mobile to prevent overlapping other interactive CTAs).
  - Glassmorphic look: semi-transparent dark background, blur filters, and subtle rotation/pulse transitions.
  - Set `display: none` by default; make it slide in and become visible once the main invitation is loaded.
- Style the Stage 4 loading screen elements to ensure a premium loading appearance with smooth CSS transitions.

#### [MODIFY] [js/main.js](file:///d:/aezakmi/website/big-wheels-birthday/js/main.js)
- Fetch settings row from `invitation_settings` table on load.
- If music is enabled and a URL exists:
  - Instantiate `new Audio(url)`.
  - Loop and set default volume.
  - Preload audio buffer silently.
- Modify `startEnterAnimation()`:
  - Calculate visual speed ticks matching the loaded `loading_duration` parameter.
- Modify `handOff()`:
  - Check if the user had previously paused the music in the current session (`sessionStorage.getItem('music_paused') === 'true'`).
  - If not paused, trigger `.play()` on the audio object.
  - Fade out the loading screen and fade in `.main-content`.
  - Reveal the floating music button.
- Implement click listeners on the floating music button to toggle play/pause states, update session storage preferences, and change sound emoji representations with smooth transitions.

---

### Admin Dashboard Module

#### [NEW] [admin.html](file:///d:/aezakmi/website/big-wheels-birthday/admin.html)
A premium dashboard page for admin configuration:
- Supabase Project Details form (inputs for URL and Key, saved to local storage so the admin doesn't need to re-enter them).
- Settings Dashboard:
  - Toggle switch for `music_enabled`.
  - Numeric inputs/ranges for `music_volume` (0.0 to 1.0) and `loading_duration` (2000 to 4000 ms).
  - Custom file drop-zone interface supporting MP3 and M4A audio formats.
  - Built-in dynamic audio player to preview the current background music file.
  - "Simpan Konfigurasi" (Save Configuration) CTA button.
- Styling: Luxury dark theme matching the navy-gold visual concepts of the main invitation.

#### [NEW] [js/admin.js](file:///d:/aezakmi/website/big-wheels-birthday/js/admin.js)
JavaScript code driving the admin dashboard:
- Connect to Supabase using local storage credentials.
- Fetch current settings from `invitation_settings` and update form fields on load.
- File upload handlers:
  - Validate files (reject any format other than `audio/mp3`, `audio/mpeg`, `audio/x-m4a`, `audio/mp4`).
  - Upload file to Supabase `music` bucket under name `background_music_[timestamp].mp3` (or original name).
  - Get public URL of the uploaded file.
  - Update settings in `invitation_settings` table (including toggles, volume, duration, and updated timestamp).
- Handle delete and settings updates cleanly.

---

## Verification Plan

### Automated / Syntax Check
- Verify JavaScript file formats.
- Ensure audio files are handled without exceptions.

### Manual Verification
- **Admin Dashboard Test**:
  1. Open `admin.html` and input Supabase credentials.
  2. Toggle settings, set volume to `0.5`, loading duration to `3500ms`.
  3. Drop an invalid file (e.g. PNG image) and confirm it is rejected with an alert.
  4. Drop a valid MP3 file, confirm successful upload, and play it in the preview audio player.
  5. Save settings and verify database row updates.
- **Invitation Test**:
  1. Open `index.html` and verify intro stage works.
  2. Complete invitation opening, verify loading screen appears and runs for `3500ms`.
  3. Verify music starts playing automatically when the loading finishes and the main page fades in.
  4. Click the floating music button to pause it; reload and verify it remembers the paused preference (no autoplay on reload).
  5. Clear session storage, reload, click to play, scroll down and verify audio plays continuously.
