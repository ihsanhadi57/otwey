/// Semua teks UI. Gaya bahasa: docs/DESIGN_SYSTEM.md bagian "Suara dan bahasa".
///
/// Jangan menulis teks langsung di widget. Jangan hardcode nama kota, pakai parameter.
abstract final class AppCopy {
  // Brand
  static const tagline = 'Make every stop count.';

  // Onboarding
  static const onboardingTitle = 'Jakarta ⇄ Bandung, sehari kelar';
  static const onboardingSubtitle =
      'Kerjaan beres, main juga sempat, pulang tetap on time';
  static const onboardingCta = 'Mulai rencanain';

  // Arah
  static const directionTitle = 'Mau ke mana hari ini?';
  static const toBandung = 'Ke Bandung';
  static const toJakarta = 'Ke Jakarta';

  // Waktu
  static const departQuestion = 'Mau berangkat jam berapa?';
  static const returnQuestion = 'Paling telat sampai rumah jam berapa?';
  static const leaveLabel = 'Berangkat';
  static const backHomeLabel = 'Sampai rumah';
  static const presetFullDay = 'Seharian';
  static const presetRelaxed = 'Santai';
  static const presetShort = 'Singkat';
  static String hoursOutSummary(String d) => '$d di luar rumah';
  static const hoursOutTooShort = 'Minimal 2 jam di luar rumah, geser jam pulang lebih malam.';
  static String saveRange(String a, String b) => 'Simpan $a – $b';

  // Tujuan kamu
  static const pinsTitle = 'Udah ada tujuan pasti?';
  static const pinsSubtitle =
      'Kerjaan, janji, atau tempat incaran. Sisanya biar kita isi.';
  static const addPin = 'Tambah tujuan';
  static const fixedTime = 'Jam tetap';
  static const flexibleTime = 'Bebas jam';
  static const priorityWajib = 'Wajib';
  static const priorityPenting = 'Penting';
  static const priorityOpsional = 'Kalau sempat';
  static const purposeKerja = 'Kerjaan';
  static const purposeJanji = 'Janji';
  static const purposeMain = 'Main';
  static const purposeLainnya = 'Lainnya';

  // Vibes
  static const vibesTitle = 'Sisa waktunya mau diisi apa?';
  static const generateCta = 'Gas, bikin itinerary';
  static const generating = 'Lagi nyusun rute terbaik buat kamu...';

  // Hasil
  static String resultTitle(String city) => '$city, here we go';
  static String freeTime(String duration) => 'Waktu luang kamu $duration';
  static const statusSafe = 'Aman, masih sempat';
  static String statusTight(String minutesLeft) => 'Mepet nih · $minutesLeft lagi';
  static const statusImpossible =
      'Nggak keburu. Coba kereta pulang yang lebih malam ya';
  static String pinsDropped(List<String> names) =>
      'Waktunya nggak cukup, jadi ${names.map((n) => '"$n"').join(', ')} kita lepas dulu.';
  static String placeClosesAt(String time) =>
      'Tutup jam $time, jadi kita taruh di awal';
  static const swapPlace = 'Tukar tempat';
  static const savePlan = 'Simpan itinerary';
  static const saved = 'Sip, itinerary kamu udah aman tersimpan.';

  // Konflik
  static String requiredPinConflict(String time, String train) =>
      'Tujuan $time nggak kekejar dari kereta $train. Ganti ke kereta lebih pagi?';
  static const changeTrain = 'Ganti kereta';
  static const changeTime = 'Ubah jam';

  // Tersimpan
  static const savedTitle = 'Trip tersimpan';
  static const savedEmpty = 'Belum ada trip tersimpan. Yuk bikin yang pertama.';
  static const deleteQuestion =
      'Hapus itinerary ini? Rencananya hilang dan nggak bisa dibalikin.';
  static const deleteConfirm = 'Hapus';
  static const deleteCancel = 'Nggak jadi';

  // Umum
  static const next = 'Lanjut';
  static const skip = 'Nanti aja';
  static const retry = 'Coba lagi';
  static const errorConnection =
      'Koneksi lagi putus nyambung. Cek internet kamu, terus coba lagi ya.';
  static const noData = 'Belum ada data';

