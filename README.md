# 🌍 SeismoGuard — Seismic Activity Data Warehouse

> **Data Warehouse berbasis Medallion Architecture untuk analitik kegempaan Indonesia**  
> Mendukung Business Intelligence, Sistem Pendukung Keputusan (DSS) Mitigasi Bencana, dan Early Warning System berbasis data BMKG.

---

## 📌 Deskripsi Proyek

**SeismoGuard** adalah proyek Data Warehouse yang memproses data historis aktivitas gempa bumi di Indonesia melalui pipeline ETL (Extract, Transform, Load) berbasis Python dan PostgreSQL (Supabase). Proyek ini menerapkan **Medallion Architecture** (Bronze → Silver → Gold) yang menghasilkan **Star Schema** siap pakai untuk analitik dan visualisasi.

### 🎯 Dirancang untuk:

| Kebutuhan | Deskripsi |
|---|---|
| **Business Intelligence (BI)** | Visualisasi tren dan pola kegempaan nasional |
| **DSS Mitigasi Bencana** | Rekomendasi prioritas wilayah rawan untuk alokasi sumber daya |
| **Dashboard Analitik** | Monitoring frekuensi, magnitudo, dan distribusi gempa |
| **Early Warning System** | Deteksi anomali berbasis data historis yang terstruktur |

---

## 🗂️ Struktur File

```
project-folder/
├── katalog_gempa.csv                    # Dataset mentah dari Kaggle/BMKG
├── katalog_gempa_downloadable.csv       # Dataset hasil transformasi awal (Python)
├── PRAKTIKUM_AVD_Checkpoint_2.ipynb     # Notebook proses pembersihan data
├── init_database.sql                    # Script pembuatan schema (Medallion)
├── ddl_bronze_silver.sql                # Script ETL untuk layer Bronze & Silver
├── ddl_gold_star_schema.sql             # Script SQL untuk Data Warehouse akhir (Gold)
└── README.md                            # Dokumentasi proyek
```

---

## 📁 Deskripsi File

### 1. `katalog_gempa.csv`
Dataset mentah berisi rekam jejak aktivitas gempa bumi di Indonesia.

| Kolom | Deskripsi |
|---|---|
| `tgl` | Tanggal kejadian gempa |
| `ot` | Origin Time — waktu tepat kejadian |
| `lat` | Latitude / Garis Lintang |
| `lon` | Longitude / Garis Bujur |
| `depth` | Kedalaman gempa (km) |
| `mag` | Magnitudo gempa |
| `remark` | Keterangan wilayah asal |
| `strike1`, `dip1`, `rake1`, dst. | Parameter mekanis (dominan kosong) |

### 2. `katalog_gempa_downloadable.csv`
Dataset pasca-transformasi menggunakan Python Pandas. Perubahan utama:
- ✅ Penghapusan kolom mekanis tidak relevan (`strike`, `dip`, `rake`)
- ✅ Penambahan kolom **feature engineering**: `Keterangan` — klasifikasi status gempa berdasarkan ambang batas magnitudo (contoh: *"Gempa Sedang"*, *"Gempa Terasa Jelas"*)

### 3. `PRAKTIKUM_AVD_Checkpoint_2.ipynb`
Notebook Python yang menjalankan seluruh alur Data Cleaning:
- Penanganan **missing values** (kolom >97% kosong dihapus)
- Analisis **outliers** pada kedalaman dan magnitudo menggunakan metode IQR
- Pembuatan **logika klasifikasi** status gempa untuk fitur DSS

### 4. Script SQL (Supabase)
Kumpulan script untuk membangun Data Warehouse di PostgreSQL dengan Medallion Architecture:

| File | Fungsi |
|---|---|
| `init_database.sql` | Membuat schema `bronze`, `silver`, dan `gold` |
| `ddl_bronze_silver.sql` | Definisi tabel + proses ETL dari Bronze ke Silver |
| `ddl_gold_star_schema.sql` | Pembentukan Star Schema di lapisan Gold |

---

## 🏗️ Arsitektur Data: Medallion Architecture

SeismoGuard mengadopsi **Medallion Architecture** — pola desain data yang mengatur pemrosesan ke dalam tiga lapisan logis secara bertahap. Setiap lapisan meningkatkan kualitas data sebelum akhirnya dikonsumsi oleh aplikasi DSS dan dashboard analitik.

