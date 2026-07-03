# Peta Dependensi — Sistem Tautan UltraLink

Laporan ini mencatat setiap simbol/fungsi terkait sistem tautan, mulai dari tempat definisi (*defined at*) hingga setiap file yang menggunakannya (*used by*).

---

## Ringkasan Peta Dependensi

```
src/types/index.ts                    ← DEFINISI: UserLink
    │
    ├── src/services/firestore.ts     ← mengimport UserLink (digunakan oleh fungsi: getUserLinks, addLink, updateLink)
    │       │
    │       │   Fungsi yang diekspor (berinteraksi dengan Firestore "links" collection):
    │       │   ├── getUserLinks()  ←── dipanggil oleh:
    │       │   │       ├── src/app/[username]/page.tsx        (render publik)
    │       │   │       ├── src/app/dashboard/page.tsx         (kalkulasi total klik)
    │       │   │       ├── src/app/dashboard/links/page.tsx   (manajemen link)
    │       │   │       └── src/services/firestore.ts          (self-call internal dari addLink)
    │       │   │
    │       │   ├── addLink()       ←── dipanggil oleh:
    │       │   │       └── src/app/dashboard/links/page.tsx
    │       │   │
    │       │   └── updateLink()    ←── dipanggil oleh:
    │       │           └── src/app/dashboard/links/page.tsx   (edit, toggle aktif, swap posisi)
    │       │
    ├── src/services/seed.ts         ← mengimport UserLink (utilitas seeding data awal)
    ├── src/config/dummyData.ts      ← mengimport UserLink (data dummy statis, tidak digunakan di runtime)
    └── src/app/[username]/LinkButton.tsx ← mengimport UserLink (prop komponen)

src/config/platforms.tsx              ← DEFINISI: detectPlatform()
    │
    └── src/app/[username]/LinkButton.tsx ← mengimport & memanggil detectPlatform()

src/app/[username]/LinkButton.tsx     ← DEFINISI: komponen LinkButton
    │
    └── src/app/[username]/page.tsx   ← mengimport & merender <LinkButton />
```

---

## Detail Per Simbol

### 1. `UserLink` (TypeScript Interface)

