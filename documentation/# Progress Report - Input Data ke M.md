# Progress Report - Input Data ke MySQL

## Tanggal: 18 Februari 2025

## Deskripsi Pekerjaan
Proses ini mencakup pembuatan database MySQL, pembuatan tabel sesuai dengan desain ERD, serta pengisian data dari hasil pembersihan data (clean data) ke dalam database menggunakan R.

## Tahapan Pekerjaan

### 1. Load Library
- DBI
- RMySQL
- tidyverse
- glue

### 2. Koneksi Ke MySQL (dbngin)
- Mengatur konfigurasi koneksi database:
  - host: 127.0.0.1
  - port: 3308
  - user: root
  - password: [kosong]
  - dbname: film_dashboard
- Membuat koneksi ke MySQL dan membuat database jika belum ada.

### 3. Membuat Entity (Tabel)
Tabel-tabel yang dibuat sesuai ERD:
- `directors` (director_id, director_name)
- `films` (film_id, title, release_year, duration, genre, vote_count, film_rating, director_id)
- `actors` (actor_id, actor_name)
- `casting` (film_id, actor_id)
- `reviewers` (reviewer_id, reviewer_name)
- `reviews` (review_id, film_id, reviewer_id, review_date, review_content, review_rating)

### 4. Read Data
Membaca data hasil wrangling dari folder `data/clean`:
- `directors.csv`
- `films.csv`
- `actors.csv`
- `casting.csv`
- `reviewers.csv`
- `reviews.csv`

### 5. Insert Data ke MySQL
Menggunakan perulangan `for` untuk memasukkan data ke setiap tabel:
- Insert ke tabel `directors`
- Insert ke tabel `films`
- Insert ke tabel `actors`
- Insert ke tabel `casting`
- Insert ke tabel `reviewers`
- Insert ke tabel `reviews` (membersihkan kutip satu terlebih dahulu untuk menghindari error SQL)

### 6. Verifikasi Data
Setelah data dimasukkan, dilakukan verifikasi dengan menjalankan query:
```sql
SELECT * FROM directors;
SELECT * FROM films;
SELECT * FROM actors;
SELECT * FROM casting;
SELECT * FROM reviewers;
SELECT * FROM reviews;
```

### 7. Menutup Koneksi
Menutup koneksi database menggunakan:
```r
dbDisconnect(con)
message("Koneksi ke MySQL ditutup.")
```

## Kendala yang Dihadapi
- Penanganan kutip satu dalam `review_content` untuk menghindari error SQL.
- Penyesuaian `film_id` pada tabel `reviews` agar sesuai dengan `film_id` baru hasil wrangling.

## Status
✅ Pekerjaan selesai dengan sukses.

## File Terkait
- `scripts/input_data_to_mysql.Rmd` (Script R untuk proses input data ke MySQL)
- `data/clean/*.csv` (Data bersih hasil wrangling)
- Database `film_dashboard` di MySQL dengan 6 tabel sesuai ERD.

