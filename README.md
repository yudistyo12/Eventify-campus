# Eventify Campus

Aplikasi Flutter lintas platform untuk melihat dan mengelola kegiatan kampus. Pengajuan event ditinjau admin sebelum dipublikasikan.

## Menjalankan aplikasi

```bash
flutter pub get
flutter run
```

Pastikan Firebase Authentication dan Cloud Firestore sudah dikonfigurasi untuk platform yang digunakan.

## Poster event

Poster dikompresi menjadi JPEG dengan lebar maksimal 800 piksel dan ukuran maksimal 200 KB. Data gambar disimpan sebagai Base64 data URI pada field `imageUrl` di dokumen event. Karena Base64 memperbesar ukuran data, batas 200 KB menjaga dokumen tetap di bawah batas ukuran Cloud Firestore.

Setelah memilih Firebase project yang benar, deploy aturan Firestore:

```bash
firebase deploy --only firestore:rules
```