```
📥 Sumber Data (CSV / BMKG)
          │
          ▼
┌─────────────────────┐
│   🥉 BRONZE LAYER   │  ← Raw Data (disimpan apa adanya, tipe TEXT)
│  bronze.crm_gempa_raw│
└─────────┬───────────┘
          │  Type Casting + Deduplication + Validasi
          ▼
┌─────────────────────┐
│   🥈 SILVER LAYER   │  ← Cleaned & Validated (DATE, DECIMAL, INT)
│  silver.gempa_clean  │
└─────────┬───────────┘
          │  Ekstraksi DISTINCT + JOIN ke Star Schema
          ▼
┌─────────────────────────────────────────┐
│              🥇 GOLD LAYER              │
│                                         │
│  ┌───────────┐      ┌───────────────┐   │
│  │ dim_waktu │◄─────│  fact_gempa   │   │
│  └───────────┘      └──────┬────────┘   │
│                             │            │
│                    ┌────────▼──────┐    │
│                    │  dim_lokasi   │    │
│                    └───────────────┘   │
└─────────────────────────────────────────┘
```

---

### 🥉 Bronze Layer — *Raw Data*

**Apa itu?**  
Lapisan pertama tempat data mendarat langsung dari sumber eksternal (CSV BMKG/Kaggle). Data disimpan **apa adanya** dengan tipe data `TEXT` tanpa modifikasi apapun.

**Kenapa diterapkan?**  
Berfungsi sebagai **Audit Trail**. Jika terdapat kesalahan logika di masa depan, kita selalu memiliki salinan data asli tanpa harus meminta ulang ke sumber. Prinsipnya: *"simpan dulu, proses belakangan."*

---

### 🥈 Silver Layer — *Cleaned & Validated*

**Apa itu?**  
Lapisan tengah di mana data dari Bronze dibersihkan, divalidasi, dan distandarisasi di dalam PostgreSQL.

**Kenapa diterapkan?**  
Untuk menjamin **Integritas Data**. Pada tahap ini dilakukan:
- Penghapusan **data duplikat**
- Penanganan **missing values**
- **Type Casting**: konversi teks ke format `DATE`, `DECIMAL`, dan `INT`

Data di Silver sudah *"setengah matang"* — dapat dipercaya tetapi belum dioptimalkan untuk query analitik.

---

### 🥇 Gold Layer — *Curated / Presentation*

**Apa itu?**  
Lapisan final yang sepenuhnya siap dikonsumsi oleh aplikasi SeismoGuard, dashboard BI, maupun sistem DSS.

**Kenapa diterapkan?**  
Untuk **Performa Analitik Maksimal**. Data disusun menggunakan **Star Schema** (Tabel Fakta & Dimensi), sehingga query dapat berjalan sangat cepat karena database tidak perlu melakukan kalkulasi berat berulang kali saat diakses.

---

### 🛠️ Mengapa Medallion Architecture?

| Alasan | Penjelasan |
|---|---|
| **Standar Industri** | Pola ini digunakan di dunia kerja nyata (Data Engineering / Lakehouse) |
| **Skalabilitas** | Penambahan sumber data baru cukup dimasukkan ke Bronze, tanpa merusak alur yang berjalan |
| **Kualitas Keputusan** | Lapisan Silver memastikan tidak ada data "sampah" yang memicu peringatan palsu (*false alarm*) pada DSS |

---

## ⭐ Struktur Star Schema (Lapisan Gold)

### `dim_lokasi` — Dimensi Lokasi

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id_lokasi` | SERIAL (PK) | Primary Key |
| `latitude` | DECIMAL | Garis Lintang |
| `longitude` | DECIMAL | Garis Bujur |
| `wilayah` | TEXT | Nama wilayah kejadian |

### `dim_waktu` — Dimensi Waktu

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id_waktu` | SERIAL (PK) | Primary Key |
| `tanggal` | DATE | Tanggal lengkap |
| `tahun` | INT | Tahun kejadian |
| `bulan` | INT | Bulan kejadian |
| `hari` | INT | Hari kejadian |

