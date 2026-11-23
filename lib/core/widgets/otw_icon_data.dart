// GENERATED dari set ikon OTWEY (canvas "Ikon OTWEY"). Jangan edit manual.
// Token di string SVG diganti saat render: {C} warna garis, {FB} {KI} {FS} {KS} {FP} isi/potongan.

enum OtwIcon {
  home,
  explore,
  ticket,
  user,
  bell,
  search,
  swap,
  arrow,
  calendar,
  clock,
  pin,
  lock,
  heart,
  star,
  wallet,
  done,
  info,
  help,
  moon,
  settings,
  logout,
  share,
  edit,
  filter,
  more,
  back,
  chevron,
  close,
  plus,
  minus,
  check,
  navigate,
  locate,
  route,
  flag,
  whoosh,
  train,
  bus,
  angkot,
  ojol,
  car,
  walk,
  station,
  bowl,
  mountain,
  city,
  briefcase,
  bag,
  family,
  ferris,
  mix,
  rice,
  sate,
  icecream,
  coffee,
  gift,
}

/// Gerak satu ikon utuh saat dipilih.
enum OtwIconMotion { pop, popSoft, bounce, wiggle, spin, ring, drop, drive, nudge, flip, none }

/// Gerak bagian tertentu ikon (asap, matahari, jendela, roda, sumpit, pita, titik).
enum OtwLayerMotion { steam, sun, blink, wheel, chop, bow, dot }

class OtwIconLayer {
  const OtwIconLayer(this.body, {this.motion, this.delay = 0});

  /// Isi elemen SVG (path, circle, rect) dalam grid 24.
  final String body;
  final OtwLayerMotion? motion;

  /// Urutan jeda 0, 1, 2 (kelipatan 120 ms).
  final int delay;
}

class OtwIconSpec {
  const OtwIconSpec(this.layers, this.motion);

  final List<OtwIconLayer> layers;
  final OtwIconMotion motion;
}