  // Navigasi
  static const navHome = 'Beranda';
  static const navExplore = 'Jelajah';
  static const navTrip = 'Trip';
  static const navAccount = 'Akun';
  static const back = 'Kembali';
  static const seeAll = 'Lihat semua';
  static const change = 'Ubah';

  // Beranda
  static String greeting(String name) => 'Halo, $name';
  static const homeTitle = 'Mau OTW ke mana hari ini?';
  static const from = 'Dari';
  static const to = 'Ke';
  static const swapDirection = 'Tukar arah';
  static const departFrom = 'Berangkat dari';
  static const date = 'Tanggal';
  static const hoursOut = 'Jam di luar rumah';
  static const planTrip = 'Rencanain trip';
  static const nextTrip = 'Trip berikutnya';
  static const tomorrow = 'Besok';
  static String leaveFromHome(String time) => 'jalan $time dari rumah';
  static String placesAndMeetings(int places, int meetings) =>
      meetings > 0 ? '$places tempat · $meetings meeting' : '$places tempat';
  static String wishSectionTitle(String city) => 'Tempat incaran di $city';
  static const wishSectionSubtitle = 'Pilihan OTWEY. Simpan yang kamu incar ke wishlist.';
  static String wishlistCount(int n) => 'Wishlist · $n';
  static const tripIdeas = 'Ide trip sehari';
  static const notifications = 'Notifikasi';

  // Pilih titik berangkat
  static const originTitle = 'Berangkat dari mana?';
  static const originSearch = 'Cari alamat, gedung, atau stasiun';
  static const useCurrentLocation = 'Pakai lokasi sekarang';
  static const useCurrentLocationHint = 'Biar akurat pas hari H';
  static const currentLocationLabel = 'Lokasi sekarang';
  static const pickOnMap = 'Pilih di peta';
  static const modeDoesNotFit = 'Kalau pakai moda ini kamu bakal telat ke jadwal berikutnya. Ubah dari rencana dulu ya.';
  static const pickOnMapHint = 'Geser dan ketuk titik berangkatmu';
  static const tapMapForOrigin = 'Ketuk peta buat pilih titik berangkat';
  static const findingAddress = 'Lagi cari nama jalannya...';
  static const pointOnMap = 'Titik di peta';
  static const locating = 'Lagi cari lokasimu...';
  static String outsideCity(String city) => 'Lokasimu bukan di $city. Pilih titik berangkat manual ya.';
  static const savedPlaces = 'Tersimpan';
  static const recentPlaces = 'Terakhir dipakai';
  static String toStationEta(String station, String eta) =>
      'Ke $station sekitar $eta';
  static const useThisPoint = 'Pakai titik ini';

  // Atur rencana
  static const planSetupTitle = 'Atur rencana';
  static const yourPins = 'Tujuan kamu';
  static const yourPinsHint = 'Kerjaan atau tempat incaran. Kita kunci duluan.';
  static String fromWishlist(int n, String city) =>
      'Ambil dari wishlist ($n di $city)';
  static const fillFreeTime = 'Isi waktu luang';
  static String freeTimeLeft(String duration) => 'Masih ada $duration di luar meeting.';
  static const calculatingFreeTime = 'Lagi ngitung waktu luang...';
  static String subVibeQuestion(String vibe) => '$vibe yang kayak gimana?';
  static String pickedCount(int n) => '$n dipilih';
  static const budget = 'Budget';
  static const budgetHemat = 'Hemat';
  static const budgetSedang = 'Sedang';
  static const budgetSultan = 'Sultan';
  static const travelBetween = 'Pindah antar tempat';
  static const travelCampur = 'Campur';
  static const travelOjol = 'Ojol';
  static const travelTransum = 'Transum';
  static const travelCampurHint = 'OTWEY pilih yang paling pas per perjalanan.';
  static const travelOjolHint = 'Semua perjalanan pakai ojol, cepat dan pintu ke pintu.';
  static const travelTransumHint =
      'Semua perjalanan pakai transum, hemat dan lengkap koridornya.';
  static const travelChangeLater = 'Tetap bisa diganti satu satu di hasil itinerary.';
  static const withKids = 'Bawa bocil';
  static const freeTimeLabel = 'Waktu luang';
  static const flexibleTimeShort = 'bebas jam';