### `fact_gempa` — Tabel Fakta

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id_fakta` | SERIAL (PK) | Primary Key |
| `id_waktu` | INT (FK) | Referensi ke `dim_waktu` |
| `id_lokasi` | INT (FK) | Referensi ke `dim_lokasi` |
| `magnitudo` | DECIMAL | Kekuatan gempa |
| `kedalaman` | INT | Kedalaman gempa (km) |
| `status_gempa` | TEXT | Kategori gempa |

---

## ⚙️ Proses ETL

### Extract → Bronze
Data dari `katalog_gempa_downloadable.csv` diimpor ke `bronze.crm_gempa_raw` sebagai teks murni untuk menjaga jejak audit yang utuh.

### Transform → Silver
Pembersihan data lanjutan di dalam PostgreSQL:
- Konversi format `"YYYY/MM/DD"` (teks) → tipe data `DATE`
- Standarisasi format desimal untuk koordinat dan magnitudo
- Penghapusan duplikat dan validasi nilai

### Load → Gold
- Ekstraksi nilai unik (`DISTINCT`) dari Silver ke tabel dimensi (`dim_waktu`, `dim_lokasi`)
- Operasi `JOIN` untuk membangun `fact_gempa` dengan relasi kunci (FK) yang utuh dan terstruktur

---

## 📊 Analisis yang Didukung

Data warehouse SeismoGuard siap mendukung berbagai skenario analitik:

- 🗺️ **Heatmap Kerawanan** — Identifikasi wilayah dengan frekuensi gempa tertinggi
- 📈 **Tren Waktu** — Frekuensi kejadian per tahun/bulan
- 📉 **Distribusi Magnitudo** — Proporsi kategori gempa (Sedang vs. Terasa Jelas)
- 🚨 **Prioritas Mitigasi** — Rekomendasi penyaluran dana darurat berbasis data

---

## 💡 Contoh Query Analisis

### Frekuensi Gempa per Tahun
```sql
SELECT w.tahun, COUNT(f.id_fakta) AS total_kejadian
FROM gold.fact_gempa f
JOIN gold.dim_waktu w ON f.id_waktu = w.id_waktu
GROUP BY w.tahun
ORDER BY w.tahun DESC;
```

### Top 5 Wilayah Paling Sering Gempa
```sql
SELECT l.wilayah, COUNT(f.id_fakta) AS frekuensi
FROM gold.fact_gempa f
JOIN gold.dim_lokasi l ON f.id_lokasi = l.id_lokasi
GROUP BY l.wilayah
ORDER BY frekuensi DESC
LIMIT 5;
```

### Rata-rata Magnitudo per Kategori Gempa
```sql
SELECT status_gempa, ROUND(AVG(magnitudo), 2) AS rata_rata_mag
FROM gold.fact_gempa
GROUP BY status_gempa
ORDER BY rata_rata_mag DESC;
```

---

## 🚀 Cara Menjalankan Proyek

### 1. Pembersihan Awal (Opsional)
Buka `PRAKTIKUM_AVD_Checkpoint_2.ipynb` di Google Colab untuk menjalankan proses data cleaning dan feature engineering dengan Python Pandas.

### 2. Setup Database di Supabase
Buat project baru di [Supabase](https://supabase.com) dan buka **SQL Editor** di dashboard.

### 3. Jalankan Script Medallion (Berurutan)
```
1. init_database.sql        → Buat schema bronze, silver, gold
2. ddl_bronze_silver.sql    → Buat tabel dan ETL Bronze ke Silver
3. ddl_gold_star_schema.sql → Buat Star Schema di Gold
```

### 4. Import Data
Gunakan fitur **Import Data** di Supabase untuk memuat `katalog_gempa_downloadable.csv` ke dalam tabel `bronze.crm_gempa_raw`.

### 5. Populate Star Schema
Jalankan query DML (`INSERT INTO ... SELECT`) untuk memindahkan dan mentransformasi data dari Bronze hingga ke Gold secara berurutan.

---

## 🧰 Teknologi yang Digunakan

| Teknologi | Kegunaan |
|---|---|
| **Python** (Pandas, NumPy) | Data Cleaning & Feature Engineering |
| **Jupyter Notebook / Google Colab** | Eksplorasi dan dokumentasi proses ETL awal |
| **PostgreSQL** (via Supabase) | Database utama Data Warehouse |
| **SQL** | Implementasi Medallion Architecture & Star Schema |

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan akademik dan riset. Dataset bersumber dari katalog publik BMKG/Kaggle.

---

*SeismoGuard — Membangun fondasi data yang kuat untuk Indonesia yang lebih siap menghadapi bencana.*