const otwIconSpecs = <OtwIcon, OtwIconSpec>{
  OtwIcon.home: OtwIconSpec([
    OtwIconLayer('<path d="M4 10.8a2 2 0 0 1 .75-1.56l6-4.8a2 2 0 0 1 2.5 0l6 4.8A2 2 0 0 1 20 10.8V18a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 18z" fill="{FB}"/><path d="M9.5 20.5v-3a2.5 2.5 0 0 1 5 0v3" stroke="{KI}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.explore: OtwIconSpec([
    OtwIconLayer('<circle cx="12" cy="12" r="9" fill="{FB}"/><path d="M15.3 8.7l-1.8 4.8-4.8 1.8 1.8-4.8z" stroke="{KI}"/>'),
  ], OtwIconMotion.spin),
  OtwIcon.ticket: OtwIconSpec([
    OtwIconLayer('<path d="M3.5 8a2.5 2.5 0 0 1 2.5-2.5h12A2.5 2.5 0 0 1 20.5 8v1.2a2.8 2.8 0 0 0 0 5.6V16a2.5 2.5 0 0 1-2.5 2.5H6A2.5 2.5 0 0 1 3.5 16v-1.2a2.8 2.8 0 0 0 0-5.6z" fill="{FB}"/><path d="M15 8.6v.8M15 11.6v.8M15 14.6v.8" stroke="{KI}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.user: OtwIconSpec([
    OtwIconLayer('<circle cx="12" cy="7.5" r="4" fill="{FB}"/><path d="M4.5 19.8c0-3.5 3.4-5.8 7.5-5.8s7.5 2.3 7.5 5.8a.7.7 0 0 1-.7.7H5.2a.7.7 0 0 1-.7-.7z" fill="{FB}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.bell: OtwIconSpec([
    OtwIconLayer('<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.2 1.4a.6.6 0 0 1-.45 1H5.25a.6.6 0 0 1-.45-1z" fill="{FB}"/><path d="M10.2 21.2a2 2 0 0 0 3.6 0"/>'),
  ], OtwIconMotion.ring),
  OtwIcon.search: OtwIconSpec([
    OtwIconLayer('<circle cx="10.5" cy="10.5" r="6.5" fill="{FB}"/><path d="M15.5 15.5l4.5 4.5"/><path d="M8 8.8a3 3 0 0 1 2-1.6" stroke="{KI}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.swap: OtwIconSpec([
    OtwIconLayer('<path d="M4 8h14.5M15 4.5L18.5 8 15 11.5M20 16H5.5M9 12.5L5.5 16 9 19.5"/>'),
  ], OtwIconMotion.flip),
  OtwIcon.arrow: OtwIconSpec([
    OtwIconLayer('<path d="M4.5 12h15M14 6.5l5.5 5.5-5.5 5.5"/>'),
  ], OtwIconMotion.nudge),
  OtwIcon.calendar: OtwIconSpec([
    OtwIconLayer('<path d="M4 8.5a3 3 0 0 1 3-3h10a3 3 0 0 1 3 3v9a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z" fill="{FB}"/><path d="M4.5 10.5h15M8.5 14.5h.01M12 14.5h.01M15.5 14.5h.01" stroke="{KI}"/><path d="M8.5 3.5v3M15.5 3.5v3"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.clock: OtwIconSpec([
    OtwIconLayer('<circle cx="12" cy="12" r="9" fill="{FB}"/><path d="M12 7.5V12l3 2" stroke="{KI}"/>'),
  ], OtwIconMotion.spin),
  OtwIcon.pin: OtwIconSpec([
    OtwIconLayer('<path d="M12 21.5s-7-6-7-11.6a7 7 0 0 1 14 0c0 5.6-7 11.6-7 11.6z" fill="{FB}"/><circle cx="12" cy="9.8" r="2.4" stroke="{KI}"/>'),
  ], OtwIconMotion.drop),
  OtwIcon.lock: OtwIconSpec([
    OtwIconLayer('<path d="M8 10V7.5a4 4 0 0 1 8 0V10"/><path d="M5 12.5A2.5 2.5 0 0 1 7.5 10h9a2.5 2.5 0 0 1 2.5 2.5V18a2.5 2.5 0 0 1-2.5 2.5h-9A2.5 2.5 0 0 1 5 18z" fill="{FB}"/><path d="M12 14.3v1.9" stroke="{KI}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.heart: OtwIconSpec([
    OtwIconLayer('<path d="M12 20s-8-4.7-8-10.4A4.3 4.3 0 0 1 12 7.2a4.3 4.3 0 0 1 8 2.4C20 15.3 12 20 12 20z" fill="{FB}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.star: OtwIconSpec([
    OtwIconLayer('<path d="M12 3.8l2.45 4.95 5.45.8-3.95 3.85.93 5.43L12 16.27l-4.88 2.56.93-5.43L4.1 9.55l5.45-.8z" fill="{FB}"/>'),
  ], OtwIconMotion.spin),
  OtwIcon.wallet: OtwIconSpec([
    OtwIconLayer('<path d="M4 7.5A2.5 2.5 0 0 1 6.5 5h10a1 1 0 0 1 1 1v2H19a1 1 0 0 1 1 1v9a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 18z" fill="{FB}"/><path d="M4.5 8h12.8M16 14h.01" stroke="{KI}"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.done: OtwIconSpec([
    OtwIconLayer('<circle cx="12" cy="12" r="9" fill="{FB}"/><path d="M8 12.3l2.8 2.7L16 9.6" stroke="{KI}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.info: OtwIconSpec([
    OtwIconLayer('<circle cx="12" cy="12" r="9" fill="{FB}"/><path d="M12 11.2v4.8M12 8h.01" stroke="{KI}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.help: OtwIconSpec([
    OtwIconLayer('<circle cx="12" cy="12" r="9" fill="{FB}"/><path d="M9.7 9.6a2.4 2.4 0 0 1 4.6.9c0 1.7-2.3 2-2.3 3.5M12 16.6h.01" stroke="{KI}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.moon: OtwIconSpec([
    OtwIconLayer('<path d="M19.5 14.6A7.8 7.8 0 1 1 9.4 4.5a6.2 6.2 0 0 0 10.1 10.1z" fill="{FB}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.settings: OtwIconSpec([
    OtwIconLayer('<path d="M10.3 3.6a1.7 1.7 0 0 1 3.4 0l.2.9a1.7 1.7 0 0 0 2.5 1l.8-.4a1.7 1.7 0 0 1 2.4 2.4l-.4.8a1.7 1.7 0 0 0 1 2.5l.9.2a1.7 1.7 0 0 1 0 3.4l-.9.2a1.7 1.7 0 0 0-1 2.5l.4.8a1.7 1.7 0 0 1-2.4 2.4l-.8-.4a1.7 1.7 0 0 0-2.5 1l-.2.9a1.7 1.7 0 0 1-3.4 0l-.2-.9a1.7 1.7 0 0 0-2.5-1l-.8.4a1.7 1.7 0 0 1-2.4-2.4l.4-.8a1.7 1.7 0 0 0-1-2.5l-.9-.2a1.7 1.7 0 0 1 0-3.4l.9-.2a1.7 1.7 0 0 0 1-2.5l-.4-.8a1.7 1.7 0 0 1 2.4-2.4l.8.4a1.7 1.7 0 0 0 2.5-1z" fill="{FB}"/><circle cx="12" cy="12" r="2.6" stroke="{KI}"/>'),
  ], OtwIconMotion.spin),
  OtwIcon.logout: OtwIconSpec([
    OtwIconLayer('<path d="M13.5 4.5H7A2.5 2.5 0 0 0 4.5 7v10A2.5 2.5 0 0 0 7 19.5h6.5M10 12h10M16.5 8.5L20 12l-3.5 3.5"/>'),
  ], OtwIconMotion.nudge),
  OtwIcon.share: OtwIconSpec([
    OtwIconLayer('<path d="M4.5 13v5a2.5 2.5 0 0 0 2.5 2.5h10a2.5 2.5 0 0 0 2.5-2.5v-5M12 3.5v11M8 7.3l4-3.8 4 3.8"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.edit: OtwIconSpec([
    OtwIconLayer('<path d="M4 20l.8-4.1L15.5 5.2a2.2 2.2 0 0 1 3.1 0l.2.2a2.2 2.2 0 0 1 0 3.1L8.1 19.2z" fill="{FB}"/><path d="M13.6 7.1l3.3 3.3" stroke="{KI}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.filter: OtwIconSpec([
    OtwIconLayer('<path d="M4 7h8.5M17.5 7H20M4 17h2.5M11.5 17H20"/><circle cx="15" cy="7" r="2.3" fill="{FP}"/><circle cx="9" cy="17" r="2.3" fill="{FP}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.more: OtwIconSpec([
    OtwIconLayer('<circle cx="5.5" cy="12" r="1.6" fill="{FB}"/>', motion: OtwLayerMotion.dot),
    OtwIconLayer('<circle cx="12" cy="12" r="1.6" fill="{FB}"/>', motion: OtwLayerMotion.dot, delay: 1),
    OtwIconLayer('<circle cx="18.5" cy="12" r="1.6" fill="{FB}"/>', motion: OtwLayerMotion.dot, delay: 2),
  ], OtwIconMotion.none),
  OtwIcon.back: OtwIconSpec([
    OtwIconLayer('<path d="M15 18.5L8.5 12 15 5.5"/>'),
  ], OtwIconMotion.nudge),
  OtwIcon.chevron: OtwIconSpec([
    OtwIconLayer('<path d="M9.5 6l6 6-6 6"/>'),
  ], OtwIconMotion.nudge),
  OtwIcon.close: OtwIconSpec([
    OtwIconLayer('<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.plus: OtwIconSpec([
    OtwIconLayer('<path d="M12 5v14M5 12h14"/>'),
  ], OtwIconMotion.spin),
  OtwIcon.minus: OtwIconSpec([
    OtwIconLayer('<path d="M5 12h14"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.check: OtwIconSpec([
    OtwIconLayer('<path d="M5 12.5l4.6 4.5L19 7.5"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.navigate: OtwIconSpec([
    OtwIconLayer('<path d="M4.3 10.6L19.4 4.3a.8.8 0 0 1 1.05 1.05l-6.3 15.1a.6.6 0 0 1-1.12-.06l-1.9-6.2-6.2-1.9a.6.6 0 0 1-.06-1.12z" fill="{FB}"/>'),
  ], OtwIconMotion.nudge),
  OtwIcon.locate: OtwIconSpec([
    OtwIconLayer('<path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3"/><circle cx="12" cy="12" r="6.5" fill="{FB}"/><circle cx="12" cy="12" r="2" stroke="{KI}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.route: OtwIconSpec([
    OtwIconLayer('<path d="M6.5 17.5H15a3.5 3.5 0 0 0 0-7H9a3.5 3.5 0 0 1 0-7h8.5"/><circle cx="6" cy="17.5" r="2.4" fill="{FP}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.flag: OtwIconSpec([
    OtwIconLayer('<path d="M6 21V4"/><path d="M6 4.5h11.2a.6.6 0 0 1 .5.9L15.8 8.5l1.9 3.1a.6.6 0 0 1-.5.9H6z" fill="{FB}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.whoosh: OtwIconSpec([
    OtwIconLayer('<path d="M2.5 15.2v-3.7A2.5 2.5 0 0 1 5 9h7.5c3.6 0 6.9 2 8.6 5.2l.15.3a1.2 1.2 0 0 1-1.05 1.7H3.5a1 1 0 0 1-1-1z" fill="{FB}"/><path d="M6 12h.8M9.2 12h.8M12.4 12h.8" stroke="{KI}"/><path d="M3 19.5h18"/>'),
  ], OtwIconMotion.drive),
  OtwIcon.train: OtwIconSpec([
    OtwIconLayer('<path d="M6 7a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v7.5a3 3 0 0 1-3 3H9a3 3 0 0 1-3-3z" fill="{FB}"/><path d="M6.5 10.5h11M9.5 14h.01M14.5 14h.01" stroke="{KI}"/><path d="M9 21l1.3-3.5M15 21l-1.3-3.5"/>'),
  ], OtwIconMotion.drive),
  OtwIcon.bus: OtwIconSpec([
    OtwIconLayer('<path d="M5 6.5A3.5 3.5 0 0 1 8.5 3h7A3.5 3.5 0 0 1 19 6.5V17a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 17z" fill="{FB}"/><path d="M5.5 11.5h13M8.5 15h.01M15.5 15h.01M10 6h4" stroke="{KI}"/><path d="M7.5 18.5V21M16.5 18.5V21"/>'),
  ], OtwIconMotion.drive),
  OtwIcon.angkot: OtwIconSpec([
    OtwIconLayer('<path d="M2.5 14.5v-6A2.5 2.5 0 0 1 5 6h9.6a2.5 2.5 0 0 1 2 1l3.4 4.5a2.5 2.5 0 0 1 .5 1.5v1.5a1.5 1.5 0 0 1-1.5 1.5H4a1.5 1.5 0 0 1-1.5-1.5z" fill="{FB}"/><path d="M3 10.5h15.5M9.5 6.5v4" stroke="{KI}"/><circle cx="7" cy="16.5" r="2.2" fill="{FS}" stroke="{KS}"/><circle cx="16.5" cy="16.5" r="2.2" fill="{FS}" stroke="{KS}"/>'),
  ], OtwIconMotion.drive),
  OtwIcon.ojol: OtwIconSpec([
    OtwIconLayer('<path d="M3.5 15.2a3.7 3.7 0 0 1 3.7-3.7h3.3a1.5 1.5 0 0 1 1.3.75l1.4 2.45h3.6a1.8 1.8 0 0 1 1.7 1.2l.2.8H3.5z" fill="{FB}"/><path d="M15.8 14.5L13.6 6.5H11.2M12.5 6.5h1.1"/><path d="M8.5 11.5V9.8a.8.8 0 0 1 .8-.8H11"/><circle cx="6.2" cy="17.5" r="2.4" fill="{FS}" stroke="{KS}"/><circle cx="18" cy="17.5" r="2.4" fill="{FS}" stroke="{KS}"/>'),
  ], OtwIconMotion.drive),
  OtwIcon.car: OtwIconSpec([
    OtwIconLayer('<path d="M3 15.5v-2.6a2 2 0 0 1 1.3-1.9L6 10.4l1.7-3.3A2 2 0 0 1 9.5 6h5a2 2 0 0 1 1.8 1.1l1.7 3.3 1.7.6a2 2 0 0 1 1.3 1.9v2.6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z" fill="{FB}"/><path d="M6.5 10.5h11" stroke="{KI}"/><circle cx="7.5" cy="16.5" r="2.2" fill="{FS}" stroke="{KS}"/><circle cx="16.5" cy="16.5" r="2.2" fill="{FS}" stroke="{KS}"/>'),
  ], OtwIconMotion.drive),
  OtwIcon.walk: OtwIconSpec([
    OtwIconLayer('<circle cx="13.5" cy="4.5" r="1.9" fill="{FB}"/><path d="M11 20.5l1.7-5.2 2.8 2.4v2.8M8 12.2l2.4-3.4a1.5 1.5 0 0 1 1.9-.5l2 1 1.3 2.2 2 .8M12.7 15.3l-.9-6.6"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.station: OtwIconSpec([
    OtwIconLayer('<path d="M5 10h14v9a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 19z" fill="{FB}"/><path d="M3.6 9.4l7.6-5a1.5 1.5 0 0 1 1.6 0l7.6 5a.4.4 0 0 1-.2.7H3.8a.4.4 0 0 1-.2-.7z" fill="{FB}"/><path d="M9.5 20.5v-3.5a2.5 2.5 0 0 1 5 0v3.5" stroke="{KI}"/>'),
  ], OtwIconMotion.pop),
  OtwIcon.bowl: OtwIconSpec([
    OtwIconLayer('<path d="M3.5 11.5h17a8.5 7.6 0 0 1-17 0z" fill="{FB}"/><path d="M9 20.5h6"/>'),
    OtwIconLayer('<path d="M8.5 3.8c-.8 1 .8 2 0 3.2"/>', motion: OtwLayerMotion.steam),
    OtwIconLayer('<path d="M12 3.8c-.8 1 .8 2 0 3.2"/>', motion: OtwLayerMotion.steam, delay: 1),
    OtwIconLayer('<path d="M15.5 3.8c-.8 1 .8 2 0 3.2"/>', motion: OtwLayerMotion.steam, delay: 2),
  ], OtwIconMotion.popSoft),
  OtwIcon.mountain: OtwIconSpec([
    OtwIconLayer('<path d="M2.8 19.5l5.7-9.2a1.2 1.2 0 0 1 2 0l2.5 4 1.5-2.2a1.2 1.2 0 0 1 2 0l4.7 7.4z" fill="{FB}"/><path d="M7.4 13.6l1.6.9 1.6-.9" stroke="{KI}"/>'),
    OtwIconLayer('<circle cx="17.5" cy="5.5" r="2.2"/>', motion: OtwLayerMotion.sun),
  ], OtwIconMotion.none),
  OtwIcon.city: OtwIconSpec([
    OtwIconLayer('<path d="M4 20.5V9.5a1.5 1.5 0 0 1 1.5-1.5H10V20.5z" fill="{FB}"/><path d="M10 20.5V4.5A1.5 1.5 0 0 1 11.5 3h7A1.5 1.5 0 0 1 20 4.5v16z" fill="{FB}"/>'),
    OtwIconLayer('<path d="M13.5 7h3" stroke="{KI}"/>', motion: OtwLayerMotion.blink),
    OtwIconLayer('<path d="M13.5 10.5h3" stroke="{KI}"/>', motion: OtwLayerMotion.blink, delay: 1),
    OtwIconLayer('<path d="M13.5 14h3" stroke="{KI}"/>', motion: OtwLayerMotion.blink, delay: 2),
    OtwIconLayer('<path d="M6.5 11.5h1M6.5 15h1" stroke="{KI}"/>', motion: OtwLayerMotion.blink, delay: 1),
    OtwIconLayer('<path d="M2.5 20.5h19"/>'),
  ], OtwIconMotion.none),
  OtwIcon.briefcase: OtwIconSpec([
    OtwIconLayer('<path d="M3.5 9.5A2.5 2.5 0 0 1 6 7h12a2.5 2.5 0 0 1 2.5 2.5V18a2.5 2.5 0 0 1-2.5 2.5H6A2.5 2.5 0 0 1 3.5 18z" fill="{FB}"/><path d="M9 7V5.5A1.5 1.5 0 0 1 10.5 4h3A1.5 1.5 0 0 1 15 5.5V7"/><path d="M3.5 12.5h17M12 11.5v2" stroke="{KI}"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.bag: OtwIconSpec([
    OtwIconLayer('<path d="M5 8.5h14l-.85 10.2a2 2 0 0 1-2 1.8H7.85a2 2 0 0 1-2-1.8z" fill="{FB}"/><path d="M9 8.5V7a3 3 0 0 1 6 0v1.5"/><path d="M9 11.5h.01M15 11.5h.01" stroke="{KI}"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.family: OtwIconSpec([
    OtwIconLayer('<circle cx="8.5" cy="7" r="3" fill="{FB}"/><path d="M3 19.5c0-3.3 2.4-5.7 5.5-5.7s5.5 2.4 5.5 5.7a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z" fill="{FB}"/><circle cx="17.6" cy="10.2" r="2.2" fill="{FB}"/><path d="M15 20c.15-2.6 1.1-4.3 2.6-4.3s2.6 1.7 2.8 4.3a.5.5 0 0 1-.5.5h-4.4a.5.5 0 0 1-.5-.5z" fill="{FB}"/>'),
  ], OtwIconMotion.bounce),
  OtwIcon.ferris: OtwIconSpec([
    OtwIconLayer('<path d="M8.5 20.5L12 11l3.5 9.5M6.5 20.5h11"/>'),
    OtwIconLayer('<circle cx="12" cy="9.5" r="6.5" fill="{FB}"/><path d="M12 5.5v8M8 9.5h8M9.2 6.7l5.6 5.6M14.8 6.7l-5.6 5.6" stroke="{KI}"/><circle cx="12" cy="3" r="1.3" fill="{FP}"/><circle cx="18.5" cy="9.5" r="1.3" fill="{FP}"/><circle cx="5.5" cy="9.5" r="1.3" fill="{FP}"/>', motion: OtwLayerMotion.wheel),
  ], OtwIconMotion.none),
  OtwIcon.mix: OtwIconSpec([
    OtwIconLayer('<rect x="4" y="4" width="7" height="7" rx="2.2" fill="{FB}"/><rect x="13" y="13" width="7" height="7" rx="2.2" fill="{FB}"/><circle cx="16.5" cy="7.5" r="3.5" fill="{FP}"/><path d="M7.5 13l3.5 6.5H4z" fill="{FP}"/>'),
  ], OtwIconMotion.spin),
  OtwIcon.rice: OtwIconSpec([
    OtwIconLayer('<path d="M6.2 12a5.8 4.6 0 0 1 11.6 0"/>'),
    OtwIconLayer('<path d="M14.5 8.5l5.5-5M12.5 7.8l5.2-5.3"/>', motion: OtwLayerMotion.chop),
    OtwIconLayer('<path d="M3.5 12h17a8.5 7.4 0 0 1-17 0z" fill="{FB}"/><path d="M9 20.5h6"/>'),
  ], OtwIconMotion.popSoft),
  OtwIcon.sate: OtwIconSpec([
    OtwIconLayer('<path d="M3.5 20.5l17-17"/><rect x="4.6" y="9" width="3" height="6" rx="1.5" transform="rotate(-45 12 12)" fill="{FP}"/><rect x="10.5" y="9" width="3" height="6" rx="1.5" transform="rotate(-45 12 12)" fill="{FP}"/><rect x="16.4" y="9" width="3" height="6" rx="1.5" transform="rotate(-45 12 12)" fill="{FP}"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.icecream: OtwIconSpec([
    OtwIconLayer('<path d="M8 12h8l-3.2 8.3a.86.86 0 0 1-1.6 0z" fill="{FB}"/><path d="M6.8 11.5a5.2 5.2 0 0 1 10.4 0 .5.5 0 0 1-.5.5H7.3a.5.5 0 0 1-.5-.5z" fill="{FP}"/><path d="M8 12h8" stroke="{KI}"/><path d="M14.5 4.2l1.3-1.6"/>'),
  ], OtwIconMotion.wiggle),
  OtwIcon.coffee: OtwIconSpec([
    OtwIconLayer('<path d="M4.5 9h11.5v4.3a5 5 0 0 1-5 5h-1.5a5 5 0 0 1-5-5z" fill="{FB}"/><path d="M16 10.4h1.3a2.3 2.3 0 0 1 0 4.6H16M4 21h12.5"/>'),
    OtwIconLayer('<path d="M8 3.6c-.7.9.7 1.8 0 2.8"/>', motion: OtwLayerMotion.steam),
    OtwIconLayer('<path d="M11.5 3.6c-.7.9.7 1.8 0 2.8"/>', motion: OtwLayerMotion.steam, delay: 1),
  ], OtwIconMotion.popSoft),
  OtwIcon.gift: OtwIconSpec([
    OtwIconLayer('<path d="M5 11.5h14v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z" fill="{FB}"/><path d="M4 8.6a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v2.4a.5.5 0 0 1-.5.5h-15a.5.5 0 0 1-.5-.5z" fill="{FS}" stroke="{KS}"/><path d="M12 12v8" stroke="{KI}"/>'),
    OtwIconLayer('<path d="M12 7.6c-.9-2.8-4.4-3.6-4.4-1.6 0 1.1 1.6 1.6 4.4 1.6zM12 7.6c.9-2.8 4.4-3.6 4.4-1.6 0 1.1-1.6 1.6-4.4 1.6z"/>', motion: OtwLayerMotion.bow),
  ], OtwIconMotion.bounce),
};
