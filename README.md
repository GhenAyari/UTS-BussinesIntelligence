---

# SeismoGuard Pipeline: An End-to-End Real-Time Earthquake Data Pipeline & Early Warning System

## Project Overview

Proyek ini mendemonstrasikan pengembangan data pipeline berbasis ETL (*Extract, Transform, Load*) secara *real-time* menggunakan **Python (Google Colab)** dan **Supabase (PostgreSQL)**[cite: 1]. Sistem ini dirancang untuk memantau aktivitas gempa bumi global secara terus-menerus, melakukan standardisasi data dari berbagai sumber, mendeteksi potensi bahaya secara spasial menggunakan perhitungan jarak, mengirim notifikasi darurat instan melalui Firebase Cloud Messaging (FCM), dan menyimpan data historis ke dalam *Data Warehouse* berbasis arsitektur *Star Schema*[cite: 1].

## Objectives

Membangun sistem pemantauan gempa bumi terpadu yang andal untuk mendukung *Early Warning System* (EWS) secara otomatis dan terstruktur[cite: 1]. Dengan memanfaatkan **Python** untuk orkestrasi data serta kalkulasi jarak analitis, proyek ini memproses aliran data mentah dari tiga institusi seismologi dunia, menyaring duplikasi, mengklasifikasikan tingkat bahaya secara langsung, dan menyajikannya ke dalam tabel dimensi serta fakta yang siap digunakan untuk kebutuhan analisis spasial maupun pelaporan analitik[cite: 1].

## Tech Stack

* **Environment**: Google Colab (Jupyter Notebook) / Python Runtime[cite: 1]
* **Programming Language**: Python (Pandas, Requests, Google Auth)[cite: 1]
* **Database / Data Warehouse**: Supabase (PostgreSQL)[cite: 1]
* **Notification Service**: Firebase Cloud Messaging (FCM) v1 API[cite: 1]
* **ETL Workflow**: Python Core & Supabase Client Engine[cite: 1]
* **Data Architecture**: Staging Layer (`public`) & Business Layer (`gold` schema)[cite: 1]
* **Data Modeling**: Star Schema (Fact and Dimension tables)[cite: 1]
* **Data Sources**: BMKG (Indonesia), USGS (Amerika Serikat), dan EMSC (Eropa)[cite: 1]

## ETL Workflow Overview

1. **Data Ingestion (Extract)**: Menarik data aktivitas gempa bumi terkini dari API publik BMKG, USGS, dan EMSC secara berkala setiap 30 detik, lalu menyatukannya ke dalam satu struktur format data yang seragam[cite: 1].
2. **Data Transformation & EWS**: Cleaned data diproses menggunakan formula *Haversine* untuk menghitung jarak episentrum terhadap lokasi acuan pengguna[cite: 1]. Sistem memfilter data menggunakan *memory cache tracker* untuk mencegah pengiriman pesan berulang (anti-spam), kemudian memicu notifikasi FCM berdasarkan kategori magnitudo dan jarak[cite: 1].
3. **Data Loading (Staging)**: Seluruh data baru hasil ekstraksi siklus berjalan dimuat langsung ke dalam tabel operasional `public.gempa_live` setelah membersihkan data siklus sebelumnya (*truncate-and-load*)[cite: 1].
4. **Data Warehouse Modeling**: Data ditransformasi dan dipecah ke dalam skema *Star Schema* pada skema `gold`, yang terdiri dari pengisian data unik ke `dim_waktu`, `dim_lokasi`, dan pencatatan metrik pada `fact_gempa`[cite: 1].

## Data Architecture

Sistem ini menggunakan pendekatan pemisahan area operasional (*Staging*) dengan area analitis (*Data Warehouse*)[cite: 1].


1. **Staging Layer (`public`)**
* **`gempa_live`**: Menampung data representasi kondisi lapangan terkini dari gabungan API global secara mentah yang diperbarui di setiap siklus[cite: 1].


2. **Gold Layer (`gold` schema)**
* Menyimpan data terstruktur jangka panjang menggunakan model relasional bintang (*Star Schema*) yang dirancang khusus untuk optimasi *analytical querying* dan pembuatan *dashboard* visualisasi[cite: 1].



## Data Flow

Aliran data linier dari penarikan sumber data API eksternal, pemrosesan logika notifikasi darurat, pembaruan tabel *live*, hingga penyimpanan terstruktur ke dalam tabel dimensi dan fakta[cite: 1].