  // Tambah tujuan
  static const searchPlace = 'Cari tempat';
  static const purposeQuestion = 'Buat apa ke sini?';
  static const startTime = 'Mulai';
  static const endTime = 'Selesai';
  static const wajibHint = 'Wajib: kita kunci duluan, nggak bakal dihapus dari rencana.';
  static const pentingHint = 'Penting: diusahakan masuk, dilepas paling akhir.';
  static const opsionalHint = 'Kalau sempat: dilepas duluan kalau waktunya mepet.';
  static const addToPlan = 'Tambah ke rencana';
  static const myLocation = 'Lokasi saya';
  static const pickStartTime = 'Jam mulai';
  static const pickEndTime = 'Jam selesai';
  static const timePickerHint = 'Geser untuk ganti jam. Menit per 5 biar gampang.';
  static const cancel = 'Batal';
  static String saveTime(String time) => 'Simpan $time';

  // Menyusun
  static const generatingHint = 'Biasanya cuma beberapa detik.';
  static const stepRoute = 'Rute dari rumah ke stasiun, pergi dan pulang';
  static String stepLock(String time) => 'Meeting $time dikunci';
  static String stepSearch(String vibe) => 'Nyari ${vibe.toLowerCase()} di sekitar rute';
  static const stepCheck = 'Ngecek semua masih sempat pulang';

  // Hasil
  static const statFreeTime = 'Waktu luang';
  static const statCost = 'Ongkos jalan';
  static const statHome = 'Sampai rumah';
  static String safeBuffer(String minutes) =>
      'Aman, masih sempat. Ada $minutes jaga jaga sebelum kereta pulang.';
  static String trainTitle(String from, String to) => 'Kereta cepat $from → $to';
  static String trainArrive(String dur, String arrive) => '$dur · tiba $arrive';
  static String trainBuffer(String dur, String buffer) => '$dur · ada $buffer jaga jaga';
  static String spareBefore(String spare, String limit) => '$spare sebelum batas $limit';
  static String resultMeta(String date, String origin, String vibe, String budget) =>
      '$date · dari $origin · $vibe · $budget';
  static const yourPlan = 'Rencana kamu';
  static const costNote = 'Ongkos di luar tiket kereta';
  static const ojolNote = 'Tarif perkiraan. Pas hari H tinggal pesan dari mode jalan.';
  static const free = 'Gratis';
  static String approxRupiah(int thousands) => '± Rp${thousands}rb';
  static const share = 'Bagikan';
  static const editPlan = 'Ubah rencana';
  static const locked = 'terkunci';
  static String walkMinutes(int m) => 'Jalan kaki $m mnt';
  static const savedToTrip = 'Itinerary disimpan ke Trip';
  static const see = 'Lihat';

  // Detail tempat
  static String stopOf(int n, int total) => 'Stop $n dari $total';
  static const openHours = 'Buka';
  static const duration = 'Durasi';
  static const fromStation = 'Dari stasiun';
  static const whyThis = 'Kenapa ini?';
  static const navigate = 'Arahkan';
  static const alternatives = 'Alternatif di slot yang sama';
  static const pick = 'Pilih';
  static String openUntil(String time) => 'Buka sampai $time';
  static String closesAt(String time) => 'Tutup $time';
  static String walkAway(int m) => '$m mnt jalan';

  // Wishlist
  static const wishlist = 'Wishlist';
  static const wishlistHint =
      'Tempat yang kamu simpan dari Beranda, Jelajah, atau detail tempat. Pas bikin rencana, tinggal pilih dari sini.';
  static const addToPlanShort = 'Masukin ke rencana';
  static const planFromWishlist = 'Rencanain trip dari wishlist';
  static const savedToWishlist = 'Disimpan ke wishlist';
  static const removedFromWishlist = 'Dihapus dari wishlist';
  static const saveToWishlist = 'Simpan ke wishlist';
  static const removeFromWishlist = 'Hapus dari wishlist';
  static const undo = 'Batal';
  static const emptyWishlistTitle = 'Belum ada tempat incaran';
  static const emptyWishlistBody =
      'Tap ikon hati di tempat yang kamu suka. Semuanya ngumpul di sini, tinggal dimasukin ke rencana.';
  static const emptyWishlistCta = 'Cari tempat di Jelajah';

