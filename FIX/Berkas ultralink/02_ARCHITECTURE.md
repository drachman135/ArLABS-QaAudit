02_ARCHITECTURE
Architecture Pattern
Aplikasi menggunakan pola arsitektur MVVM (Model-View-ViewModel) yang dipadukan dengan prinsip Single Source of Truth (SSoT) menggunakan database lokal.
Layers
1. UI Layer (View)
•
Terdiri dari Fragments dan Activities.
•
Bertanggung jawab untuk menampilkan data ke pengguna dan menangkap input.
•
Berlangganan (Observe) pada data dari ViewModel.
2. ViewModel Layer
•
Bertindak sebagai perantara antara View dan Repository.
•
Memproses logika presentasi (filtering, sorting untuk UI).
•
Menjaga state UI agar tetap bertahan saat terjadi perubahan konfigurasi (seperti rotasi layar).
3. Repository Layer (Domain)
•
Mengelola aliran data dari berbagai sumber (Local Room & Remote Firestore).
•
Implementasi logika sinkronisasi via SyncManager.
•
Menyediakan API bersih untuk ViewModel tanpa mempedulikan dari mana data berasal.
4. Data Layer
•
Local Source: Room Database (TargetDatabase) untuk akses cepat dan offline.
•
Remote Source: FirestoreDataSource untuk backup cloud dan sinkronisasi antar perangkat.
•
Settings Source: Jetpack DataStore (AppSettingsManager & WidgetSettingsManager).
Data Flow Diagram
graph TD
    UI[Fragments / Widgets] -->|Action| VM[ViewModels / WidgetUpdateWorker]
    VM -->|Request Data| REPO[Repositories]
    REPO -->|Query/Update| ROOM[(Room DB - SSoT)]
    REPO -->|Sync Action| SYNC[SyncManager / WorkManager]
    SYNC -->|Push/Pull| FS{Firestore Cloud}
    ROOM -->|Reactive Flow| REPO
    REPO -->|Resource State| VM
    VM -->|LiveData/Flow| UI
Dependency Injection
Menggunakan sistem Manual Injection melalui objek Injector.kt. Seluruh dependensi didefinisikan secara terpusat untuk mempermudah pemeliharaan dan pengujian tanpa overhead library DI pihak ketiga.
Repository List
•
ProjectRepository: Inti manajemen data proyek dan tugas.
•
AchievementRepository: Logika gamifikasi dan aturan unlock pencapaian.
•
SearchRepository: Logika pencarian data lintas entitas.
•
WidgetRepository: Sumber data khusus untuk ekosistem widget Glance.