## Data Integration

Proyek ini mengintegrasikan data dari tiga domain platform seismologi yang memiliki format *payload* awal berbeda[cite: 1]:

1. **BMKG**: Mengambil data gempa yang dirasakan di wilayah Indonesia[cite: 1].
2. **USGS**: Mengambil data GeoJSON aktivitas gempa global dalam rentang waktu satu jam terakhir[cite: 1].
3. **EMSC**: Mengambil data terbaru berskala internasional dari portal seismik Eropa[cite: 1].


## Data Modeling — Star Schema

Arsitektur data pada lapisan **Gold Layer** dirancang menggunakan *Star Schema* yang terdiri dari[cite: 1]:

* Satu tabel pusat **Fact Table**:
* `gold.fact_gempa`[cite: 1]


* Didukung oleh dua **Dimension Tables**:
* `gold.dim_waktu`[cite: 1]
* `gold.dim_lokasi`[cite: 1]




## Gold Layer Table Snapshots

Lapisan bisnis (Gold Layer) menyajikan data bersih yang siap dianalisis untuk melihat tren aktivitas kegempaan[cite: 1].

### `gold.dim_waktu`

Menyimpan dekomposisi waktu kejadian gempa untuk memudahkan analisis berbasis tren waktu[cite: 1].


### `gold.dim_lokasi`

Menyimpan data koordinat presisi (latitude & longitude) beserta deskripsi wilayah episentrum gempa[cite: 1].


### `gold.fact_gempa`

Merekam metrik kuantitatif seperti magnitudo dan kedalaman gempa yang terikat dengan relasi kunci dari tabel dimensi waktu maupun lokasi[cite: 1].


## Features

* **Real-Time Data Orchestration**: Pipeline berjalan otomatis dengan interval siklus 30 detik untuk menjamin aktualitas data[cite: 1].
* **Multi-Source Parser**: Secara cerdas menyatukan format data yang berbeda dari BMKG, USGS, dan EMSC menjadi satu standar skema data[cite: 1].
* **Location Proximity Warning**: Menggunakan rumus matematika *Haversine* untuk menghitung jarak nyata episentrum gempa ke koordinat pengguna[cite: 1].
* **Intelligent Push Notification**: Mengirim pesan *high-priority* via Firebase Cloud Messaging (FCM) v1 API berdasarkan klasifikasi tingkat bahaya gempa[cite: 1].
* **Anti-Spam Mechanism**: Memanfaatkan pelacakan memori *state* ID gempa untuk menghindari pengiriman notifikasi berulang untuk kejadian gempa yang sama[cite: 1].
* **Star Schema Data Warehouse**: Penerapan konsep pemodelan data modern (`fact` & `dimension`) di platform cloud Supabase[cite: 1].

## Environment Variables & Configuration

Pastikan Anda mengatur variabel lingkungan berikut di dalam skrip sebelum menjalankan pipeline[cite: 1]:

| Nama Variabel | Deskripsi | Contoh Nilai / Format |
| --- | --- | --- |
| `FIREBASE_PROJECT_ID` | ID proyek konsol Google Firebase Anda[cite: 1]. | `"sasimoks-fbe64"`[cite: 1] |
| `SERVICE_ACCOUNT_FILE` | Jalur file kredensial JSON Akun Layanan Firebase[cite: 1]. | `"firebase_service_account.json"`[cite: 1] |
| `SUPABASE_URL` | URL endpoint API proyek Supabase Anda[cite: 1]. | `[https://your-project.supabase.co](https://your-project.supabase.co)`[cite: 1] |
| `SUPABASE_KEY` | Token rahasia akses database (*Service Role Key*)[cite: 1]. | *String Token JWT Supabase*[cite: 1] |
| `USER_LAT` | Koordinat Latitude acuan lokasi pusat pengguna[cite: 1]. | `-0.5022` (Samarinda)[cite: 1] |
| `USER_LNG` | Koordinat Longitude acuan lokasi pusat pengguna[cite: 1]. | `117.1536` (Samarinda)[cite: 1] |

## How to Run

1. Tempatkan berkas kredensial `firebase_service_account.json` ke dalam direktori kerja proyek Anda[cite: 1].
2. Pastikan tabel target pada skema `public` dan `gold` telah dibuat di Supabase sesuai dengan struktur pemodelan data[cite: 1].
3. Jalankan pipeline utama menggunakan perintah terminal[cite: 1]:
```bash

```



python main.py

```
