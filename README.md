![poster](docs/visuals/poster.png)
# SasimokGuard: End-to-End Real-Time Earthquake Data Pipeline & Early Warning System

## Project Overview
Proyek ini mendemonstrasikan pengembangan *data warehouse* modern dan Sistem Pendukung Keputusan (DSS) menggunakan PostgreSQL (Supabase). Arsitektur sistem ini mencakup pemrosesan data historis (*batch processing*) dan proses ETL *real-time*, arsitektur data berlapis (*Staging* dan *Gold Layer*), pemodelan data dimensional, serta integrasi notifikasi darurat. Fokus utama proyek ini adalah membersihkan data historis untuk analisis dasar dan mentransformasi aliran data mentah aktivitas kegempaan global secara terus-menerus menjadi format terstruktur untuk mendukung analisis spasial, pelaporan tren, serta memicu *Early Warning System* (EWS) secara otomatis.

## Objectives
Membangun *data warehouse* dan sistem pemantauan gempa bumi terpadu menggunakan PostgreSQL untuk menyatukan data seismik dari berbagai institusi dan dataset historis ke dalam satu sistem terpusat (*Single Source of Truth*). Pendekatan terstruktur ini memungkinkan manajemen data yang lebih baik dan akurasi tinggi. Dengan mentransformasi aliran data mentah dan data historis menjadi *dataset* yang siap pakai, proyek ini bertujuan untuk mendukung pelaporan *Business Intelligence* (BI) yang jelas, memicu notifikasi darurat berbasis lokasi, dan membantu pengambilan keputusan mitigasi yang digerakkan oleh data (*data-driven*).

## Tech Stack
- **Database / Data Warehouse**: PostgreSQL (Supabase)
- **Environment**: Google Colab (Jupyter Notebook) / Python Runtime
- **Programming Language**: Python (Pandas, Requests, Google Auth)
- **Notification Service**: Firebase Cloud Messaging (FCM) v1 API
- **ETL Workflow**: Python Core & Supabase Client Engine
- **Architecture**: Layered Architecture (Staging `public` → Business `gold`)
- **Modeling**: Star Schema (Fact and Dimension tables)
- **Data Sources**: API Terbuka (BMKG, USGS, EMSC) & Dataset Kaggle

## ETL Workflow Overview
1. **Data Ingestion (Extract)**
   - **Batch / Historical**: Menarik dan membaca data historis gempa bumi Indonesia dari dataset Kaggle.
   - **Real-time**: Menarik data aktivitas gempa bumi secara *real-time* dari API publik BMKG, USGS, dan EMSC setiap 30 detik.
2. **Data Transformation & EWS**
   - Membersihkan data mentah (baik historis maupun *real-time*), menyeragamkan format, dan menangani nilai yang hilang (*missing values*).
   - Menerapkan logika bisnis (formula *Haversine*) pada jalur *real-time* untuk menghitung jarak episentrum terhadap pengguna, lalu memicu notifikasi FCM berdasarkan klasifikasi tingkat bahaya.
3. **Data Loading (Staging)**
   - Memuat data operasional *real-time* ke dalam tabel `public.gempa_live` menggunakan metode *truncate-and-load* di setiap siklus.
4. **Data Modeling**
   - Mendesain dan mengimplementasikan *star schema* pada lapisan analitik untuk menampung data historis yang sudah bersih:
     - `fact_gempa`
     - `dim_waktu`
     - `dim_lokasi`
5. **Analysis & Reporting**
   - Menyediakan *dataset* di lapisan *Gold* yang siap dikueri untuk menemukan tren aktivitas seismik dan mendukung visualisasi *dashboard*.

## Data Architecture
Sistem ini menggunakan pendekatan pemisahan area operasional dan area analitik.

1. **Staging Layer (Lapisan Operasional - `public`)**
   - Menampung data mentah representasi kondisi lapangan terkini (`gempa_live`).
   - Diperbarui secara *real-time* tanpa proses transformasi berat.
   - Bertindak sebagai *trigger* operasional untuk algoritma Sistem Peringatan Dini.
2. **Gold Layer (Lapisan Bisnis - `gold` schema)**
   - Membangun tabel dimensi dan fakta analitik menggunakan *Star Schema*.
   - Menyimpan data terstruktur jangka panjang yang telah divalidasi (termasuk data historis pembersihan awal).
   - Digunakan secara langsung untuk pelaporan, *dashboard* BI, dan analisis mitigasi kebencanaan.

