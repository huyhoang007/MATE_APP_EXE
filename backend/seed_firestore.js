// ============================================================
// MATE — Firestore Seed Script
// ============================================================
// Seed dữ liệu vào các collection read-only:
//   places, shopItems, shopCategories, gameQuestions
//
// Chạy: node seed_firestore.js [--only places,shopItems,...]
// ============================================================

require('dotenv').config();
const admin = require('firebase-admin');

// --- Init Firebase Admin ---
const serviceAccount = require(
  process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json'
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID || 'mateapp-8d44d',
});

const db = admin.firestore();

// --- Parse CLI args ---
const args = process.argv.slice(2);
let onlyCollections = null;
const onlyIdx = args.indexOf('--only');
if (onlyIdx !== -1 && args[onlyIdx + 1]) {
  onlyCollections = args[onlyIdx + 1].split(',').map(s => s.trim());
}

function shouldSeed(name) {
  return !onlyCollections || onlyCollections.includes(name);
}

// --- Helper: slugify for stable doc IDs ---
function slug(str) {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 60);
}

// ============================================================
// PLACES — Địa điểm hẹn hò thật tại TP.HCM
// ============================================================
const PLACES = [
  {
    name: 'The Coffee House - Nguyễn Huệ',
    category: 'eat',
    area: 'Quận 1',
    address: '123 Nguyễn Huệ, Bến Nghé, Quận 1',
    lat: 10.7736, lng: 106.7032,
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 150000,
    priceText: '45K - 90K / người',
    durationMin: 60,
    moods: ['chill', 'romantic'],
    slots: ['Sáng', 'Chiều', 'Tối'],
    hours: '07:00 – 22:00',
    description: 'Chuỗi cà phê nổi tiếng với không gian ấm cúng, thích hợp cho buổi hẹn hò nhẹ nhàng.',
    rating: 4.3, reviewCount: 1250,
    isPartner: true, active: true,
  },
  {
    name: 'Pizza 4P\'s - Đông Du',
    category: 'eat',
    area: 'Quận 1',
    address: '8 Đông Du, Bến Nghé, Quận 1',
    lat: 10.7780, lng: 106.7040,
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 450000,
    priceText: '250K - 500K / 2 người',
    durationMin: 90,
    moods: ['romantic', 'luxury'],
    slots: ['Chiều', 'Tối'],
    hours: '10:00 – 22:00',
    description: 'Pizza Nhật Bản thủ công với phô mai tự làm. Không gian sang trọng, lãng mạn.',
    rating: 4.6, reviewCount: 2100,
    isPartner: false, active: true,
  },
  {
    name: 'Quán ăn Cô Ba',
    category: 'eat',
    area: 'Quận 3',
    address: '45 Lê Lợi, Quận 3',
    lat: 10.7759, lng: 106.6924,
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 200000,
    priceText: '100K - 200K / 2 người',
    durationMin: 60,
    moods: ['chill', 'fun'],
    slots: ['Sáng', 'Chiều', 'Tối'],
    hours: '08:00 – 21:30',
    description: 'Ẩm thực truyền thống Sài Gòn, đậm vị quê hương trong không gian hoài cổ.',
    rating: 4.2, reviewCount: 890,
    isPartner: true, active: true,
  },
  {
    name: 'Góc Hà Nội - Phở Bò',
    category: 'eat',
    area: 'Quận 1',
    address: '12 Trần Hưng Đạo, Quận 1',
    lat: 10.7660, lng: 106.6937,
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 160000,
    priceText: '60K - 100K / người',
    durationMin: 45,
    moods: ['chill'],
    slots: ['Sáng', 'Chiều'],
    hours: '06:00 – 14:00',
    description: 'Phở bò Hà Nội chính hiệu tại Sài Gòn, nước dùng ngọt thanh.',
    rating: 4.4, reviewCount: 650,
    isPartner: false, active: true,
  },
  {
    name: 'CGV Vincom Đồng Khởi',
    category: 'movie',
    area: 'Quận 1',
    address: '72 Lê Thánh Tôn, Quận 1',
    lat: 10.7789, lng: 106.7018,
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 300000,
    priceText: '90K - 200K / vé',
    durationMin: 150,
    moods: ['romantic', 'chill'],
    slots: ['Chiều', 'Tối'],
    hours: '09:00 – 23:30',
    description: 'Rạp chiếu phim hiện đại, hệ thống âm thanh Dolby Atmos, ghế đôi cho cặp đôi.',
    rating: 4.5, reviewCount: 3200,
    isPartner: true, active: true,
  },
  {
    name: 'Lotte Cinema Gò Vấp',
    category: 'movie',
    area: 'Gò Vấp',
    address: '242 Nguyễn Văn Lượng, Gò Vấp',
    lat: 10.8388, lng: 106.6471,
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 260000,
    priceText: '85K - 180K / vé',
    durationMin: 150,
    moods: ['chill', 'fun'],
    slots: ['Chiều', 'Tối'],
    hours: '09:00 – 23:00',
    description: 'Rạp phim tiện lợi khu Gò Vấp, nhiều suất chiếu, phòng VIP cho cặp đôi.',
    rating: 4.2, reviewCount: 1800,
    isPartner: false, active: true,
  },
  {
    name: 'Galaxy Cinema Phạm Văn Đồng',
    category: 'movie',
    area: 'Bình Thạnh',
    address: '819 Phạm Văn Đồng, Bình Thạnh',
    lat: 10.8279, lng: 106.7171,
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 250000,
    priceText: '80K - 170K / vé',
    durationMin: 150,
    moods: ['chill', 'romantic'],
    slots: ['Chiều', 'Tối'],
    hours: '09:00 – 23:00',
    description: 'Rạp Galaxy với hệ thống ghế ngả đôi, giá vé hợp lý.',
    rating: 4.3, reviewCount: 1500,
    isPartner: true, active: true,
  },
  {
    name: 'Suối Tiên Theme Park',
    category: 'play',
    area: 'Thủ Đức',
    address: 'Xa lộ Hà Nội, Thủ Đức',
    lat: 10.8658, lng: 106.7930,
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 400000,
    priceText: '200K - 400K / vé',
    durationMin: 240,
    moods: ['fun', 'adventure'],
    slots: ['Sáng', 'Chiều'],
    hours: '08:00 – 17:30',
    description: 'Công viên giải trí lớn nhất TP.HCM với nhiều trò chơi cảm giác mạnh.',
    rating: 4.0, reviewCount: 4500,
    isPartner: true, active: true,
  },
  {
    name: 'Bảo tàng Mỹ thuật TP.HCM',
    category: 'play',
    area: 'Quận 1',
    address: '97A Phó Đức Chính, Quận 1',
    lat: 10.7693, lng: 106.6958,
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 60000,
    priceText: '30K / vé',
    durationMin: 90,
    moods: ['romantic', 'chill'],
    slots: ['Sáng', 'Chiều'],
    hours: '09:00 – 17:00',
    description: 'Kiến trúc Pháp cổ điển, tuyệt đẹp để chụp ảnh cặp đôi và ngắm tranh.',
    rating: 4.4, reviewCount: 2200,
    isPartner: false, active: true,
  },
  {
    name: 'Landmark 81 SkyView',
    category: 'outdoor',
    area: 'Bình Thạnh',
    address: 'Vinhomes Central Park, 720A Điện Biên Phủ',
    lat: 10.7950, lng: 106.7220,
    imageAsset: 'assets/images/affiliate/outdoor.jpg',
    pricePerTwo: 500000,
    priceText: '250K / vé',
    durationMin: 60,
    moods: ['romantic', 'luxury'],
    slots: ['Chiều', 'Tối'],
    hours: '09:30 – 21:30',
    description: 'Đài quan sát trên tầng 81, ngắm toàn cảnh Sài Gòn. Cực lãng mạn vào buổi tối.',
    rating: 4.7, reviewCount: 5800,
    isPartner: false, active: true,
  },
  {
    name: 'Thảo Cầm Viên',
    category: 'outdoor',
    area: 'Quận 1',
    address: '2 Nguyễn Bỉnh Khiêm, Quận 1',
    lat: 10.7876, lng: 106.7057,
    imageAsset: 'assets/images/affiliate/outdoor.jpg',
    pricePerTwo: 100000,
    priceText: '50K / vé',
    durationMin: 120,
    moods: ['chill', 'fun'],
    slots: ['Sáng', 'Chiều'],
    hours: '07:00 – 18:00',
    description: 'Vườn bách thảo lâu đời nhất Việt Nam, không gian xanh mát giữa lòng thành phố.',
    rating: 4.1, reviewCount: 3800,
    isPartner: false, active: true,
  },
  {
    name: 'Flower Shop Hồng Tươi',
    category: 'gift',
    area: 'Quận 1',
    address: '15 Pasteur, Quận 1',
    lat: 10.7770, lng: 106.6970,
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 350000,
    priceText: '150K - 500K / bó',
    durationMin: 30,
    moods: ['romantic', 'luxury'],
    slots: ['Sáng', 'Chiều', 'Tối'],
    hours: '07:00 – 22:00',
    description: 'Hoa tươi nghệ thuật cho mọi dịp đặc biệt. Giao hàng nhanh trong 2 giờ.',
    rating: 4.5, reviewCount: 680,
    isPartner: true, active: true,
  },
  {
    name: 'Mochi Bakery',
    category: 'gift',
    area: 'Quận 1',
    address: '78 Hai Bà Trưng, Quận 1',
    lat: 10.7820, lng: 106.6990,
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 200000,
    priceText: '80K - 200K / hộp',
    durationMin: 30,
    moods: ['romantic', 'chill'],
    slots: ['Sáng', 'Chiều'],
    hours: '08:00 – 20:00',
    description: 'Bánh ngọt handmade Nhật Bản, xinh xắn và ngon miệng. Quà tặng hoàn hảo.',
    rating: 4.6, reviewCount: 420,
    isPartner: false, active: true,
  },
  {
    name: 'Cafe Rooftop M.O.I',
    category: 'eat',
    area: 'Quận 1',
    address: '151 Đồng Khởi, Quận 1',
    lat: 10.7765, lng: 106.7020,
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 300000,
    priceText: '100K - 200K / người',
    durationMin: 75,
    moods: ['romantic', 'luxury'],
    slots: ['Chiều', 'Tối'],
    hours: '10:00 – 23:00',
    description: 'Cafe rooftop view thành phố tuyệt đẹp. Cocktail và đồ ăn nhẹ phong cách Pháp.',
    rating: 4.5, reviewCount: 980,
    isPartner: false, active: true,
  },
  {
    name: 'Phố đi bộ Nguyễn Huệ',
    category: 'outdoor',
    area: 'Quận 1',
    address: 'Nguyễn Huệ, Quận 1',
    lat: 10.7730, lng: 106.7036,
    imageAsset: 'assets/images/affiliate/outdoor.jpg',
    pricePerTwo: 0,
    priceText: 'Miễn phí',
    durationMin: 60,
    moods: ['chill', 'fun', 'romantic'],
    slots: ['Chiều', 'Tối'],
    hours: '24/7',
    description: 'Phố đi bộ sầm uất nhất Sài Gòn. Dạo bộ, chụp ảnh, ăn vặt và ngắm đèn.',
    rating: 4.3, reviewCount: 7200,
    isPartner: false, active: true,
  },
  {
    name: 'Đầm Sen Park',
    category: 'play',
    area: 'Quận 11',
    address: '3 Hòa Bình, Quận 11',
    lat: 10.7686, lng: 106.6369,
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 300000,
    priceText: '150K - 300K / vé',
    durationMin: 180,
    moods: ['fun', 'adventure'],
    slots: ['Sáng', 'Chiều'],
    hours: '08:00 – 17:00',
    description: 'Công viên nước và giải trí đa dạng, phù hợp cho ngày vui đôi.',
    rating: 4.1, reviewCount: 3100,
    isPartner: false, active: true,
  },
  {
    name: 'Nến Thơm Sài Gòn',
    category: 'gift',
    area: 'Quận 3',
    address: '102 Nguyễn Đình Chiểu, Quận 3',
    lat: 10.7790, lng: 106.6890,
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 250000,
    priceText: '120K - 280K',
    durationMin: 30,
    moods: ['romantic', 'chill'],
    slots: ['Sáng', 'Chiều', 'Tối'],
    hours: '09:00 – 21:00',
    description: 'Nến thơm handmade với hương liệu tự nhiên. Quà tặng tinh tế cho người yêu.',
    rating: 4.4, reviewCount: 310,
    isPartner: false, active: true,
  },
  {
    name: 'Mộc Mây Handmade',
    category: 'gift',
    area: 'Phú Nhuận',
    address: '32 Phan Đình Phùng, Phú Nhuận',
    lat: 10.7997, lng: 106.6835,
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 250000,
    priceText: '100K - 350K',
    durationMin: 45,
    moods: ['romantic', 'chill'],
    slots: ['Sáng', 'Chiều'],
    hours: '09:00 – 19:00',
    description: 'Xưởng handmade gỗ và mây tre. Tự tay làm quà tặng cho nửa kia.',
    rating: 4.3, reviewCount: 275,
    isPartner: false, active: true,
  },
];