  // Trip
  static const tripTitle = 'Trip kamu';
  static const newTrip = 'Trip baru';
  static String upcoming(int n) => 'Akan datang · $n';
  static String finished(int n) => 'Selesai · $n';
  static String leaveAt(String time, String origin) => 'Jalan $time dari $origin';
  static String morePlaces(int n, String time) => '+ $n tempat lagi · sampai rumah $time';
  static String trainTimes(String go, String back) => 'Kereta $go pergi, $back pulang';
  static const seePlan = 'Lihat rencana';
  static const startTrip = 'Mulai trip';
  static const remindMe = 'Ingatkan aku berangkat';
  static const remindMeHint = 'Kabarin 15 mnt sebelum harus jalan';
  static const before = 'Sebelumnya';
  static const done = 'Selesai';
  static const emptyTripTitle = 'Oti masih rebahan';
  static const emptyTripBody =
      'Belum ada trip yang direncanain. Pilih kota, isi jam kosong kamu, nanti Oti yang nyusun rutenya.';
  static const emptyTripCta = 'Bikin trip pertama';
  static const emptyTripSecondary = 'Lihat ide tempat dulu';

  // Mode jalan
  static const nextUp = 'BERIKUTNYA';
  static String onTimeHome(String time) => 'On time · sampai rumah $time';
  static const leaveLatest = 'Jalan paling telat';
  static String ojolEta(String order, String arrive) =>
      'Pesan sebelum $order, sampai sekitar $arrive. Masih santai sebelum meeting.';
  static const arrived = 'Udah sampai';
  static const orderOjol = 'Pesan ojol';

  // Jelajah
  static String nearby(String vibe, String place) => '$vibe dekat $place';
  static String placeCount(int n) => '$n tempat';
  static String searchIn(String city) => 'Cari tempat di $city';
  static const filter = 'Filter';
  static const loadingPlacesTitle = 'Oti lagi ngendus tempat enak';
  static const loadingPlacesBody = 'Ngecek jam buka dan jarak dari rute kamu';

  // Akun
  static const accountTitle = 'Akun';
  static String accountStats(int trips, int places) =>
      '$trips trip · $places tempat dikunjungi';
  static const tripPrefs = 'Preferensi trip';
  static const favoriteVibe = 'Vibes favorit';
  static const reminders = 'Pengingat';
  static const reminderLeave = 'Waktunya berangkat';
  static const reminderTight = 'Kabarin kalau mepet';
  static const help = 'Bantuan';
  static String placesSaved(int n) => '$n tempat';

  // Dialog
  static String deletePinTitle(String name) => 'Hapus $name?';
  static const deletePinBody =
      'Ini tujuan Wajib. Kalau dihapus, jadwal hari itu kita susun ulang dan jam meeting nggak dikunci lagi.';
  static const deletePinConfirm = 'Hapus tujuan';
  static const tightTitle = 'Waktunya mepet nih';
  static String tightBody(String place, int late, String train) =>
      '$place bikin kamu telat $late mnt ke stasiun. Lepas aja biar tetap kebagian kereta $train?';
  static String dropPlace(String place) => 'Lepas $place';
  static const keepIt = 'Tetap simpan';
  static const discardTitle = 'Buang perubahan?';
  static const discardBody = 'Tujuan dan vibes yang barusan kamu ubah belum disimpan.';
  static const discardConfirm = 'Buang perubahan';
  static const keepEditing = 'Lanjut ngedit';
  static const failedRoute = 'Gagal ambil rute. Cek koneksi kamu';

  // Detail tempat (jelajah)
  static const aboutPlace = 'Tentang tempat ini';
  static const photoSoon = 'Foto menyusul';
  static const openToday = 'Jam buka hari ini';
  static const openNow = 'Lagi buka';
  static const closedNow = 'Lagi tutup';
  static const address = 'Alamat';
  static const priceRange = 'Kisaran harga';
  static const stayTime = 'Enaknya di sini';
  static const goodFor = 'Cocok buat';
  static const location = 'Lokasi';