## Data Integration
Proyek ini mengintegrasikan dataset historis serta data *payload* awal yang berbeda-beda dari tiga domain platform seismologi utama di dunia:
1. **Kaggle (Indonesia Historical Data)**: [Dataset Earthquakes in Indonesia](https://www.kaggle.com/datasets/kekavigi/earthquakes-in-indonesia?select=katalog_gempa.csv) untuk keperluan *data cleaning*, analisis historis awal, dan pemodelan dasar.
2. **BMKG (Indonesia)**: Data gempa bumi terkini dan gempa dirasakan di wilayah Nusantara.
3. **USGS (Amerika Serikat)**: Data GeoJSON aktivitas gempa global dalam rentang waktu satu jam terakhir.
4. **EMSC (Eropa)**: Data terbaru berskala internasional dari portal seismik Eropa dan Mediterania.

## Data Modeling — Star Schema
Arsitektur data pada lapisan **Gold Layer** dirancang menggunakan *Star Schema* yang terdiri dari:
- Satu tabel pusat **Fact Table**:
  - `gold.fact_gempa`
- Didukung oleh dua **Dimension Tables**:
  - `gold.dim_waktu`
  - `gold.dim_lokasi`

## Gold Layer Table Snapshots
Lapisan bisnis (Gold Layer) menyajikan representasi data yang telah dioptimalkan untuk kasus penggunaan analitik dan pelaporan tren kegempaan.
### `gold.dim_waktu`
Menyimpan dekomposisi waktu kejadian gempa (tanggal, bulan, tahun) untuk memudahkan analisis berbasis tren waktu historis.
### `gold.dim_lokasi`
Menyimpan data koordinat presisi (*latitude* & *longitude*) beserta nama wilayah geografis episentrum gempa untuk mendukung analisis spasial.
### `gold.fact_gempa`
Merekam metrik kuantitatif transaksional seperti magnitudo dan kedalaman (*depth*) gempa yang terikat erat dengan relasi *foreign key* dari tabel dimensi waktu maupun lokasi.

## Features
- **Historical Data Cleaning**: Alur pembersihan data terstruktur untuk dataset Kaggle sebelum dimasukkan ke dalam *Data Warehouse*.
- **End-to-End Real-Time Pipeline**: Mengorkestrasi siklus ETL otomatis setiap 30 detik untuk menjamin aktualitas data tanpa intervensi manual.
- **Multi-Source Integration**: Secara cerdas menyatukan format data yang berbeda dari BMKG, USGS, EMSC, dan dataset historis menjadi satu model terpadu.
- **Location Proximity Warning**: Menggunakan rumus matematika *Haversine* untuk menghitung jarak nyata episentrum gempa ke koordinat pengguna sebagai basis DSS.
- **Intelligent Push Notification**: Mengirim pesan darurat (*high-priority*) via Firebase Cloud Messaging (FCM) v1 API berdasarkan aturan tingkat risiko (*Rule-Based Decision*).
- **Star Schema Design**: Menggabungkan tabel fakta dan dimensi untuk mendukung kueri analitik super cepat.
- **Anti-Spam Mechanism**: Memanfaatkan pelacakan memori *state* ID gempa untuk menghindari pengiriman notifikasi berulang untuk kejadian gempa yang sama.

## Environment Variables & Configuration
Pastikan Anda mengatur variabel lingkungan berikut di dalam skrip/notebook sebelum menjalankan *pipeline*:

| Nama Variabel | Deskripsi | Contoh Nilai / Format |
| --- | --- | --- |
| `FIREBASE_PROJECT_ID` | ID proyek konsol Google Firebase Anda. | `"sasimoks-fbe64"` |
| `SERVICE_ACCOUNT_FILE` | Jalur file kredensial JSON Akun Layanan Firebase. | `"firebase_service_account.json"` |
| `SUPABASE_URL` | URL endpoint API proyek Supabase Anda. | `https://your-project.supabase.co` |
| `SUPABASE_KEY` | Token rahasia akses database (*Service Role Key*). | *String Token JWT Supabase* |
| `USER_LAT` | Koordinat *Latitude* acuan lokasi pusat pengguna. | `-0.5022` (Samarinda) |
| `USER_LNG` | Koordinat *Longitude* acuan lokasi pusat pengguna. | `117.1536` (Samarinda) |

## Project Workspaces & Notebooks
Berikut adalah tautan Google Colab yang memuat eksekusi kode proyek ini:
- **[Workspace 1: Data Pipeline & EWS (Real-time)](https://colab.research.google.com/drive/13Gaog9-bgI5pZ3_u7slzrf-T6isZp9xS?usp=sharing)**
- **[Workspace 2: Data Cleaning & Historical Data Processing](https://colab.research.google.com/drive/1wXfwk2O_Tew6N_IU9XsbOTWoqLAqU_vt#scrollTo=0kE8HT3QATPW)**

## How to Run
1. Persiapkan skema *Data Warehouse* dengan menjalankan skrip DDL yang tersedia di dalam folder **`scripts/`**. Eksekusi skrip ini di SQL Editor Supabase Anda untuk membuat tabel pada skema `public` dan `gold`.
2. Untuk melihat proses pembersihan dan transformasi data historis (dataset Kaggle), buka dan jalankan file *Jupyter Notebook* (`.ipynb`) yang terdapat di dalam folder **`data_cleaning/`** atau akses langsung melalui tautan Colab di atas.
3. Untuk menjalankan *Real-Time Pipeline*, pastikan berkas kredensial `firebase_service_account.json` telah diletakkan di dalam direktori kerja/environment Anda, sesuaikan variabel lingkungan, lalu jalankan *cell* eksekusi di notebook terkait.
