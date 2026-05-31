SUPPORT : https://saweria.co/medalixt

# medalixt_identitas

`medalixt_identitas` adalah resource identitas untuk server QBCore/Qbox yang menyediakan layanan pembuatan dan penggunaan kartu identitas warga, kartu tanda anggota job, serta lisensi senjata berbasis item ox_inventory.

Resource ini dirancang untuk workflow roleplay melalui NPC petugas, NUI kartu identitas, metadata player, dan item inventory yang dapat digunakan untuk menampilkan kartu sendiri atau menunjukkannya ke pemain sekitar.

## Fitur

- Pembuatan KTP warga oleh job pemerintah.
- Perpanjangan masa berlaku KTP warga.
- Pembuatan Kartu Tanda Anggota untuk job:
  - Police
  - Ambulance
  - Mechanic
  - Pedagang
  - Pemerintah
  - Judge / DOJ
  - Lawyer / Law Firm
- Pembuatan lisensi senjata oleh job police.
- Perpanjangan lisensi senjata dengan cooldown seminggu sekali.
- Lisensi senjata menggunakan item `lisensi_senjata` dengan durability sebagai masa berlaku.
- Integrasi pembelian senjata ox_inventory melalui item `lisensi_senjata`, bukan license database bawaan.
- Tampilan NUI dengan background berbeda untuk KTP, KTA, dan lisensi senjata.
- Opsi penggunaan item:
  - Lihat kartu sendiri.
  - Tunjukkan kartu ke pemain sekitar.
- Menu petugas berbasis `ox_target` dan `ox_lib`.

## Dependensi

Pastikan resource berikut sudah terpasang dan berjalan sebelum `medalixt_identitas`:

```cfg
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qb-core
ensure qbx_core
```

Catatan:

- Resource ini menggunakan `exports['qb-core']:GetCoreObject()`.
- Beberapa fungsi perubahan data karakter menggunakan export `qbx_core`.
- Inventory item dan usable item menggunakan `ox_inventory` serta QBCore usable item.

## Instalasi

1. Letakkan folder resource di:

```text
resources/[medalixt]/medalixt_identitas
```

2. Tambahkan resource ke `resources.cfg` atau config server Anda:

```cfg
ensure medalixt_identitas
```

3. Pastikan urutan start resource sudah benar:

```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qb-core
ensure qbx_core
ensure medalixt_identitas
```

4. Tambahkan item identitas ke `ox_inventory/data/items.lua`. Template tersedia di:

```text
install/template_ox_inventory.lua
```

5. Restart server atau refresh resource:

```cfg
refresh
ensure medalixt_identitas
```

## Item Inventory

Resource ini membutuhkan item berikut di `ox_inventory/data/items.lua`:

```lua
['ktp'] = {
    name = 'ktp',
    label = 'KTP',
    weight = 50,
    stack = false,
    description = 'Kartu identitas resmi sebagai warga negara.'
}
```

Item KTA:

- `kta_police`
- `kta_ambulance`
- `kta_mechanic`
- `kta_pedagang`
- `kta_government`
- `kta_judge`
- `kta_lawyer`

Item lisensi senjata:

```lua
['lisensi_senjata'] = {
    name = 'lisensi_senjata',
    label = 'Lisensi Senjata',
    weight = 50,
    width = 1,
    height = 1,
    rarity = 'rare',
    stack = false,
    degrade = 10080,
    description = 'Lisensi resmi untuk memiliki dan menggunakan senjata api tertentu'
}
```

`degrade = 10080` berarti item memiliki durability berbasis waktu selama 7 hari. Saat lisensi dibuat atau diperpanjang melalui resource ini, durability item akan disesuaikan dengan tanggal berlaku lisensi.

## Konfigurasi

Konfigurasi utama berada di:

```text
config.lua
```

Biaya dan durasi:

```lua
Config.BiayaKTP = 50000
Config.BiayaPerpanjangPerBulan = 25000
Config.PerpanjangLisensiSenjataHari = 7
Config.CooldownPerpanjangLisensiSenjataHari = 7
```

Daftar tipe kartu:

```lua
Config.CardTypes = {
    police = { label = 'POLICE', itemName = 'kta_police' },
    weapon_license = { label = 'LISENSI SENJATA', itemName = 'lisensi_senjata' },
    ambulance = { label = 'AMBULANCE', itemName = 'kta_ambulance' },
    mechanic = { label = 'MEKANIK', itemName = 'kta_mechanic' },
    pedagang = { label = 'PEDAGANG', itemName = 'kta_pedagang' },
    government = { label = 'PEMERINTAH', itemName = 'kta_government' },
    judge = { label = 'DEPARTEMENT OF JUSTICE', itemName = 'kta_judge' },
    lawyer = { label = 'LAW FIRM', itemName = 'kta_lawyer' },
}
```