  // Peta
  static const mapAttribution = 'OpenStreetMap contributors';
  static const mapTapToPin = 'Ketuk peta buat pindahin titik tujuan';
  static const openInMaps = 'Buka di peta';
  static const noDescription = 'Belum ada cerita soal tempat ini. Nanti kita lengkapi ya.';
  static String distanceFromStation(String station, String duration) => '$duration jalan dari $station';
  static String addedToPlan(String name) => '$name masuk rencana sebagai Kalau sempat';
  static const alreadyInPlan = 'Udah ada di rencana';
  static const seePlanShort = 'Lihat';

  // Tempo dan edit hasil
  static const pace = 'Tempo';
  static const paceSantai = 'Santai';
  static const pacePas = 'Pas';
  static const pacePadat = 'Padat';
  static const maxStopsLabel = 'Maks tempat rekomendasi';
  static const maxStopsLess = 'Kurangi tempat';
  static const maxStopsMore = 'Tambah tempat';
  static String paceHint(int stops) => stops == 0
      ? 'Cuma tujuan kamu sendiri, tanpa rekomendasi.'
      : 'Paling banyak $stops tempat dari OTWEY. Tujuan kamu sendiri nggak ikut dihitung.';
  static const removeStop = 'Hapus dari rencana';
  static String stopRemoved(String name) => '$name dihapus, sisa waktunya jadi waktu luang';
  static const freeTimeBlock = 'Waktu luang';
  static const freeTimeBeforeReturn = 'Bebas santai di sekitar sini sebelum jalan ke stasiun.';
  static const freeTimeBeforeAgenda = 'Bebas dulu sebelum agenda berikutnya.';
  static const fillMore = 'Isi 1 tempat lagi';
  static String returnEarlier(String time) => 'Pulang jam $time';

  // Timeline perjalanan
  static String startAt(String station) => 'Mulai di $station';
  static String departFromPlace(String place) => 'Berangkat dari $place';
  static String arriveAt(String station) => 'Tiba di $station';
  static String walkTo(String stop, String duration) => 'Jalan kaki ke $stop · $duration';
  static String ojolTo(String stop, String duration) => 'Ojol ke $stop · $duration';
  static String walkFrom(String stop, String duration) => 'Jalan kaki dari $stop · $duration';
  static String ojolFrom(String stop, String duration) => 'Ojol dari $stop · $duration';
  static String rideStep(String from, String to, int stops, String duration, int wait) =>
      '$from ke $to · $stops halte · $duration${wait > 0 ? ' · tunggu ±$wait mnt' : ''}';
  static String arriveAround(String time) => 'tiba ±$time';

  // Rute transum langsung (Google Routes lewat Edge Function)
  static const liveTransitTitle = 'Rute transum';
  static const liveTransitSource = 'Rute dari Google Maps';
  static String liveTransitSummary(String duration, String time) => '$duration · tiba ±$time';
  static String liveTransitSlower(String extra) =>
      'Lebih lama $extra dari rencana. Kalau mau naik transum, berangkat lebih awal.';
  static String transitStops(int n) => '$n halte';
  static String transitTowards(String headsign) => 'arah $headsign';
  static String transitRide(String from, String to) => '$from → $to';
  static String transitWalk(String duration) => 'Jalan kaki $duration';

