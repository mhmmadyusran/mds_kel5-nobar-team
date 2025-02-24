# Progress Report - Data Wrangling

## Tanggal: 17 Februari 2025

## Task: Data Wrangling

### Deskripsi Pekerjaan
- Menggabungkan 4 tabel mentah: film, sutradara, aktor, reviews.
- Membersihkan data:
  - Menghapus kolom yang redundan.
  - Mengganti nama kolom sesuai standar.
  - Menangani nilai "nan" dan NA pada kolom aktor.
  - Mengubah `review_date` menjadi tipe tanggal.
  - Mengisi `NA` pada kolom review dengan nilai default.
- Membentuk 6 tabel sesuai ERD:
  - `films`
  - `directors`
  - `actors`
  - `casting`
  - `reviewers`
  - `reviews`
- Menyusun primary key pada masing-masing tabel agar rapi dan terurut.

### Hasil Akhir
- Data bersih tersimpan dalam folder `data/clean/`:
  - `films.csv`
  - `directors.csv`
  - `actors.csv`
  - `casting.csv`
  - `reviewers.csv`
  - `reviews.csv`

### Kendala
- Ditemukan string `"nan"` pada kolom `actors`, telah ditangani.

### Status: ✅ SELESAI

### Catatan Tambahan
- Siap dilanjutkan ke tahap Import ke MySQL.