| Peran | File | Baris |
|:---|:---|:---|
| **DEFINISI** | [src/types/index.ts](file:///c:/Users/PC/ultralink/src/types/index.ts#L16) | L16 |
| Import | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L16) | L16 |
| Import | [src/services/seed.ts](file:///c:/Users/PC/ultralink/src/services/seed.ts#L3) | L3 |
| Import | [src/config/dummyData.ts](file:///c:/Users/PC/ultralink/src/config/dummyData.ts#L1) | L1 |
| Import | [src/app/\[username\]/LinkButton.tsx](file:///c:/Users/PC/ultralink/src/app/[username]/LinkButton.tsx#L5) | L5 |
| Import | [src/app/dashboard/links/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/links/page.tsx#L6) | L6 |

---

### 2. Koleksi Firestore `"links"` (Direct DB Access)

> Semua akses ke koleksi Firestore `"links"` terpusat di dalam satu file service.

| Peran | File | Baris | Konteks |
|:---|:---|:---|:---|
| `collection(db, "links")` | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L94) | L94 | Di dalam `getUserLinks()` |
| `collection(db, "links")` | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L122) | L122 | Di dalam `addLink()` |
| `doc(db, "links", linkId)` | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L132) | L132 | Di dalam `updateLink()` |
| `doc(db, "links", linkId)` | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L142) | L142 | Di dalam `deleteLink()` |
| `collection(db, "links")` | [src/services/seed.ts](file:///c:/Users/PC/ultralink/src/services/seed.ts#L44) | L44 | Di dalam `seedDummyData()` |

---

### 3. `getUserLinks()`

| Peran | File | Baris | Konteks |
|:---|:---|:---|:---|
| **DEFINISI** | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L92) | L92 | Fungsi async |
| Self-call internal | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L116) | L116 | Dipanggil dari dalam `addLink()` untuk validasi batas 5 tautan |
| Import + Panggil | [src/app/\[username\]/page.tsx](file:///c:/Users/PC/ultralink/src/app/[username]/page.tsx#L2) | L2, L32 | Server Component: ambil link aktif untuk render halaman publik |
| Import + Panggil | [src/app/dashboard/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/page.tsx#L5) | L5, L20 | Client Component: kalkulasi total klik di overview dashboard |
| Import + Panggil | [src/app/dashboard/links/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/links/page.tsx#L5) | L5, L25 | Client Component: load daftar link untuk manajemen (CRUD) |

---

### 4. `addLink()`

| Peran | File | Baris | Konteks |
|:---|:---|:---|:---|
| **DEFINISI** | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L111) | L111 | Dengan validasi batas 5 tautan; memanggil `getUserLinks()` secara internal |
| Import + Panggil | [src/app/dashboard/links/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/links/page.tsx#L5) | L5, L56 | Dipanggil saat user menekan tombol "Tambahkan" di form |

---

### 5. `updateLink()`

| Peran | File | Baris | Konteks |
|:---|:---|:---|:---|
| **DEFINISI** | [src/services/firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts#L130) | L130 | |
| Import + Panggil (edit data) | [src/app/dashboard/links/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/links/page.tsx#L52) | L52 | Mode edit: simpan title & url baru |
| Panggil (toggle aktif) | [src/app/dashboard/links/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/links/page.tsx#L78) | L78 | Toggle switch aktif/nonaktif link |
| Panggil (swap posisi) | [src/app/dashboard/links/page.tsx](file:///c:/Users/PC/ultralink/src/app/dashboard/links/page.tsx#L127-L128) | L127, L128 | Digunakan dua kali bersamaan via `Promise.all()` untuk swap urutan posisi |

---

### 6. `detectPlatform()`

| Peran | File | Baris | Konteks |
|:---|:---|:---|:---|
| **DEFINISI** | [src/config/platforms.tsx](file:///c:/Users/PC/ultralink/src/config/platforms.tsx#L196) | L196 | Mencocokkan URL ke registry platform |
| Import + Panggil | [src/app/\[username\]/LinkButton.tsx](file:///c:/Users/PC/ultralink/src/app/[username]/LinkButton.tsx#L6) | L6, L9 | Dipanggil di komponen `PlatformIcon` (inner component) |

---

### 7. `LinkButton` (React Component)

| Peran | File | Baris | Konteks |
|:---|:---|:---|:---|
| **DEFINISI** | [src/app/\[username\]/LinkButton.tsx](file:///c:/Users/PC/ultralink/src/app/[username]/LinkButton.tsx#L45) | L45 | Client Component, menerima prop `link: UserLink`, `accent`, `isLight` |
| Import + Render | [src/app/\[username\]/page.tsx](file:///c:/Users/PC/ultralink/src/app/[username]/page.tsx#L6) | L6, L73 | Dirender per item di dalam loop `activeLinks.map(...)` |

---

## Diagram Dependensi Lengkap (Level File)

```
src/types/index.ts
    ↑ (diimport oleh)
    ├── src/services/firestore.ts
    │       ↑ (diimport oleh)
    │       ├── src/app/[username]/page.tsx          → getUserLinks
    │       ├── src/app/dashboard/page.tsx           → getUserLinks
    │       └── src/app/dashboard/links/page.tsx     → getUserLinks, addLink, updateLink
    │
    ├── src/services/seed.ts                         → (utilitas, tidak terhubung ke UI)
    ├── src/config/dummyData.ts                      → (data statis, tidak terhubung ke UI)
    └── src/app/[username]/LinkButton.tsx
            ↑ (diimport oleh)
            └── src/app/[username]/page.tsx

src/config/platforms.tsx
    ↑ (diimport oleh)
    └── src/app/[username]/LinkButton.tsx
```

---

## Kesimpulan

| Simbol | File Definisi | Jumlah Pemakai (Consumer) |
|:---|:---|:---:|
| `UserLink` | `src/types/index.ts` | **5 file** |
| Koleksi `"links"` | `src/services/firestore.ts` | **1 file** (terpusat) + `seed.ts` |
| `getUserLinks()` | `src/services/firestore.ts` | **3 file** + 1 self-call internal |
| `addLink()` | `src/services/firestore.ts` | **1 file** |
| `updateLink()` | `src/services/firestore.ts` | **1 file** (3 titik panggil) |
| `detectPlatform()` | `src/config/platforms.tsx` | **1 file** |
| `LinkButton` | `src/app/[username]/LinkButton.tsx` | **1 file** |

> **Catatan penting:** Seluruh operasi tulis/baca ke koleksi Firestore `"links"` hanya boleh diakses melalui abstraksi di [firestore.ts](file:///c:/Users/PC/ultralink/src/services/firestore.ts). Tidak ada file UI yang mengakses Firestore secara langsung untuk koleksi ini, kecuali `seed.ts`.
