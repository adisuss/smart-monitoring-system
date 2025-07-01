# 🌡️ ESP32 Smart Temperature Monitor ![Status](https://img.shields.io/badge/status-stable-brightgreen) ![License](https://img.shields.io/badge/license-MIT-blue)

Sistem pemantauan suhu berbasis **ESP32 + DHT11**, dirancang untuk penggunaan di **gudang**, **ruang panel**, dan **ruang server**. Alat ini memonitor suhu secara otomatis, mengirimkan **notifikasi saat suhu melebihi batas**, serta mencatat data suhu ke **Firebase** dan **Google Sheets** yang terintegrasi dengan akun Google Anda.

---

## 🔧 Fitur Utama

- ✅ Pemantauan suhu dan kelembapan
- ✅ Push notifikasi saat suhu melewati batas atas/bawah
- ✅ Aplikasi Android dengan grafik suhu real-time
- ✅ WiFi provisioning langsung dari aplikasi
- ✅ Pengaturan batas suhu dan jadwal pengiriman data ke GoogleSheets
- ✅ Google Sheets otomatis berisi tabel & grafik suhu
- ✅ Login Google untuk akses data pribadi dan aman

---

## 📱 Cara Kerja

1. **Pertama kali digunakan**, alat akan masuk ke mode WiFi provisioning dan dikonfigurasi melalui aplikasi Android.
2. Setelah tersambung ke WiFi, alat mulai **mengambil data suhu tiap 5 menit** menggunakan sensor DHT11.
3. Data dikirim secara otomatis ke **Firebase Realtime Database**.
4. **Aplikasi Android** akan menampilkan data suhu dalam bentuk **grafik 20 titik terakhir**, serta menyediakan pengaturan batas suhu & jadwal.
5. Jika suhu di luar batas yang ditentukan, **notifikasi langsung dikirim ke smartphone** Anda.
6. Setiap hari pada waktu tertentu, data suhu dikirim otomatis ke **Google Sheets** yang terhubung ke akun Google pengguna.
7. Google Sheets menyusun data ke dalam **tabel yang mudah dibaca**, lengkap dengan **grafik suhu historis**.

---

## 🎯 Cocok Untuk

- 🏭 **Gudang penyimpanan** — mencegah kerusakan akibat suhu ekstrem
- ⚡ **Ruang panel listrik** — deteksi dini overheating peralatan
- 🖥️ **Ruang server** — menjaga suhu stabil demi operasional sistem
- 📦 Lokasi sensitif lainnya yang butuh pemantauan suhu

---

## 📷 Gambar Perangkat

> Ganti gambar di bawah ini dengan foto asli alatmu.

![Foto Alat](docs/device-photo.jpg)

---

## 📊 Contoh Output Google Sheets

> Ganti dengan screenshot tampilan sheets.

![Tampilan Sheets](docs/sheets-sample.png)

---


## 📞 Pemesanan

Ingin melindungi ruang penting Anda dengan sistem monitoring suhu otomatis?

> 📲 [Hubungi kami di WhatsApp](https://wa.me/6281381113710)

Kami siap menerima pemesanan unit, permintaan kustom, atau kerja sama proyek dalam skala kecil hingga industri.

---

## 📄 Lisensi

Proyek ini berada di bawah lisensi MIT.  
Bebas digunakan dan dimodifikasi — mohon tetap mencantumkan atribusi.

---