// ============================================================
// SHOP CATEGORIES
// ============================================================
const SHOP_CATEGORIES = [
  { id: 'outfit', name: 'Trang phục Pet', icon: 'checkroom', order: 1, active: true },
  { id: 'accessory', name: 'Phụ kiện Pet', icon: 'auto_awesome', order: 2, active: true },
  { id: 'decoration', name: 'Đồ trang trí', icon: 'chair', order: 3, active: true },
  { id: 'food', name: 'Thức ăn Pet', icon: 'restaurant', order: 4, active: true },
  { id: 'limited', name: 'Giới hạn mùa', icon: 'celebration', order: 5, active: true },
];

// ============================================================
// SHOP ITEMS
// ============================================================
const SHOP_ITEMS = [
  { name: 'Áo trái tim 💕', category: 'outfit', coins: 120, rarity: 'common', icon: 'favorite', description: 'Áo dễ thương với họa tiết trái tim hồng.', active: true },
  { name: 'Mũ phi hành gia', category: 'accessory', coins: 250, rarity: 'rare', icon: 'rocket_launch', description: 'Mũ bảo hiểm phi hành gia tí hon cho pet phiêu lưu.', active: true },
  { name: 'Đèn lồng mùa thu', category: 'decoration', coins: 180, rarity: 'rare', icon: 'lightbulb', description: 'Đèn lồng giấy lung linh trang trí nhà pet.', active: true },
  { name: 'Bộ sưu tập Noel', category: 'limited', coins: 480, rarity: 'limited', icon: 'ac_unit', description: 'Bộ trang phục Noel giới hạn — có áo, mũ và khăn đỏ.', active: true },
  { name: 'Kẹo bông hồng', category: 'food', coins: 90, rarity: 'common', icon: 'icecream', description: 'Kẹo bông ngọt ngào, pet ăn tăng 20 hạnh phúc.', active: true },
  { name: 'Bong bóng trái tim', category: 'accessory', coins: 200, rarity: 'rare', icon: 'bubble_chart', description: 'Bong bóng bay hình trái tim bay lơ lửng bên pet.', active: true },
  { name: 'Nơ bướm hồng', category: 'accessory', coins: 80, rarity: 'common', icon: 'brush', description: 'Nơ bướm xinh xắn đeo trên đầu pet.', active: true },
  { name: 'Bánh kem sinh nhật', category: 'food', coins: 150, rarity: 'rare', icon: 'cake', description: 'Bánh kem đặc biệt — pet ăn tăng 40 hạnh phúc.', active: true },
  { name: 'Áo hoodie dễ thương', category: 'outfit', coins: 160, rarity: 'common', icon: 'checkroom', description: 'Áo hoodie ấm áp với tai thỏ trên mũ.', active: true },
  { name: 'Vương miện vàng', category: 'accessory', coins: 500, rarity: 'limited', icon: 'emoji_events', description: 'Vương miện vàng lấp lánh — chỉ dành cho pet Premium.', active: true },
  { name: 'Cỏ 4 lá may mắn', category: 'decoration', coins: 100, rarity: 'common', icon: 'eco', description: 'Cỏ 4 lá trang trí, mang lại may mắn cho cặp đôi.', active: true },
  { name: 'Set Valentine', category: 'limited', coins: 600, rarity: 'limited', icon: 'favorite_border', description: 'Set giới hạn Valentine — gồm áo, nơ và hiệu ứng tim.', active: true },
  { name: 'Xương gặm', category: 'food', coins: 50, rarity: 'common', icon: 'pets', description: 'Xương gặm giòn tan, pet ăn tăng 15 no bụng.', active: true },
  { name: 'Thảm mây trắng', category: 'decoration', coins: 220, rarity: 'rare', icon: 'cloud', description: 'Thảm mây mềm mại làm nền nhà pet.', active: true },
];