NPC petugas dapat diatur melalui `Config.Locations`. Setiap lokasi mendukung:

- `label`
- `model`
- `allowedJobs`
- `cardType`
- `coords`
- `scenario`

Contoh:

```lua
{
    label = "Petugas Police",
    model = 's_m_y_cop_01',
    allowedJobs = { police = true },
    cardType = 'police',
    coords = vector4(480.90, -992.14, 30.71, 93.54),
    scenario = "WORLD_HUMAN_CLIPBOARD",
}
```

## Integrasi Lisensi Senjata dengan ox_inventory

Pembelian senjata di Ammunation dapat dikunci menggunakan item `lisensi_senjata`.

Contoh pada `ox_inventory/data/shops.lua`:

```lua
{ name = 'WEAPON_PISTOL', price = 1000, metadata = { registered = true }, licenseItem = 'lisensi_senjata' }
```

Dengan konfigurasi ini:

- Player harus memiliki item `lisensi_senjata`.
- Item harus memiliki durability lebih dari `0`.
- Jika item tidak ada atau durability habis, pembelian senjata ditolak.

License bawaan ox_inventory pada `data/licenses.lua` dapat dikosongkan jika seluruh sistem license senjata sudah diganti dengan item:

```lua
return {}
```

## Alur Penggunaan

### KTP Warga

1. Petugas pemerintah berinteraksi dengan NPC pemerintah.
2. Pilih `Buatkan KTP untuk Warga`.
3. Masukkan ID server warga, URL foto, dan tanggal expired.
4. Warga menerima item `ktp`.

### KTA Job

1. Petugas job berinteraksi dengan NPC sesuai job.
2. Pilih menu pembuatan kartu anggota.
3. Masukkan ID server warga dan URL foto.
4. Warga menerima item KTA sesuai job.

### Lisensi Senjata

1. Police berinteraksi dengan NPC police.
2. Pilih `Buat Lisensi Senjata`.
3. Masukkan ID server warga, URL foto opsional, dan tanggal berlaku.
4. Warga menerima item `lisensi_senjata`.
5. Item tersebut menjadi syarat pembelian senjata di shop ox_inventory.

### Perpanjangan Lisensi Senjata

1. Police memilih `Perpanjang Lisensi Senjata`.
2. Masukkan ID server warga.
3. Lisensi diperpanjang sesuai `Config.PerpanjangLisensiSenjataHari`.
4. Cooldown perpanjangan mengikuti `Config.CooldownPerpanjangLisensiSenjataHari`.

## Tampilan NUI

File UI berada di:

```text
html/index.html
html/style.css
html/script.js
html/img/
```

Background yang digunakan:

- `ktp_background.png`
- `kta_police_background.png`
- `kta_ambulance_background.png`
- `kta_mechanic_background.png`
- `kta_pedagang_background.png`
- `kta_government_background.png`
- `kta_judge_background.png`
- `kta_lawyer_background.png`
- `lisensi_senjata.png`

Jika masa berlaku lisensi senjata sudah lewat, tampilan kartu akan menampilkan status `TIDAK BERLAKU`.

## Command Admin

Resource menyediakan command:

```text
/resetktp [id]
```

Fungsi:

- Menghapus metadata KTP dan lisensi pemain target.
- Hanya dapat digunakan oleh admin.

## Troubleshooting

### NPC tidak muncul

- Pastikan resource sudah `ensure`.
- Pastikan `ox_target` berjalan.
- Pastikan job player sesuai `allowedJobs`.
- Restart resource setelah mengubah `Config.Locations`.

### Item kartu tidak bisa digunakan

- Pastikan item sudah terdaftar di `ox_inventory/data/items.lua`.
- Pastikan resource sudah restart setelah item ditambahkan.
- Pastikan nama item sama dengan `Config.CardTypes`.

### Tidak bisa beli senjata meskipun punya lisensi

- Pastikan item bernama `lisensi_senjata`.
- Pastikan durability item lebih dari `0`.
- Pastikan shop item memakai `licenseItem = 'lisensi_senjata'`.
- Jika item sudah expired, lakukan perpanjangan melalui NPC police.

### Foto tidak tampil

- Pastikan URL foto valid dan dapat diakses client.
- Jika URL kosong saat membuat lisensi senjata, sistem akan mencoba memakai foto dari data KTP warga.

## Struktur Resource

```text
medalixt_identitas/
|-- client.lua
|-- config.lua
|-- fxmanifest.lua
|-- server.lua
|-- html/
|   |-- index.html
|   |-- script.js
|   |-- style.css
|   `-- img/
`-- install/
    `-- template_ox_inventory.lua
```

## Lisensi

Resource ini dibuat oleh MEDALIXT untuk kebutuhan sistem identitas server roleplay berbasis QBCore/Qbox.
