import '../models/category.dart';

const List<Category> seededCategories = [
  Category(
    id: 'home-plumbing',
    nameEn: 'Plumbing',
    nameUr: 'پلمبنگ (نل اور پائپ)',
    iconName: 'Wrench',
    parentCategory: 'Home Services',
    subcategories: [
      Subcategory(id: 'pipe-leak', nameEn: 'Pipe Leakage Repair', nameUr: 'پائپ لیکج کی مرمت'),
      Subcategory(id: 'sanitary-fit', nameEn: 'Sanitary Fitting', nameUr: 'سینیٹری فٹنگ'),
      Subcategory(id: 'water-tank', nameEn: 'Water Tank Cleaning', nameUr: 'پانی کی ٹینکی صفائی'),
      Subcategory(id: 'motor-repair', nameEn: 'Water Pump / Motor Repair', nameUr: 'پانی کی موٹر مرمت'),
    ],
  ),
  Category(
    id: 'home-electrical',
    nameEn: 'Electrical Work',
    nameUr: 'بجلی کا کام',
    iconName: 'Zap',
    parentCategory: 'Home Services',
    subcategories: [
      Subcategory(id: 'wiring', nameEn: 'UPS / Inverter & Solar Wiring', nameUr: 'یو پی ایس اور سولر وائرنگ'),
      Subcategory(id: 'fan-light', nameEn: 'Fan & Light Installation', nameUr: 'پنکھے اور لائٹ کی انسٹالیشن'),
      Subcategory(id: 'short-circuit', nameEn: 'Short Circuit Fixing', nameUr: 'شارٹ سرکٹ کی درستگی'),
      Subcategory(id: 'switch-board', nameEn: 'Switchboard Repair', nameUr: 'سوئچ بورڈ مرمت'),
    ],
  ),
  Category(
    id: 'ac-appliance',
    nameEn: 'AC & Appliances',
    nameUr: 'اے سی اور ہوم اپلائنسز',
    iconName: 'Wind',
    parentCategory: 'Home Services',
    subcategories: [
      Subcategory(id: 'ac-service', nameEn: 'AC Service & Gas Refill', nameUr: 'اے سی سروس اور گیس چارج'),
      Subcategory(id: 'fridge-repair', nameEn: 'Refrigerator Repair', nameUr: 'فریج مرمت'),
      Subcategory(id: 'washing-machine', nameEn: 'Washing Machine Repair', nameUr: 'واشنگ مشین مرمت'),
    ],
  ),
  Category(
    id: 'home-carpentry',
    nameEn: 'Carpentry & Furniture',
    nameUr: 'کارپینٹر (لکڑی کا کام)',
    iconName: 'Hammer',
    parentCategory: 'Home Services',
    subcategories: [
      Subcategory(id: 'door-lock', nameEn: 'Door Lock Repair & Polish', nameUr: 'دروازے اور لاک کی مرمت'),
      Subcategory(id: 'cabinet', nameEn: 'Kitchen Cabinet Repair', nameUr: 'کچن کیبنٹ مرمت'),
      Subcategory(id: 'sofa-repair', nameEn: 'Sofa & Bed Repair', nameUr: 'صوفہ اور بیڈ کی مرمت'),
    ],
  ),
  Category(
    id: 'home-painting',
    nameEn: 'Painting & Masonry',
    nameUr: 'پینٹ اور راج مستری',
    iconName: 'Paintbrush',
    parentCategory: 'Construction',
    subcategories: [
      Subcategory(id: 'wall-paint', nameEn: 'House Painting / Touchup', nameUr: 'گھر کا رنگ روپغ'),
      Subcategory(id: 'masonry', nameEn: 'Masonry / Tile Work', nameUr: 'ٹائل اور راج مستری'),
      Subcategory(id: 'roof-leakage', nameEn: 'Roof Seepage & Leakage', nameUr: 'چھت کی سیم روکنا'),
    ],
  ),
  Category(
    id: 'vehicle-repair',
    nameEn: 'Mechanic & Bike Repair',
    nameUr: 'مکینک اور بائیک مرمت',
    iconName: 'Car',
    parentCategory: 'Vehicles',
    subcategories: [
      Subcategory(id: 'bike-tuning', nameEn: '70cc/125cc Bike Tuning', nameUr: 'موٹر سائیکل ٹیوننگ'),
      Subcategory(id: 'car-mechanic', nameEn: 'Car Emergency Repair', nameUr: 'گاڑی کی ہنگامی مرمت'),
      Subcategory(id: 'tyre-puncture', nameEn: 'Puncture & Battery Jumpstart', nameUr: 'پنکچر اور بیٹری جمپ اسٹارٹ'),
    ],
  ),
  Category(
    id: 'education-tutor',
    nameEn: 'Home Tutor',
    nameUr: 'ہوم ٹیوٹر (استاد)',
    iconName: 'BookOpen',
    parentCategory: 'Education',
    subcategories: [
      Subcategory(id: 'matric-fsc', nameEn: 'Matric / FSc Science Tutor', nameUr: 'میٹرک اور ایف ایس سی ٹیوٹر'),
      Subcategory(id: 'quran-tutor', nameEn: 'Quran Teacher', nameUr: 'قرآن پاک کی تعلیم'),
      Subcategory(id: 'english-spoken', nameEn: 'English Spoken & Primary', nameUr: 'انگلش اور پرائمری کلاسز'),
    ],
  ),
  Category(
    id: 'cleaning-maid',
    nameEn: 'Cleaning & Housekeeping',
    nameUr: 'صفائی اور گھر کے کام',
    iconName: 'Sparkles',
    parentCategory: 'Cleaning',
    subcategories: [
      Subcategory(id: 'deep-clean', nameEn: 'Deep House Cleaning', nameUr: 'گھر کی مکمل صفائی'),
      Subcategory(id: 'sofa-wash', nameEn: 'Sofa & Carpet Wash', nameUr: 'صوفہ اور قالین واش'),
      Subcategory(id: 'disinfection', nameEn: 'Water Tank & Fumigation', nameUr: 'کینمیکل سپرے اور صفائی'),
    ],
  ),
  Category(
    id: 'delivery-driver',
    nameEn: 'Driver & Delivery',
    nameUr: 'ڈرائیور اور ڈلیوری',
    iconName: 'Truck',
    parentCategory: 'Delivery',
    subcategories: [
      Subcategory(id: 'personal-driver', nameEn: 'Daily / Hourly Driver', nameUr: 'روزانہ یا گھنٹے کا ڈرائیور'),
      Subcategory(id: 'luggage-moving', nameEn: 'Pickup Loader / Moving', nameUr: 'سامان منتقل کرنا (لوڈر)'),
      Subcategory(id: 'rider', nameEn: 'Local Parcel Rider', nameUr: 'لوکل پارسل رائڈر'),
    ],
  ),
  Category(
    id: 'tech-repair',
    nameEn: 'Mobile & Laptop Repair',
    nameUr: 'موبائل اور لیپ ٹاپ ریپئر',
    iconName: 'Smartphone',
    parentCategory: 'Technology',
    subcategories: [
      Subcategory(id: 'mobile-screen', nameEn: 'Mobile Screen / Battery Replacement', nameUr: 'موبائل سکرین اور بیٹری'),
      Subcategory(id: 'laptop-windows', nameEn: 'Laptop Hardware & Windows', nameUr: 'لیپ ٹاپ کی ہارڈویئر و ونڈوز'),
      Subcategory(id: 'wifi-setup', nameEn: 'CCTV & WiFi Router Setup', nameUr: 'سی سی ٹی وی اور وائی فائی سیٹ اپ'),
    ],
  ),
];

const List<LahoreLocation> lahoreLocations = [
  LahoreLocation('Gulberg III, Lahore', 31.5204, 74.3587),
  LahoreLocation('DHA Phase 5, Lahore', 31.4697, 74.4027),
  LahoreLocation('Model Town, Lahore', 31.4829, 74.3218),
  LahoreLocation('Johar Town, Lahore', 31.465, 74.296),
  LahoreLocation('Ferozepur Road, Lahore', 31.503, 74.331),
  LahoreLocation('Garden Town, Lahore', 31.501, 74.322),
  LahoreLocation('Allama Iqbal Town, Lahore', 31.508, 74.288),
  LahoreLocation('Cantt, Lahore', 31.532, 74.372),
];

class LahoreLocation {
  final String name;
  final double lat;
  final double lng;
  const LahoreLocation(this.name, this.lat, this.lng);
}

List<Map<String, dynamic>> get lahoreLocationMaps =>
    lahoreLocations.map((l) => {'name': l.name, 'lat': l.lat, 'lng': l.lng}).toList();
