# Sprint 2 — YouTube Auto Embed: Final Report

## 1. File yang Diubah

| File | Jenis Perubahan |
|------|----------------|
| [LinkButton.tsx](file:///c:/Users/PC/ultralink/src/app/%5Busername%5D/LinkButton.tsx) | Ditambahkan 2 import + 1 early-return branch untuk YouTube |

**Detail perubahan di `LinkButton.tsx`:**
```diff
+ import { isYoutubeUrl } from "@/utils/youtube";
+ import YoutubeEmbed from "./YoutubeEmbed";

  // Di dalam fungsi LinkButton, sebelum return utama:
+ if (isYoutubeUrl(link.url)) {
+   return <YoutubeEmbed url={link.url} title={link.title} accent={accent} isLight={isLight} />;
+ }
```

---

## 2. File Baru

| File | Deskripsi |
|------|-----------|
| [src/utils/youtube.ts](file:///c:/Users/PC/ultralink/src/utils/youtube.ts) | Helper: `getYoutubeVideoId`, `isYoutubeUrl`, `getYoutubeEmbedUrl` |
| [src/app/\[username\]/YoutubeEmbed.tsx](file:///c:/Users/PC/ultralink/src/app/%5Busername%5D/YoutubeEmbed.tsx) | Komponen iframe embed YouTube yang responsive |

---

## 3. Alasan Setiap Perubahan

### `src/utils/youtube.ts`
- Dibuat di `src/utils/` mengikuti konvensi standar Next.js/React untuk utility functions yang tidak berhubungan dengan UI.
- Dipisahkan dari `PLATFORM_REGISTRY` agar registry tetap bertugas hanya untuk icon, warna, label, dan deteksi platform (sesuai requirement).
- Menggunakan `new URL()` native browser API — tidak butuh library tambahan, tidak ada dependency baru.
- Mendukung semua 4 format URL yang diminta: `youtu.be`, `youtube.com/watch?v=`, `www.youtube.com/watch?v=`, `youtube.com/shorts/`.

### `src/app/[username]/YoutubeEmbed.tsx`
- Diletakkan di samping `LinkButton.tsx` dan `page.tsx` karena ini adalah komponen yang spesifik untuk halaman publik `[username]`.
- Menggunakan `"use client"` karena berada dalam komponen tree yang sudah client-side (`LinkButton` juga `"use client"`).
- Desain konsisten: warna border menggunakan `accent`, mode dark/light mengikuti `isLight`, `rounded-2xl` sesuai dengan `rounded-2xl` yang dipakai `LinkButton`.
- Menggunakan teknik `padding-bottom: 56.25%` (aspect ratio 16:9) untuk mencegah layout shift — tidak perlu `aspect-ratio` CSS yang kurang kompatibel di beberapa browser.
- `loading="lazy"` ditambahkan agar tidak memblok render halaman.

### Modifikasi `LinkButton.tsx`
- Hanya 3 baris tambahan (2 import, 1 early-return `if` block).
- Semua kode lama tidak disentuh — backward-compatible 100%.
- `detectPlatform()`, `PLATFORM_REGISTRY`, `PlatformIcon`, logika link biasa — semuanya tetap utuh.

---

## 4. Potensi Risiko

| Risiko | Tingkat | Catatan |
|--------|---------|---------|
| Video YouTube yang di-embed mungkin diblokir oleh pemilik channel | Rendah | Ini adalah batasan YouTube sendiri, bukan bug aplikasi |
| CSP (Content Security Policy) memblokir iframe YouTube | Sedang | Perlu diverifikasi di production. Jika ada, tambahkan `frame-src https://www.youtube.com` di Next.js headers |
| Tidak ada `trackLinkClick` untuk YouTube embed | Rendah | Saat ini analytics tidak ter-trigger untuk embed (karena tidak ada `onClick` di iframe). Bisa menjadi improvement Sprint 3 |

---

## 5. Cara Kerja Implementasi

```
User membuka halaman publik /{username}
        ↓
page.tsx memanggil getUserLinks() → activeLinks
        ↓
Untuk setiap link → <LinkButton link={...} accent={...} isLight={...} />
        ↓
LinkButton memeriksa: isYoutubeUrl(link.url) ?
        ↓                               ↓
       YA                              TIDAK
        ↓                               ↓
getYoutubeVideoId() → video ID    Render <a href={...}> seperti biasa
        ↓
getYoutubeEmbedUrl() → https://www.youtube.com/embed/{VIDEO_ID}
        ↓
Render <YoutubeEmbed> → responsive 16:9 iframe
```

### Detail ekstraksi Video ID

| Input URL | Video ID yang diekstrak |
|-----------|------------------------|
| `https://youtu.be/dQw4w9WgXcQ` | `dQw4w9WgXcQ` |
| `https://www.youtube.com/watch?v=dQw4w9WgXcQ` | `dQw4w9WgXcQ` |
| `https://youtube.com/watch?v=dQw4w9WgXcQ` | `dQw4w9WgXcQ` |
| `https://youtube.com/shorts/dQw4w9WgXcQ` | `dQw4w9WgXcQ` |
| URL non-YouTube | `null` → tampil sebagai button biasa |

---

## 6. Cara Pengujian Manual

### Setup
1. Pastikan dev server berjalan: `npm run dev`
2. Login ke dashboard dan tambahkan link dengan URL YouTube

### Test Case 1 — `youtu.be`
- Tambahkan link: URL = `https://youtu.be/dQw4w9WgXcQ`, Title = "Rick Roll"
- Buka halaman publik `/{username}`
- **Expected:** Muncul iframe video YouTube dengan judul "Rick Roll" di atas

### Test Case 2 — `youtube.com/watch?v=`
- Tambahkan link: URL = `https://www.youtube.com/watch?v=dQw4w9WgXcQ`, Title = "YouTube Watch"
- **Expected:** Sama seperti Test Case 1

### Test Case 3 — `youtube.com/shorts/`
- Tambahkan link: URL = `https://youtube.com/shorts/ABCDEF12345`, Title = "YouTube Shorts"
- **Expected:** Muncul iframe embed video Shorts

### Test Case 4 — URL non-YouTube (Backward Compat)
- Tambahkan link: URL = `https://instagram.com/username`, Title = "Instagram"
- **Expected:** Tampil sebagai button link biasa dengan icon Instagram, tidak ada iframe

### Test Case 5 — Mixed links
- Tambahkan beberapa link: 1 YouTube + 2 non-YouTube
- **Expected:** YouTube tampil sebagai embed, lainnya sebagai button — keduanya di halaman yang sama tanpa masalah layout

### Test Case 6 — Mobile
- Buka halaman publik di viewport mobile (DevTools → 375px)
- **Expected:** Iframe YouTube tetap responsive 16:9, tidak overflow, tidak ada horizontal scroll

---

## Rekomendasi untuk Sprint Berikutnya

> Catatan: Item-item berikut **tidak diubah** dalam sprint ini sesuai aturan. Dicatat di sini sebagai rekomendasi saja.

1. **Analytics untuk YouTube embed** — Tambahkan `trackLinkClick` menggunakan `IntersectionObserver` atau wrapper `<div onClick>` di sekitar iframe.
2. **Pre-existing TypeScript errors** — 6 file di `src/config/platforms/` (facebook, instagram, tiktok, whatsapp, x, youtube) memiliki error `'React' is declared but its value is never read`. Ini bisa diselesaikan dengan menghapus `import React from "react"` yang tidak diperlukan (JSX transform modern sudah tidak membutuhkannya).
3. **Thumbnail-first embed** — Pertimbangkan menampilkan thumbnail dulu, baru load iframe saat diklik (lite-embed pattern) untuk performa halaman publik dengan banyak link YouTube.