  // Detail tempat dari Google Places
  static const googleData = 'Data Google';
  static String ratingCount(int n) => '($n ulasan)';
  static const closedTemporarily = 'Tutup sementara';
  static const closedPermanently = 'Tutup permanen';
  static const feederLabel = 'KA Feeder';
  static const noTransumData = 'Belum ada data transum untuk rute ini, jadi kami sarankan ojol.';
  static String droppedAfterEdit(String names) => '$names nggak muat lagi, jadi dilepas dulu.';
  static const noSavedTrip = 'Belum ada trip tersimpan. Bikin rencana dulu, nanti muncul di sini.';
  static const stayTitle = 'Mau berapa lama di sini?';
  static String stayUntil(String time) => 'Sampai $time';
  static const stayHint = 'Jam tempat berikutnya ikut digeser. Kalau nggak muat, tempat terakhir dilepas.';
  static const changeStay = 'Ubah lama di sini';
  static String paceTooLight(String free, int stops) =>
      'Waktu luangmu $free tapi cuma $stops tempat. Pilih Pas atau Padat biar lebih terisi.';
  static const stayHere = 'Lama di tempat ini';
  static const changeDuration = 'Ubah';
  static String swapped(String from, String to) => '$from diganti $to';
  static String feederTitle(String from, String to) => 'KA Feeder $from → $to';
  static const locationOff = 'GPS kamu mati. Nyalain dulu biar posisimu kelihatan.';
  static const locationDenied = 'Izin lokasi belum dikasih. Coba ketuk lagi dan pilih Izinkan.';
  static const locationDeniedForever = 'Izin lokasi ditolak. Buka pengaturan buat ngizinin.';
  static const locationFailed = 'Lokasimu belum ketemu. Coba lagi di tempat terbuka.';
  static const openSettings = 'Pengaturan';
  static const mapAttributionShort = '© OpenStreetMap';
  // Mode jalan
  static const liveNow = 'Sekarang';
  static const liveNext = 'Berikutnya';
  static const liveDone = 'Trip selesai. Makasih udah jalan bareng OTWEY!';
  static const liveFullPlan = 'Rencana lengkap';
  static const liveSimulate = 'Coba simulasi';
  static const liveSimulating = 'Mode simulasi: ketuk "Udah sampai" buat lanjut';
  static String liveStartsIn(String date, int days) =>
      days == 1 ? 'Trip kamu besok, $date' : 'Trip kamu $date, $days hari lagi';
  static const liveStartsHint = 'Mode jalan aktif otomatis di hari H dan ngikutin jam. Sekarang kamu bisa cek rencananya atau coba simulasi.';
  static const livePast = 'Tanggal trip ini sudah lewat.';
  static const liveTrainHint = 'Naik kereta sesuai jadwal di tiket.';
  static const liveFeederHint = 'KA Feeder gratis buat penumpang Whoosh, tunjukkan tiket.';
  static const liveFreeTitle = 'Waktu luang';
  static const liveLeaveBy = 'Jalan paling telat';
  static const directions = 'Petunjuk arah';
  static const openMapsFailed = 'Aplikasi peta nggak bisa dibuka.';
  static String liveWalk(int m) => 'Jalan kaki $m mnt';
  static const dateQuestion = 'Mau jalan tanggal berapa?';
  static const today = 'Hari ini';
  static const thisSaturday = 'Sabtu ini';
  static const prevMonth = 'Bulan sebelumnya';
  static const nextMonth = 'Bulan berikutnya';
  static String pickDate(String date) => 'Pilih $date';
  static const exploreAll = 'Lihat semua di Jelajah';
  static const savedInWishlist = 'Tersimpan di wishlist';
  static const tapToCopy = 'ketuk buat salin';
  static const addressCopied = 'Alamat disalin';
  // Filter Jelajah
  static const filterTitle = 'Filter tempat';
  static const filterOpenNow = 'Buka sekarang';
  static const filterOnlySaved = 'Cuma yang di wishlist';
  static const filterBudget = 'Budget paling mahal';
  static const filterAll = 'Semua';
  static const filterFeatures = 'Fasilitas';
  static const filterReset = 'Reset';
  static String filterApply(int n) => 'Lihat $n tempat';
  static const clearSearch = 'Hapus pencarian';
  static String searchResult(String q) => 'Hasil "$q"';
  static const noResult = 'Belum ada tempat yang cocok. Coba kata lain atau longgarkan filter.';
  static const close = 'Tutup';
  static const selectedOnMap = 'Dipilih di peta';
  // Tambah tujuan
  static const searchPlaceOrAddress = 'Cari tempat atau alamat';
  static const searchFailed = 'Pencarian online gagal. Cek koneksi, atau ketuk peta buat pilih titik.';
  static const searchNotFound = 'Nggak ketemu. Coba nama jalan atau gedung, atau ketuk peta.';
  static const searchAttribution = 'Hasil alamat dari OpenStreetMap (Nominatim)';
  static const pinNameHint = 'Nama tujuan, misal Kantor klien';
  static const pickPointHint = 'Cari di atas atau ketuk peta buat pilih titik';
  static const pickPointFirst = 'Pilih titik tujuannya dulu di peta';
  static const endAfterStart = 'Jam selesai harus setelah jam mulai';
  static const editTripTitle = 'Ubah asal, tanggal, dan jam';
  static const removePin = 'Hapus tujuan';
}