// ============================================================
// GAME QUESTIONS
// ============================================================
const GAME_QUESTIONS = [
  // --- Quiz questions (30+) ---
  { game: 'quiz', question: 'Ngày Valentine là ngày bao nhiêu?', options: ['14/1', '14/2', '14/3', '14/4'], correctIndex: 1, category: 'trivia', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Biểu tượng tình yêu phổ biến nhất là gì?', options: ['Ngôi sao', 'Trái tim', 'Hoa hồng', 'Nhẫn'], correctIndex: 1, category: 'trivia', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Trong tiếng Pháp, "Je t\'aime" nghĩa là gì?', options: ['Tôi nhớ bạn', 'Tôi yêu bạn', 'Tôi thích bạn', 'Xin chào'], correctIndex: 1, category: 'language', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Hoa nào tượng trưng cho tình yêu vĩnh cửu?', options: ['Hoa lan', 'Hoa hồng đỏ', 'Hoa cúc', 'Hoa sen'], correctIndex: 1, category: 'trivia', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Thần tình yêu trong thần thoại Hy Lạp tên gì?', options: ['Zeus', 'Eros', 'Apollo', 'Hermes'], correctIndex: 1, category: 'mythology', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Romeo và Juliet là tác phẩm của ai?', options: ['Charles Dickens', 'William Shakespeare', 'Oscar Wilde', 'Jane Austen'], correctIndex: 1, category: 'literature', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Bộ phim tình cảm "Titanic" ra mắt năm nào?', options: ['1995', '1997', '1999', '2001'], correctIndex: 1, category: 'movie', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Kim cương tượng trưng cho kỷ niệm bao nhiêu năm?', options: ['25 năm', '50 năm', '60 năm', '75 năm'], correctIndex: 2, category: 'trivia', difficulty: 'hard', active: true },
  { game: 'quiz', question: 'Quốc gia nào được mệnh danh là "Thành phố tình yêu"?', options: ['Ý - Rome', 'Pháp - Paris', 'Tây Ban Nha - Barcelona', 'Anh - London'], correctIndex: 1, category: 'geography', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Theo phong thủy, hướng nào tượng trưng cho tình duyên?', options: ['Đông', 'Tây Nam', 'Bắc', 'Đông Nam'], correctIndex: 1, category: 'culture', difficulty: 'hard', active: true },
  { game: 'quiz', question: '"Love is patient, love is kind" trích từ sách nào?', options: ['Kinh Thánh', 'Iliad', 'Quran', 'Bhagavad Gita'], correctIndex: 0, category: 'literature', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Ngày White Day (14/3) bắt nguồn từ đâu?', options: ['Hàn Quốc', 'Nhật Bản', 'Trung Quốc', 'Mỹ'], correctIndex: 1, category: 'culture', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Hormone nào được gọi là "hormone tình yêu"?', options: ['Dopamine', 'Serotonin', 'Oxytocin', 'Adrenaline'], correctIndex: 2, category: 'science', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Màu hoa hồng nào tượng trưng cho tình yêu đầu?', options: ['Đỏ', 'Hồng', 'Trắng', 'Cam'], correctIndex: 1, category: 'trivia', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Bài hát "My Heart Will Go On" do ai thể hiện?', options: ['Adele', 'Whitney Houston', 'Celine Dion', 'Mariah Carey'], correctIndex: 2, category: 'music', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Kỷ niệm năm thứ nhất gọi là đám cưới gì?', options: ['Đám cưới giấy', 'Đám cưới gỗ', 'Đám cưới bạc', 'Đám cưới vàng'], correctIndex: 0, category: 'trivia', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Trong "The Notebook", nhân vật chính tên gì?', options: ['Jack & Rose', 'Noah & Allie', 'Edward & Bella', 'Han & Leia'], correctIndex: 1, category: 'movie', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Cupid mang vũ khí gì?', options: ['Kiếm', 'Cung tên', 'Gậy', 'Lưới'], correctIndex: 1, category: 'mythology', difficulty: 'easy', active: true },
  { game: 'quiz', question: '"Anh yêu em" tiếng Hàn nói thế nào?', options: ['Wo ai ni', 'Saranghae', 'Aishiteru', 'Mahal kita'], correctIndex: 1, category: 'language', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Trái tim con người đập khoảng bao nhiêu lần/ngày?', options: ['50.000', '100.000', '150.000', '200.000'], correctIndex: 1, category: 'science', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Bộ phim hoạt hình tình cảm nổi tiếng của Disney?', options: ['Frozen', 'Tangled', 'Up', 'Beauty and the Beast'], correctIndex: 3, category: 'movie', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Đá quý nào tượng trưng cho tình yêu chung thủy?', options: ['Ruby', 'Sapphire', 'Emerald', 'Kim cương'], correctIndex: 3, category: 'trivia', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Ngày lễ Qixi (Thất Tịch) rơi vào tháng mấy âm lịch?', options: ['Tháng 5', 'Tháng 7', 'Tháng 8', 'Tháng 9'], correctIndex: 1, category: 'culture', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Bài thơ tình nổi tiếng nhất Việt Nam là?', options: ['Đây thôn Vĩ Dạ', 'Tôi yêu em', 'Hai sắc hoa Ti-gôn', 'Sóng'], correctIndex: 3, category: 'literature', difficulty: 'medium', active: true },
  { game: 'quiz', question: 'Nhẫn đính hôn thường đeo ở ngón nào?', options: ['Ngón trỏ', 'Ngón giữa', 'Ngón áp út', 'Ngón út'], correctIndex: 2, category: 'trivia', difficulty: 'easy', active: true },
  { game: 'quiz', question: '"Wo ai ni" là "I love you" bằng tiếng nào?', options: ['Nhật', 'Hàn', 'Trung', 'Thái'], correctIndex: 2, category: 'language', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Tác giả "Nhỏ ơi" là ai?', options: ['Nguyễn Nhật Ánh', 'Anh Khang', 'Hamlet Trương', 'Iris Cao'], correctIndex: 2, category: 'literature', difficulty: 'hard', active: true },
  { game: 'quiz', question: 'Loài chim nào tượng trưng cho tình yêu đôi lứa?', options: ['Chim sẻ', 'Chim bồ câu', 'Chim thiên nga', 'Chim ưng'], correctIndex: 2, category: 'trivia', difficulty: 'easy', active: true },
  { game: 'quiz', question: 'Phim "La La Land" giành bao nhiêu giải Oscar?', options: ['4', '6', '8', '10'], correctIndex: 1, category: 'movie', difficulty: 'hard', active: true },
  { game: 'quiz', question: 'Tháng nào có nhiều đám cưới nhất ở Việt Nam?', options: ['Tháng 1', 'Tháng 6', 'Tháng 10', 'Tháng 12'], correctIndex: 3, category: 'culture', difficulty: 'medium', active: true },

  // --- Mind-read prompts (20) ---
  { game: 'mindread', question: 'Món ăn yêu thích nhất của người kia là gì?', options: [], correctIndex: -1, category: 'food', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Bộ phim mà người kia muốn xem lại nhiều nhất?', options: [], correctIndex: -1, category: 'entertainment', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Điều gì khiến người kia cười nhiều nhất?', options: [], correctIndex: -1, category: 'personality', difficulty: 'medium', active: true },
  { game: 'mindread', question: 'Nếu được du lịch, người kia sẽ chọn biển hay núi?', options: [], correctIndex: -1, category: 'travel', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Màu sắc yêu thích của người kia?', options: [], correctIndex: -1, category: 'personality', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Bài hát nào gắn liền với kỷ niệm của hai bạn?', options: [], correctIndex: -1, category: 'memory', difficulty: 'medium', active: true },
  { game: 'mindread', question: 'Người kia sợ nhất điều gì?', options: [], correctIndex: -1, category: 'personality', difficulty: 'medium', active: true },
  { game: 'mindread', question: 'Buổi hẹn lý tưởng của người kia là gì?', options: [], correctIndex: -1, category: 'romance', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Nếu thắng xổ số, người kia sẽ làm gì đầu tiên?', options: [], correctIndex: -1, category: 'dream', difficulty: 'medium', active: true },
  { game: 'mindread', question: 'Siêu năng lực nào người kia muốn có nhất?', options: [], correctIndex: -1, category: 'fun', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Thói quen kỳ lạ nhất của người kia là gì?', options: [], correctIndex: -1, category: 'personality', difficulty: 'hard', active: true },
  { game: 'mindread', question: 'Người kia thích được tặng quà bất ngờ hay được biết trước?', options: [], correctIndex: -1, category: 'romance', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Kỷ niệm đáng nhớ nhất của hai bạn là gì?', options: [], correctIndex: -1, category: 'memory', difficulty: 'medium', active: true },
  { game: 'mindread', question: 'Đồ uống yêu thích của người kia khi trời lạnh?', options: [], correctIndex: -1, category: 'food', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Nếu là một loài động vật, người kia sẽ là con gì?', options: [], correctIndex: -1, category: 'fun', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Người kia mơ ước sống ở thành phố hay nông thôn?', options: [], correctIndex: -1, category: 'dream', difficulty: 'medium', active: true },
  { game: 'mindread', question: 'Điều gì khiến người kia stress nhất?', options: [], correctIndex: -1, category: 'personality', difficulty: 'hard', active: true },
  { game: 'mindread', question: 'Ngày trong tuần người kia thích nhất?', options: [], correctIndex: -1, category: 'personality', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Ca sĩ/nhóm nhạc yêu thích của người kia?', options: [], correctIndex: -1, category: 'entertainment', difficulty: 'easy', active: true },
  { game: 'mindread', question: 'Lần đầu gặp nhau ở đâu? Nhớ không? 💕', options: [], correctIndex: -1, category: 'memory', difficulty: 'medium', active: true },

  // --- Daily challenges (15) ---
  { game: 'daily_challenge', question: 'Gửi cho người yêu một tin nhắn ngọt ngào ngay bây giờ 💕', options: [], correctIndex: -1, category: 'action', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Kể cho nhau nghe 3 điều bạn yêu ở người kia', options: [], correctIndex: -1, category: 'share', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Cùng nhau nấu một bữa ăn đặc biệt hôm nay', options: [], correctIndex: -1, category: 'action', difficulty: 'medium', active: true },
  { game: 'daily_challenge', question: 'Chụp một tấm ảnh selfie cùng nhau và lưu vào Khoảnh khắc', options: [], correctIndex: -1, category: 'action', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Viết một lá thư tay ngắn cho người yêu', options: [], correctIndex: -1, category: 'creative', difficulty: 'medium', active: true },
  { game: 'daily_challenge', question: 'Ôm người yêu ít nhất 30 giây liên tục 🤗', options: [], correctIndex: -1, category: 'action', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Cùng xem lại album ảnh kỷ niệm của hai bạn', options: [], correctIndex: -1, category: 'memory', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Đặt bàn ở nhà hàng yêu thích và đi ăn tối', options: [], correctIndex: -1, category: 'action', difficulty: 'hard', active: true },
  { game: 'daily_challenge', question: 'Chia sẻ một bí mật mà bạn chưa từng kể', options: [], correctIndex: -1, category: 'share', difficulty: 'hard', active: true },
  { game: 'daily_challenge', question: 'Nghe lại bài hát kỷ niệm của hai bạn cùng nhau', options: [], correctIndex: -1, category: 'memory', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Massage vai cho người yêu 10 phút', options: [], correctIndex: -1, category: 'action', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Lên kế hoạch cho chuyến du lịch tiếp theo', options: [], correctIndex: -1, category: 'creative', difficulty: 'medium', active: true },
  { game: 'daily_challenge', question: 'Gửi một bức ảnh hài hước cho người yêu', options: [], correctIndex: -1, category: 'fun', difficulty: 'easy', active: true },
  { game: 'daily_challenge', question: 'Nói "Anh/Em yêu em/anh" bằng 3 ngôn ngữ khác nhau', options: [], correctIndex: -1, category: 'fun', difficulty: 'medium', active: true },
  { game: 'daily_challenge', question: 'Cùng đi dạo 20 phút và không dùng điện thoại', options: [], correctIndex: -1, category: 'action', difficulty: 'medium', active: true },
];

// ============================================================
// SEED FUNCTIONS
// ============================================================

async function seedCollection(collectionName, data, idFn) {
  console.log(`\n📦 Seeding ${collectionName} (${data.length} documents)...`);
  const batch = db.batch();
  let count = 0;

  for (const item of data) {
    const docId = idFn ? idFn(item) : slug(item.name || item.id || item.question);
    const ref = db.collection(collectionName).doc(docId);
    batch.set(ref, {
      ...item,
      _seedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    count++;
  }

  await batch.commit();
  console.log(`   ✅ ${count} documents seeded to '${collectionName}'`);
}

async function main() {
  console.log('🚀 MATE Firestore Seed Script');
  console.log(`   Project: ${process.env.FIREBASE_PROJECT_ID || 'mateapp-8d44d'}`);
  if (onlyCollections) {
    console.log(`   Only: ${onlyCollections.join(', ')}`);
  }

  try {
    if (shouldSeed('places')) {
      await seedCollection('places', PLACES, (p) => slug(p.name));
    }

    if (shouldSeed('shopCategories')) {
      await seedCollection('shopCategories', SHOP_CATEGORIES, (c) => c.id);
    }

    if (shouldSeed('shopItems')) {
      await seedCollection('shopItems', SHOP_ITEMS, (i) => slug(i.name));
    }

    if (shouldSeed('gameQuestions')) {
      await seedCollection(
        'gameQuestions',
        GAME_QUESTIONS,
        (q) => slug(`${q.game}-${q.question.substring(0, 40)}`)
      );
    }

    console.log('\n🎉 Seed hoàn tất!\n');
  } catch (err) {
    console.error('\n❌ Lỗi:', err.message);
    process.exit(1);
  }
}

main();
