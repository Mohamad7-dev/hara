/* ============================================================
   حارة — تطبيق السوق المحلي
   نسخة احترافية v3
   ============================================================ */
const CHK_SVG = '<svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg>';
const APP = {
  currentUser: null, currentPage: 'home', cart: [], products: [], orders: [], users: [],
  services: [], jobs: [], requests: [], saved: [], chats: [],
  selectedCategory: 'الكل',
  searchState: { q: '', cat: 'الكل', condition: 'الكل', city: '', sort: 'latest' },
  _detailId: null, _viewerIdx: 0, _chatName: null, locCity: '',

  /* ================= HELPERS ================= */
  esc(s) { return (s || '').replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m])); },

  fmt(n) { return `${n ?? 0} ₪`; },

  timeAgo(iso) {
    const d = new Date(iso), diff = (Date.now() - d.getTime()) / 1000;
    if (diff < 60) return 'الآن';
    if (diff < 3600) return `منذ ${Math.floor(diff / 60)} د`;
    if (diff < 86400) return `منذ ${Math.floor(diff / 3600)} س`;
    if (diff < 604800) return `منذ ${Math.floor(diff / 86400)} يوم`;
    return d.toLocaleDateString('ar-EG', { day: 'numeric', month: 'short' });
  },

  stars(r) { const v = Math.round(r || 0); return '★'.repeat(v) + '☆'.repeat(5 - v); },

  catStyle(cat) {
    const map = {
      'طعام': { icon: 'ph ph-duotone ph-bowl-food', g1: '#B85C38', g2: '#96411F', g3: '#CE8059' },
      'إلكترونيات': { icon: 'ph ph-duotone ph-devices', g1: '#8A6D46', g2: '#6C5130', g3: '#A8895F' },
      'هواتف': { icon: 'ph ph-duotone ph-device-mobile', g1: '#6E8A5E', g2: '#516C43', g3: '#8CA87C' },
      'لابتوبات': { icon: 'ph ph-duotone ph-laptop', g1: '#7A6A5A', g2: '#5E4F41', g3: '#95846F' },
      'سيارات': { icon: 'ph ph-duotone ph-car', g1: '#6E5B4B', g2: '#544236', g3: '#8B7766' },
      'عقارات': { icon: 'ph ph-duotone ph-buildings', g1: '#9C7B50', g2: '#7C5E39', g3: '#B5976C' },
      'أثاث': { icon: 'ph ph-duotone ph-couch', g1: '#8A5A34', g2: '#6C4223', g3: '#A8794F' },
      'ملابس': { icon: 'ph ph-duotone ph-t-shirt', g1: '#A85E6B', g2: '#86404C', g3: '#C27D89' },
      'ألعاب': { icon: 'ph ph-duotone ph-game-controller', g1: '#B98A35', g2: '#966A20', g3: '#D0A757' },
      'أجهزة منزلية': { icon: 'ph ph-duotone ph-oven', g1: '#7E6A84', g2: '#604E66', g3: '#9A86A0' },
      'كتب': { icon: 'ph ph-duotone ph-book-open', g1: '#9C6E4B', g2: '#7C5333', g3: '#B78D6C' },
      'رياضة': { icon: 'ph ph-duotone ph-basketball', g1: '#66834F', g2: '#4C6838', g3: '#86A36D' },
      'هدايا': { icon: 'ph ph-duotone ph-gift', g1: '#A9823C', g2: '#8F6B2C', g3: '#C29B55' },
      'منزل': { icon: 'ph ph-duotone ph-house', g1: '#A97B45', g2: '#875E2E', g3: '#C09563' },
      'حرف يدوية': { icon: 'ph ph-duotone ph-palette', g1: '#9C6286', g2: '#7C4666', g3: '#B77FA4' },
      'خدمات': { icon: 'ph ph-duotone ph-wrench', g1: '#6B4E33', g2: '#3B2A1D', g3: '#8A6844' },
    };
    return map[cat] || { icon: 'ph ph-duotone ph-package', g1: '#7A6A54', g2: '#5E4F41', g3: '#95846F' };
  },

  productImages(p) {
    const arr = p.images || [];
    return arr.map(u => ({ bg: 'transparent', img: u }));
  },

  imgPh(cat, seed = 0) {
    const s = seed % 3;
    const g1 = '#F3EDE2', g2 = '#ECE4D4', g3 = '#DFD6C4';
    const ic = '#C9BFA9';
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600">
      <defs>
        <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="${g1}"/><stop offset="1" stop-color="${g2}"/>
        </linearGradient>
      </defs>
      <rect width="600" height="600" fill="url(#g)"/>
      <circle cx="${[486,110,300][s]}" cy="${[92,88,476][s]}" r="${[196,168,214][s]}" fill="${g3}" opacity="0.55"/>
      <circle cx="${[108,474,138][s]}" cy="${[506,474,118][s]}" r="${[172,204,152][s]}" fill="${g3}" opacity="0.65"/>
      <g transform="rotate(${[28,44,16][s]} 300 300)">
        <circle cx="300" cy="300" r="150" fill="none" stroke="${ic}" stroke-opacity="0.35" stroke-width="4"/>
        <circle cx="300" cy="300" r="112" fill="${ic}" fill-opacity="0.10"/>
        <circle cx="300" cy="300" r="74" fill="none" stroke="${ic}" stroke-opacity="0.30" stroke-width="2"/>
      </g>
      <rect x="40" y="520" width="186" height="10" rx="5" fill="${ic}" opacity="0.40"/>
      <rect x="40" y="544" width="124" height="8" rx="4" fill="${ic}" opacity="0.30"/>
      <g opacity="0.45">
        <path d="M262 214 l18 -20 h40 l18 20 z" fill="none" stroke="${ic}" stroke-width="12" stroke-linejoin="round"/>
        <rect x="196" y="214" width="208" height="152" rx="30" fill="none" stroke="${ic}" stroke-width="13"/>
        <circle cx="300" cy="290" r="48" fill="none" stroke="${ic}" stroke-width="13"/>
        <circle cx="300" cy="290" r="19" fill="${ic}"/>
      </g>
    </svg>`;
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  },

  demoImg(kind) {
    const imgs = {
      oil: '<rect width="600" height="600" fill="#F4EDDD"/><ellipse cx="300" cy="512" rx="180" ry="24" fill="#E7DEC8"/><rect x="268" y="92" width="64" height="40" rx="8" fill="#A9823C"/><path d="M244 132 h112 v250 a16 16 0 0 1 -16 16 h-80 a16 16 0 0 1 -16 -16 z" fill="#6E8B3A"/><path d="M256 170 c4 90 -6 150 48 200" stroke="#8FA75F" stroke-width="26" stroke-linecap="round" fill="none" opacity="0.4"/><text x="300" y="452" font-family="Arial" font-size="40" font-weight="bold" fill="#F4EDDD" text-anchor="middle">زيت زيتون</text>',
      laptop: '<rect width="600" height="600" fill="#F4EDDD"/><ellipse cx="300" cy="512" rx="190" ry="22" fill="#E7DEC8"/><rect x="150" y="150" width="300" height="214" rx="14" fill="#3B2A1D"/><rect x="168" y="170" width="264" height="168" rx="8" fill="#8FB0D8"/><rect x="168" y="170" width="264" height="44" fill="#6E93BD" opacity="0.75"/><rect x="128" y="382" width="344" height="18" rx="9" fill="#C9A86A"/><rect x="238" y="400" width="124" height="8" rx="4" fill="#A9823C"/>'
    };
    const inner = imgs[kind] || imgs.oil;
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600">${inner}</svg>`);
  },

  grad(g) { return `linear-gradient(135deg, ${g.g1}, ${g.g2})`; },

  /* ================= INIT ================= */
  init() {
    this.loadData();
    const h = location.hash.replace('#', '');
    if (h) this.currentPage = h;
    window.addEventListener('hashchange', () => this.handleHashChange());
    this.bindGlobal();
    this.render();
  },

  handleHashChange() {
    const h = location.hash.replace('#', '');
    if (!h || h === this.currentPage) return;
    this.navigate(h);
  },

  loadData() {
    try {
      this.users = JSON.parse(localStorage.getItem('hara_users')) || [];
      this.products = JSON.parse(localStorage.getItem('hara_products')) || [];
      this.orders = JSON.parse(localStorage.getItem('hara_orders')) || [];
      this.cart = JSON.parse(localStorage.getItem('hara_cart')) || [];
      this.services = JSON.parse(localStorage.getItem('hara_services')) || [];
      this.jobs = JSON.parse(localStorage.getItem('hara_jobs')) || [];
      this.requests = JSON.parse(localStorage.getItem('hara_requests')) || [];
      this.saved = JSON.parse(localStorage.getItem('hara_saved')) || [];
      this.chats = JSON.parse(localStorage.getItem('hara_chats')) || [];
      const s = localStorage.getItem('hara_current_user');
      if (s) this.currentUser = JSON.parse(s);
    } catch (e) {}
    this.users.forEach(u => { if (typeof u.balance !== 'number') u.balance = 500; });
    if (this.currentUser && typeof this.currentUser.balance !== 'number') this.currentUser.balance = 500;
    if (!this.currentUser) {
      this.currentUser = { id: 'guest', name: 'زائر', email: 'guest@hara.ps', phone: '0599000000', address: 'رام الله - البيرة', userType: 'regular', deliveryAreas: [], deliveryFee: 0, vehicleType: '', verified: false, joinedAt: new Date().toISOString(), bio: '', balance: 500 };
      localStorage.setItem('hara_current_user', JSON.stringify(this.currentUser));
    }
    if (this.products.length === 0) this.seedData();
    if (this.services.length === 0 || this.jobs.length === 0 || this.requests.length === 0) this.seedSections();
    const params = new URLSearchParams(location.search);
    if (params.get('user')) {
      const u = this.users.find(x => x.email === params.get('user') + '@hara.ps');
      if (u) { this.currentUser = u; this.isPreviewUser = true; }
    }
    if (params.get('demo')) this.seedDemoData();
    this.seedDemoChats();
    this.locCity = localStorage.getItem('hara_loc');
    if (this.locCity === null) this.locCity = this.userCity(this.currentUser?.address);
  },

  seedData() {
    const now = Date.now(), day = 86400000;
    this.users = [
      { id: 'admin1', name: 'الإدارة', email: 'admin@hara.ps', phone: '0599000000', password: '123456', address: 'رام الله', userType: 'admin', verified: true, joinedAt: new Date(now - 400 * day).toISOString(), bio: 'حساب إدارة منصة حارة', balance: 0 },
      { id: 'user1', name: 'محمد أبو أحمد', email: 'user1@hara.ps', phone: '0599000001', password: '123456', address: 'الخليل - عسكر', userType: 'regular', verified: true, joinedAt: new Date(now - 210 * day).toISOString(), bio: 'أبيع منتجات بلدية وطبيعية من مزرعة العائلة. أهلاً بالجميع 🌿', balance: 650 },
      { id: 'user2', name: 'سامي عوض', email: 'user2@hara.ps', phone: '0599000003', password: '123456', address: 'نابلس - رفيديا', userType: 'regular', verified: false, joinedAt: new Date(now - 60 * day).toISOString(), bio: 'أهلاً بكم، موجود دائماً لخدمتكم.', balance: 220 },
      { id: 'delivery1', name: 'خالد حسن', email: 'delivery@hara.ps', phone: '0599000002', password: '123456', address: 'رام الله - البيرة', userType: 'delivery', deliveryAreas: ['البيرة', 'الماصيون'], deliveryFee: 7, vehicleType: 'دراجة', verified: true, available: true, workHours: '8 ص - 8 م', rating: 4.7, ratingCount: 41, joinedAt: new Date(now - 150 * day).toISOString(), bio: 'موصل معتمد — توصيل سريع وآمن داخل رام الله والبيرة.', balance: 90 },
    ];
    this.products = [
      { id: 'p1', sellerId: 'user1', sellerName: 'محمد أبو أحمد', title: 'زيت زيتون بلدي', description: 'زيت زيتون عذراء طبيعي 100% معصور على البارد من مزرعة العائلة. يمتاز بطعمه الأصيل ولونه الذهبي. متوفر بجرّة 1 لتر و 4 لتر.', price: 35, category: 'طعام', images: [this.demoImg('oil')], stock: 50, isAvailable: true, rating: 4.8, ratingCount: 23, city: 'الخليل', condition: 'جديد', views: 120, saves: 34, featured: true, createdAt: new Date(now - 2 * day).toISOString() },
      { id: 'p2', sellerId: 'user1', sellerName: 'محمد أبو أحمد', title: 'تمر مجهول فاخر', description: 'تمر مجهول عضوي فاخر، وزن 1 كجم، منتج طبيعي بدون مواد حافظة. مثالي للضيافة والحلويات.', price: 28, category: 'طعام', images: [], stock: 30, isAvailable: true, rating: 4.6, ratingCount: 15, city: 'جنين', condition: 'جديد', views: 90, saves: 18, featured: false, createdAt: new Date(now - 1 * day).toISOString() },
      { id: 'p3', sellerId: 'user1', sellerName: 'محمد أبو أحمد', title: 'عصير طبيعي', description: 'عصير برتقال طبيعي طازج بدون سكر مضاف، معصور يومياً.', price: 8, category: 'طعام', images: [], stock: 100, isAvailable: true, rating: 4.5, ratingCount: 8, city: 'نابلس', condition: 'جديد', views: 60, saves: 9, featured: false, createdAt: new Date(now - 5 * 3600000).toISOString() },
      { id: 'p4', sellerId: 'user2', sellerName: 'سامي عوض', title: 'شنطة يدوية', description: 'شنطة يد مصنوعة يدوياً من القماش الفلسطيني المطرّز، تصميم عصري ومتين.', price: 45, category: 'هدايا', images: [], stock: 10, isAvailable: true, rating: 5.0, ratingCount: 5, city: 'رام الله', condition: 'مستعمل', views: 150, saves: 27, featured: false, createdAt: new Date(now - 3 * day).toISOString() },
      { id: 'p5', sellerId: 'user2', sellerName: 'سامي عوض', title: 'لابتوب مستعمل', description: 'لابتوب بحالة ممتازة، معالج i5، رام 8 جيجا، شاشة 15 بوصة. البطارية تدوم 5 ساعات. مع الشاحن الأصلي.', price: 850, category: 'لابتوبات', images: [this.demoImg('laptop')], stock: 1, isAvailable: true, rating: 4.3, ratingCount: 11, city: 'نابلس - رفيديا', condition: 'مستعمل', views: 340, saves: 52, featured: true, createdAt: new Date(now - 6 * 3600000).toISOString() },
      { id: 'p6', sellerId: 'user1', sellerName: 'محمد أبو أحمد', title: 'هاتف سامسونج', description: 'هاتف سامسونج شبه جديد، بطارية ممتازة، مع الشاحن والعلبة. يصلح لجميع الشبكات.', price: 420, category: 'هواتف', images: [], stock: 1, isAvailable: true, rating: 4.7, ratingCount: 18, city: 'الخليل', condition: 'مستعمل', views: 260, saves: 31, featured: false, createdAt: new Date(now - 8 * 3600000).toISOString() },
    ];
    this.orders = []; this.saveAll();
  },

  seedSections() {
    const now = Date.now(), day = 86400000;
    if (this.services.length === 0) {
      this.services = [
        { id: 'sv1', userId: 'user2', providerName: 'سامي عوض', title: 'تصميم شعارات وهوية بصرية', category: 'مصمم', description: 'تصميم شعارات وهويات بصرية احترافية للشركات والمشاريع الصغيرة. خبرة 5 سنوات مع أكثر من 40 مشروع منجز.', price: 150, areas: ['رام الله', 'البيرة'], workHours: '9 ص - 6 م', rating: 4.9, ratingCount: 32, completedJobs: 41, verified: false, createdAt: new Date(now - 2 * day).toISOString() },
        { id: 'sv2', userId: 'delivery1', providerName: 'خالد حسن', title: 'تصليح كهرباء منزلية', category: 'كهربائي', description: 'تركيب وتمديد كهرباء، تصليح أعطال، تركيب إنارة وأجهزة. عمل نظيف بأسعار منافسة.', price: 60, areas: ['الخليل', 'عسكر', 'رفيديا'], workHours: '8 ص - 8 م', rating: 4.7, ratingCount: 24, completedJobs: 95, verified: true, createdAt: new Date(now - 4 * day).toISOString() },
        { id: 'sv3', userId: 'user1', providerName: 'محمد أبو أحمد', title: 'تدريس رياضيات لجميع المراحل', category: 'مدرس', description: 'تدريس الرياضيات للمراحل الأساسية والثانوية، تحضير للامتحانات، متابعة فردية.', price: 40, areas: ['نابلس'], workHours: '4 م - 9 م', rating: 4.8, ratingCount: 19, completedJobs: 27, verified: true, createdAt: new Date(now - 1 * day).toISOString() },
      ];
    }
    if (this.jobs.length === 0) {
      this.jobs = [
        { id: 'jb1', companyName: 'شركة أفق للتكنولوجيا', title: 'مطور فلاتر', type: 'دوام كامل', salary: '1500 - 2000$', city: 'رام الله', experience: 'سنتين - 4 سنوات', skills: ['Flutter', 'Dart', 'Firebase'], description: 'مطلوب مطور فلاتر للانضمام لفريق تطوير تطبيقات جوال. خبرة في نشر تطبيقات على المتاجر.', applicants: [], createdAt: new Date(now - 5 * 3600000).toISOString() },
        { id: 'jb2', companyName: 'مقهى الزيتون', title: 'باريستا', type: 'دوام جزئي', salary: '800$', city: 'نابلس - رفيديا', experience: 'بدون خبرة', skills: ['خدمة عملاء'], description: 'مطلوب باريستا لشفت مسائي. التدريب متوفر.', applicants: [], createdAt: new Date(now - 1 * day).toISOString() },
        { id: 'jb3', companyName: 'فريق حر', title: 'كاتب محتوى عن بعد', type: 'عن بعد', salary: '500 - 800$', city: 'عن بعد', experience: 'سنة', skills: ['كتابة', 'سوشيال ميديا'], description: 'مطلوب كاتب محتوى بالعربية للمواقع والسوشيال ميديا. عمل مرن عن بعد.', applicants: [], createdAt: new Date(now - 2 * day).toISOString() },
      ];
    }
    if (this.requests.length === 0) {
      this.requests = [
        { id: 'rq1', userId: 'user1', userName: 'محمد أبو أحمد', title: 'أبحث عن لابتوب مستعمل', category: 'لابتوبات', description: 'أبحث عن لابتوب مستعمل بحالة جيدة لاستخدامات المكتب، الميزانية حتى 800 شيكل.', status: 'open', offers: [], createdAt: new Date(now - 3 * 3600000).toISOString() },
        { id: 'rq2', userId: 'user2', userName: 'سامي عوض', title: 'أحتاج سباك اليوم', category: 'خدمات منزلية', description: 'تسريب في الحمام، أحتاج سباك اليوم قبل المساء. في منطقة رفيديا.', status: 'negotiating', offers: [{ id: 'of1', userId: 'delivery1', offererName: 'خالد حسن', price: 80, message: 'أستطيع الحضور خلال ساعة', createdAt: new Date(now - 3600000).toISOString() }], createdAt: new Date(now - 6 * 3600000).toISOString() },
        { id: 'rq3', userId: 'delivery1', userName: 'خالد حسن', title: 'أريد مصمم شعار', category: 'خدمات', description: 'محتاج شعار لمشروع توصيل جديد بأسلوب حديث. الميزانية 300 شيكل.', status: 'done', offers: [{ id: 'of2', userId: 'user1', offererName: 'محمد أبو أحمد', price: 300, message: 'أستطيع تنفيذه خلال أسبوع مع 3 مسودات أولية.', createdAt: new Date(now - 2 * day).toISOString() }], createdAt: new Date(now - 4 * day).toISOString() },
      ];
    }
    this.saveAll();
  },

  seedDemoData() {
    if (this.cart.length === 0) this.cart = [{ productId: 'p1', quantity: 2 }, { productId: 'p3', quantity: 1 }];
    if (this.orders.length === 0) {
      const now = Date.now();
      this.orders = [
        { id: 'ORD111111', buyerId: 'demo1', buyerName: 'سامي عوض', buyerPhone: '0599555333', buyerAddress: 'رام الله - البيرة', status: 'accepted', items: [{ productId: 'p1', productTitle: 'زيت زيتون بلدي', price: 35, quantity: 1 }, { productId: 'p3', productTitle: 'عصير طبيعي', price: 8, quantity: 2 }], subtotal: 51, deliveryFee: 5, total: 56, paymentMethod: 'كاش', paymentStatus: 'pending', createdAt: new Date(now - 3600000).toISOString(), deliveredAt: null, deliveryPersonId: 'delivery1', deliveryPersonName: 'خالد حسن' },
        { id: 'ORD222222', buyerId: 'guest', buyerName: 'زائر', buyerPhone: '0599000000', buyerAddress: 'نابلس', status: 'delivered', items: [{ productId: 'p4', productTitle: 'شنطة يدوية', price: 45, quantity: 1 }], subtotal: 45, deliveryFee: 5, total: 50, paymentMethod: 'محفظة', paymentStatus: 'paid', createdAt: new Date(now - 86400000).toISOString(), deliveredAt: new Date(now - 72000000).toISOString() },
      ];
    }
    this.saveAll();
  },

  seedDemoChats() {
    if (this.chats.length > 0) return;
    const now = Date.now();
    this.chats = [
      { id: 'c1', name: 'سامي عوض', role: 'بائع', icon: 'ph-storefront', unread: 2, messages: [
        { from: 'me', text: 'أهلاً سامي، هل الشنطة اليدوية متوفرة؟', time: new Date(now - 54000000).toISOString() },
        { from: 'them', text: 'أهلاً بك! نعم متوفرة، باقي نسختين.', time: new Date(now - 52500000).toISOString() },
        { from: 'them', text: 'أستطيع التنازل لـ 40 شيكل إذا بتأخذ اليوم.', time: new Date(now - 51000000).toISOString() },
      ]},
      { id: 'c2', name: 'خالد حسن', role: 'موصل', icon: 'ph-moped', unread: 0, messages: [
        { from: 'me', text: 'كم الوقت المتوقع للتوصيل؟', time: new Date(now - 86400000).toISOString() },
        { from: 'them', text: 'حوالي نصف ساعة، معك وصل الاستلام.', time: new Date(now - 85800000).toISOString() },
      ]},
    ];
    this.saveAll();
  },

  saveAll() {
    const keys = ['users', 'products', 'orders', 'cart', 'services', 'jobs', 'requests', 'saved', 'chats'];
    keys.forEach(k => localStorage.setItem('hara_' + k, JSON.stringify(this[k])));
    if (this.isPreviewUser) return;
    if (this.currentUser) localStorage.setItem('hara_current_user', JSON.stringify(this.currentUser));
    else localStorage.removeItem('hara_current_user');
  },

  /* ================= NAV / RENDER SHELL ================= */
  navigate(p) {
    this.currentPage = p; window.scrollTo(0, 0);
    if (location.hash !== '#' + p) location.hash = p;
    this.render();
  },

  render() {
    const app = document.getElementById('app');
    if (this.currentPage === 'login' || this.currentPage === 'register') { this.renderAuth(app); return; }
    const tabHide = ['cart', 'checkout', 'order-success', 'product-detail', 'chat'].includes(this.currentPage);
    const noHeader = ['product-detail', 'chat'].includes(this.currentPage);
    const bellCount = this.bellCount();
    const unreadMsgs = this.unreadChats();
    app.innerHTML = `
      ${noHeader ? '' : `<div class="header"><div class="header-inner">
        <div class="header-loc">
          <button class="loc-select ripple-host" onclick="APP.toggleLocMenu()">
            <img src="images/logo.png" class="loc-logo" alt="حارة">
            <span class="loc-name">${this.esc(this.locCity || 'منطقتك')}</span>
            <i class="ph ph-duotone ph-caret-down loc-caret"></i>
          </button>
        </div>
        <div class="header-actions">
          <button class="ripple-host" onclick="APP.navigate('notifications')" title="الإشعارات">
            <i class="ph ph-duotone ph-bell"></i>
            ${bellCount ? `<span class="badge bell-badge">${bellCount > 9 ? '9+' : bellCount}</span>` : ''}
          </button>
          <button class="ripple-host" onclick="APP.navigate('cart')">
            <i class="ph ph-duotone ph-shopping-cart"></i>
            <span class="badge cart-badge">${this.getCartCount()}</span>
          </button>
        </div>
      </div>
      <div class="loc-menu" id="loc-menu">
        <div class="loc-menu-head"><i class="ph ph-duotone ph-map-pin"></i> اختر منطقتك</div>
        <div class="loc-menu-list">
          ${['الكل', ...this.AREAS].map(a => {
            const v = a === 'الكل' ? '' : a;
            return `<button class="loc-opt ${this.locCity === v ? 'on' : ''}" onclick="APP.setLoc('${a}')">
              <i class="ph ph-duotone ph-map-pin"></i><span>${a}</span>
              ${this.locCity === v ? '<svg class="chk loc-on" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg>' : ''}
            </button>`;
          }).join('')}
        </div>
      </div></div>`}
      <div id="page-content"></div>
      ${noHeader ? '' : `<div class="tabbar" id="tabbar" style="display:${tabHide ? 'none' : 'flex'}">
        ${this.tabItems().slice(0, 2).map(t => `
          <button class="ripple-host ${this.currentPage === t.page ? 'active' : ''}" onclick="APP.navigate('${t.page}')">
            <i class="ph ph-duotone ${t.icon}"></i><span>${t.label}</span>
            ${t.page === 'messages' && unreadMsgs > 0 ? `<span class="tab-badge">${unreadMsgs > 9 ? '9+' : unreadMsgs}</span>` : ''}
          </button>`).join('')}
        <button class="tab-fab ripple-host" onclick="APP.navigate('add-product')"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v14M5 12h14"/></svg></button>
        ${this.tabItems().slice(2).map(t => `
          <button class="ripple-host ${this.currentPage === t.page ? 'active' : ''}" onclick="APP.navigate('${t.page}')">
            <i class="ph ph-duotone ${t.icon}"></i><span>${t.label}</span>
            ${t.page === 'messages' && unreadMsgs > 0 ? `<span class="tab-badge">${unreadMsgs > 9 ? '9+' : unreadMsgs}</span>` : ''}
          </button>`).join('')}
      </div>`}
      <div class="bottom-bar" id="bottom-bar" style="display:none"></div>
    `;
    this.updateBadge();
    const camel = this.currentPage.split('-').map(s => s.charAt(0).toUpperCase() + s.slice(1)).join('');
    const f = this['render' + camel];
    if (f) f.call(this);
    if (this.currentPage === 'home') this.ripples('.hero-banner');
  },

  tabItems() {
    return [
      { page: 'home', icon: 'ph-house', label: 'الرئيسية' },
      { page: 'saved', icon: 'ph-bookmark', label: 'المفضلة' },
      { page: 'messages', icon: 'ph-chats-circle', label: 'الرسائل' },
      { page: 'profile', icon: 'ph-user-circle', label: 'حسابي' },
    ];
  },

  /* ================= GLOBAL: RIPPLE + SUGGEST CLOSE ================= */
  bindGlobal() {
    document.addEventListener('click', (e) => {
      const t = e.target.closest('.btn, .hero-chip, .category-chip, .cat-item, .sort-chip, .tabbar button, .location-chip, .loc-select');
      if (t) this.spawnRipple(e, t);
      if (!e.target.closest('.search-box')) { document.querySelectorAll('.suggest').forEach(s => s.remove()); }
      const lm = document.getElementById('loc-menu');
      if (lm && lm.style.display === 'flex' && !e.target.closest('#loc-menu') && !e.target.closest('.loc-select')) lm.style.display = 'none';
    });
  },
  spawnRipple(e, el) {
    const r = el.getBoundingClientRect(), d = Math.max(r.width, r.height);
    const ink = document.createElement('span');
    ink.className = 'ripple-ink';
    ink.style.width = ink.style.height = d + 'px';
    ink.style.left = (e.clientX - r.left - d / 2) + 'px';
    ink.style.top = (e.clientY - r.top - d / 2) + 'px';
    el.appendChild(ink);
    setTimeout(() => ink.remove(), 650);
  },
  ripples(sel) { document.querySelectorAll(sel).forEach(el => el.classList.add('ripple-host')); },

  /* ================= LOCATION ================= */
  AREAS: ['رام الله', 'البيرة', 'القدس', 'نابلس', 'الخليل', 'جنين', 'طولكرم', 'قلقيلية', 'سلفيت', 'بيت لحم', 'أريحا'],

  toggleLocMenu() {
    const m = document.getElementById('loc-menu');
    if (m) m.style.display = m.style.display === 'flex' ? 'none' : 'flex';
  },
  setLoc(a) {
    this.locCity = a === 'الكل' ? '' : a;
    localStorage.setItem('hara_loc', this.locCity);
    const m = document.getElementById('loc-menu');
    if (m) m.style.display = 'none';
    this.render();
  },
  bellCount() {
    const u = this.currentUser; if (!u) return 0;
    if (u.userType === 'delivery') return this.orders.filter(o => o.status === 'pending').length;
    return this.orders.filter(o => o.buyerId === u.id && ['pending', 'accepted', 'delivering'].includes(o.status)).length;
  },

  /* ================= AUTH ================= */
  renderLogin() { this.renderAuth(document.getElementById('app')); },
  renderRegister() { this.renderAuth(document.getElementById('app')); },

  renderAuth(c) {
    const isLogin = this.currentPage === 'login';
    c.innerHTML = `
      <div class="auth-page">
        <div class="auth-brand">
          <div class="logo"><i class="ph ph-duotone ph-storefront"></i></div>
          <h1>حارة</h1>
          <p>سوق حيك</p>
        </div>
        <div class="auth-card">
          <h2>${isLogin ? 'أهلاً بعودتك 👋' : 'أنشئ حسابك الجديد'}</h2>
          ${isLogin ? `
          <form onsubmit="event.preventDefault();APP.login(document.getElementById('lemail').value,document.getElementById('lpass').value)">
            <div class="form-group"><label>البريد الإلكتروني</label><input id="lemail" class="form-input" type="email" placeholder="example@email.com" required></div>
            <div class="form-group"><label>كلمة المرور</label><input id="lpass" class="form-input" type="password" placeholder="••••••" required></div>
            <button class="btn btn-primary" type="submit"><i class="ph ph-duotone ph-sign-in"></i> تسجيل الدخول</button>
          </form>` : `
          <form onsubmit="event.preventDefault();APP.handleRegister()">
            <div class="form-group"><label>نوع الحساب</label><select id="rtype" class="form-input" onchange="APP.toggleRegisterFields()"><option value="regular">مستخدم عادي (بيع وشراء)</option><option value="delivery">موصل</option></select></div>
            <div class="form-group"><label>الاسم الكامل</label><input id="rname" class="form-input" placeholder="محمد أبو أحمد" required></div>
            <div class="form-group"><label>البريد الإلكتروني</label><input id="remail" class="form-input" type="email" placeholder="example@email.com" required></div>
            <div class="form-group"><label>رقم الهاتف</label><input id="rphone" class="form-input" type="tel" placeholder="05X XXX XXXX" required></div>
            <div class="form-group"><label>المدينة / الحي</label><input id="raddress" class="form-input" placeholder="رام الله - البيرة" required></div>
            <div class="form-group"><label>كلمة المرور</label><input id="rpass" class="form-input" type="password" placeholder="3 أحرف على الأقل" minlength="3" required></div>
            <div id="df" style="display:none">
              <div class="form-group"><label>مناطق التوصيل <span class="req">*</span></label><input id="rareas" class="form-input" placeholder="رام الله, البيرة, نابلس"></div>
              <div class="form-group"><label>أجرة التوصيل (شيكل)</label><input id="rfee" class="form-input" type="number" value="7"></div>
              <div class="form-group"><label>المركبة</label><select id="rvehicle" class="form-input"><option value="دراجة">دراجة</option><option value="سيارة">سيارة</option><option value="شاحنة">شاحنة</option></select></div>
            </div>
            <button class="btn btn-primary" type="submit"><i class="ph ph-duotone ph-user-plus"></i> إنشاء حساب</button>
          </form>`}
          <div class="auth-link">
            <span>${isLogin ? 'ما عندك حساب؟' : 'عندك حساب؟'}</span>
            <a href="#" onclick="APP.navigate('${isLogin ? 'register' : 'login'}');return false">${isLogin ? 'سجل الآن' : 'تسجيل الدخول'}</a>
          </div>
        </div>
      </div>`;
  },

  toggleRegisterFields() {
    const t = document.getElementById('rtype').value;
    document.getElementById('df').style.display = t === 'delivery' ? 'block' : 'none';
  },

  handleRegister() {
    this.register({
      name: document.getElementById('rname').value, email: document.getElementById('remail').value,
      phone: document.getElementById('rphone').value, address: document.getElementById('raddress').value,
      password: document.getElementById('rpass').value, userType: document.getElementById('rtype').value,
      deliveryAreas: document.getElementById('rareas')?.value?.split(',').map(s => s.trim()).filter(Boolean) || [],
      deliveryFee: parseFloat(document.getElementById('rfee')?.value) || 0,
      vehicleType: document.getElementById('rvehicle')?.value || '',
    });
  },

  login(email, password) {
    const user = this.users.find(u => u.email === email && u.password === password);
    if (!user) { this.toast('البريد الإلكتروني أو كلمة المرور غير صحيحة', 'error'); return false; }
    this.currentUser = user; this.saveAll(); this.navigate('home');
    this.toast(`مرحباً ${user.name}`, 'success'); return true;
  },

  register(data) {
    if (this.users.find(u => u.email === data.email)) { this.toast('البريد الإلكتروني مستخدم مسبقاً', 'error'); return false; }
    const user = { id: 'u' + Date.now(), ...data, deliveryAreas: data.deliveryAreas || [], deliveryFee: data.deliveryFee || 0, vehicleType: data.vehicleType || '', verified: false, available: true, rating: 0, ratingCount: 0, joinedAt: new Date().toISOString(), bio: '', balance: 100 };
    this.users.push(user); this.currentUser = user; this.saveAll(); this.navigate('home');
    this.toast('تم إنشاء الحساب بنجاح', 'success'); return true;
  },

  logout() {
    this.currentUser = null; this.cart = [];
    localStorage.removeItem('hara_current_user'); this.saveAll();
    this.navigate('login');
  },

  /* ================= HOME ================= */
  renderHome() {
    const p = document.getElementById('page-content');
    const u = this.currentUser;
    const skeleton = `
      <div class="container">
        <div class="skeleton" style="height:120px;border-radius:var(--radius-lg);margin-bottom:20px"></div>
        <div class="skeleton" style="height:52px;border-radius:var(--radius);margin-bottom:20px"></div>
        <div class="post-feed">${Array(3).fill('<div class="skel-post"><div class="skeleton" style="height:44px;border-radius:50%;width:40px;margin:14px 14px 0"></div><div class="skeleton" style="height:220px;border-radius:0;margin-top:14px"></div><div class="skeleton" style="height:14px;width:60%;margin:14px 14px 0;border-radius:6px"></div><div class="skeleton" style="height:14px;width:40%;margin:10px 14px 14px;border-radius:6px"></div></div>').join('')}</div>
      </div>`;
    p.innerHTML = skeleton;
    clearTimeout(this._homeT);
    this._homeT = setTimeout(() => p.innerHTML = this.buildHome(u), 400);
  },

  buildHome(u) {
    const recent = [...this.products].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 8);
    const topViews = [...this.products].sort((a, b) => b.views - a.views).slice(0, 6);
    const featured = this.products.filter(x => x.featured).slice(0, 6);
    const nearMe = this.nearProducts(6);
    const services = this.services.slice(0, 3);
    const jobs = this.jobs.slice(0, 3);
    const requests = this.requests.slice(0, 3);
    const cats = [['طعام', 'ph-bowl-food'], ['هواتف', 'ph-device-mobile'], ['إلكترونيات', 'ph-devices'], ['ملابس', 'ph-t-shirt'], ['أثاث', 'ph-couch'], ['لابتوبات', 'ph-laptop'], ['هدايا', 'ph-gift'], ['أخرى', 'ph-package']];
    const h = new Date().getHours();
    const dayPhrase = h < 12 ? 'صباح الخير — ماذا تحتاج اليوم؟' : h < 17 ? 'نهارك سعيد — ماذا تبحث عنه؟' : 'مساء الخير — لسه بدور على شي؟';

    const firstName = (u.name || 'صديق').split(' ')[0];
    const avatarLetter = (u.name || 'ح').trim().charAt(0);

    return `
      <div class="container">
        <div class="home-top">
          <div class="home-greet">
            <h2>أهلاً، <em>${firstName}</em></h2>
            <p>${dayPhrase}</p>
          </div>
          <div class="home-avatar">${avatarLetter}</div>
        </div>

        <div class="search-box lg">
          <span class="icon"><i class="ph ph-duotone ph-magnifying-glass"></i></span>
          <input id="home-search" autocomplete="off" placeholder="ابحث عن منتجات، خدمات، وظائف..." oninput="APP.homeSuggest(this.value)" onfocus="APP.homeSuggest(this.value)" onkeydown="if(event.key==='Enter'){APP.searchState.q=this.value;APP.navigate('market')}">
          <button class="search-clear" id="hs-clear" onclick="APP.clearHomeSearch()"><i class="ph ph-duotone ph-x"></i></button>
        </div>

        <div class="qa-row">
          <button class="qa-tile" onclick="APP.navigate('add-product')"><span class="qa-ico"><i class="ph ph-duotone ph-plus-circle"></i></span>انشر إعلان</button>
          <button class="qa-tile" onclick="APP.navigate('new-service')"><span class="qa-ico"><i class="ph ph-duotone ph-wrench"></i></span>قدّم خدمة</button>
          <button class="qa-tile" onclick="APP.navigate('new-request')"><span class="qa-ico"><i class="ph ph-duotone ph-megaphone"></i></span>اطلب شيئاً</button>
        </div>

        <div class="hero-banner">
          <div class="h-badge"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> مجتمع حارتك</div>
          <div class="h-title">كل ما تحتاجه في منطقتك<br><em>بيع، خدمات، وظائف، طلبات</em></div>
          <div class="h-sub">انشر إعلانك خلال دقيقة، أو اطلب خدمة من جيرانك — التوصيل متوفر.</div>
          <i class="ph ph-duotone ph-storefront h-ico"></i>
        </div>

        <div class="home-section" style="margin-bottom:22px">
          <div class="section-head"><h3><i class="ph ph-duotone ph-grid-four"></i> تصفح حسب الفئة</h3></div>
          <div class="cat-grid">
            ${cats.map(([name, icon]) => `<div class="cat-item" onclick="APP.selectedCategory='${name}';APP.navigate('market')"><div class="c-ico"><i class="ph ph-duotone ${icon}"></i></div><div class="c-name">${name}</div></div>`).join('')}
          </div>
        </div>

        ${featured.length ? `<div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-star"></i> إعلانات مميزة</h3><a href="#market" onclick="APP.navigate('market');return false">عرض الكل <i class="ph ph-duotone ph-arrow-left"></i></a></div>
          <div class="post-feed">${featured.map(x => this.postCard(x, true)).join('')}</div>
        </div>` : ''}

        ${nearMe.length ? `<div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-map-pin"></i> الأقرب إليك</h3></div>
          <div class="post-feed">${nearMe.map(x => this.postCard(x)).join('')}</div>
        </div>` : ''}

        <div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-clock"></i> أحدث الإعلانات</h3><a href="#market" onclick="APP.navigate('market');return false">عرض الكل <i class="ph ph-duotone ph-arrow-left"></i></a></div>
          <div class="post-feed">${recent.map(x => this.postCard(x)).join('')}</div>
        </div>

        <div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-fire"></i> الأكثر مشاهدة</h3></div>
          <div class="post-feed">${topViews.map(x => this.postCard(x)).join('')}</div>
        </div>

        <div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-wrench"></i> خدمات قريبة منك</h3><a href="#services" onclick="APP.navigate('services');return false">عرض الكل <i class="ph ph-duotone ph-arrow-left"></i></a></div>
          ${services.length === 0 ? this.emptyMini('لا توجد خدمات بعد') : services.map(s => this.serviceListItem(s)).join('')}
        </div>

        <div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-briefcase"></i> أحدث الوظائف</h3><a href="#jobs" onclick="APP.navigate('jobs');return false">عرض الكل <i class="ph ph-duotone ph-arrow-left"></i></a></div>
          ${jobs.length === 0 ? this.emptyMini('لا توجد وظائف بعد') : jobs.map(j => this.jobListItem(j)).join('')}
        </div>

        <div class="home-section">
          <div class="section-head"><h3><i class="ph ph-duotone ph-megaphone"></i> طلبات تحتاج عروضاً</h3><a href="#requests" onclick="APP.navigate('requests');return false">عرض الكل <i class="ph ph-duotone ph-arrow-left"></i></a></div>
          ${requests.length === 0 ? this.emptyMini('لا توجد طلبات بعد') : requests.map(r => this.requestListItem(r)).join('')}
        </div>
      </div>`;
  },

  userCity(addr) {
    if (!addr) return 'منطقتك';
    const parts = (addr || '').split(' - ')[0].split('،')[0];
    return parts || 'منطقتك';
  },

  nearProducts(n) {
    const myCity = this.locCity;
    const scored = this.products.filter(p => p.isAvailable).map(p => {
      let score = 0;
      if ((p.city || '').includes(myCity)) score += 100;
      score += (p.rating || 0) * 5;
      score += (p.views || 0) / 20;
      return { p, score };
    }).sort((a, b) => b.score - a.score);
    return scored.slice(0, n).map(s => s.p);
  },

  emptyMini(msg) { return `<div class="list-item" style="cursor:default"><p style="color:var(--text-muted);font-size:14px;text-align:center;width:100%">${msg}</p></div>`; },

  homeSuggest(q) {
    const box = document.getElementById('home-search');
    const clear = document.getElementById('hs-clear');
    clear.classList.toggle('show', q.length > 0);
    this.showSuggest(q, box, 'home');
  },
  clearHomeSearch() {
    const box = document.getElementById('home-search');
    box.value = ''; this.homeSuggest('');
    box.focus();
  },

  /* ================= SEARCH + SUGGESTIONS ================= */
  showSuggest(q, input, key) {
    document.querySelectorAll('.suggest').forEach(s => s.remove());
    if (!q || q.trim().length < 1) return;
    q = q.trim();
    const results = [];
    this.products.filter(p => p.isAvailable && (p.title.includes(q) || p.description.includes(q) || (p.city || '').includes(q) || p.category.includes(q))).slice(0, 3).forEach(p =>
      results.push({ type: 'منتج', icon: this.catStyle(p.category).icon, title: p.title, sub: p.city, price: p.price + ' ₪', act: () => this.showProductDetail(p.id) }));
    this.services.filter(s => s.title.includes(q) || s.category.includes(q)).slice(0, 2).forEach(s =>
      results.push({ type: 'خدمة', icon: 'ph-wrench', title: s.title, sub: s.providerName, price: s.price + ' ₪', act: () => this.showServiceDetail(s.id) }));
    this.jobs.filter(j => j.title.includes(q) || j.companyName.includes(q)).slice(0, 2).forEach(j =>
      results.push({ type: 'وظيفة', icon: 'ph-briefcase', title: j.title, sub: j.companyName, price: j.salary, act: () => this.showJobDetail(j.id) }));
    this.requests.filter(r => r.status !== 'done' && r.title.includes(q)).slice(0, 2).forEach(r =>
      results.push({ type: 'طلب', icon: 'ph-megaphone', title: r.title, sub: r.userName, price: '', act: () => this.showRequestDetail(r.id) }));
    if (results.length === 0) return;
    const wrap = document.createElement('div');
    wrap.className = 'suggest';
    wrap.innerHTML = results.map(r => `
      <div class="suggest-item" data-i="${results.indexOf(r)}">
        <div class="s-icon"><i class="ph ph-duotone ${r.icon}"></i></div>
        <div><div class="s-title">${this.esc(r.title)}</div><div class="s-sub">${r.type} • ${this.esc(r.sub)}</div></div>
        <div class="s-price">${r.price}</div>
      </div>`).join('');
    wrap.addEventListener('click', (e) => {
      const i = e.target.closest('.suggest-item')?.dataset.i;
      if (i == null) return;
      results[i].act();
    });
    input.parentElement.appendChild(wrap);
  },

  renderSearch() {
    const p = document.getElementById('page-content');
    p.innerHTML = `
      <div class="container">
        <h2 style="font-size:19px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-magnifying-glass" style="color:var(--gold)"></i> بحث متقدم</h2>
        <div class="search-box lg">
          <span class="icon"><i class="ph ph-duotone ph-magnifying-glass"></i></span>
          <input id="g-search" autocomplete="off" value="${this.esc(this.searchState.q)}" placeholder="ماذا تبحث عنه؟" oninput="APP.globalSearch(this.value)" onkeydown="if(event.key==='Enter')APP.globalSearchGo()">
        </div>
        <div id="g-results" style="margin-top:4px"></div>
      </div>`;
    document.getElementById('g-search').focus();
    this.globalSearch(this.searchState.q);
  },

  globalSearch(q) {
    this.searchState.q = q;
    const res = document.getElementById('g-results');
    if (!q) { res.innerHTML = this.filterPanel(); return; }
    const products = this.filterProducts();
    const services = this.services.filter(s => s.title.includes(q) || s.category.includes(q) || (s.areas || []).join('').includes(q));
    const jobs = this.jobs.filter(j => j.title.includes(q) || j.companyName.includes(q) || (j.city || '').includes(q));
    const requests = this.requests.filter(r => r.status !== 'done' && r.title.includes(q));
    res.innerHTML = `
      ${products.length ? `<div class="section-head"><h3><i class="ph ph-duotone ph-shopping-bag"></i> منتجات (${products.length})</h3></div><div class="post-feed" style="margin-bottom:18px">${products.slice(0, 4).map(x => this.postCard(x)).join('')}</div>` : ''}
      ${services.length ? `<div class="section-head"><h3><i class="ph ph-duotone ph-wrench"></i> خدمات (${services.length})</h3></div>${services.slice(0, 3).map(s => this.serviceListItem(s)).join('')}` : ''}
      ${jobs.length ? `<div class="section-head"><h3><i class="ph ph-duotone ph-briefcase"></i> وظائف (${jobs.length})</h3></div>${jobs.slice(0, 3).map(j => this.jobListItem(j)).join('')}` : ''}
      ${requests.length ? `<div class="section-head"><h3><i class="ph ph-duotone ph-megaphone"></i> طلبات (${requests.length})</h3></div>${requests.slice(0, 3).map(r => this.requestListItem(r)).join('')}` : ''}
      ${!products.length && !services.length && !jobs.length && !requests.length ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-magnifying-glass"></i></div><h3>لا توجد نتائج</h3><p>جرّب كلمة بحث مختلفة</p></div>' : ''}`;
  },
  globalSearchGo() { this.navigate('market'); },

  filterPanel() {
    const st = this.searchState;
    return `
      <div class="section" style="margin-top:18px">
        <div class="section-head"><h3><i class="ph ph-duotone ph-funnel"></i> فلاتر البحث</h3><button class="icon-btn" style="width:36px;height:36px;font-size:16px" onclick="APP.resetFilters()" title="إعادة تعيين"><i class="ph ph-duotone ph-arrow-counter-clockwise"></i></button></div>
        <div class="filter-grid">
          <div class="filter-group"><label>الترتيب حسب</label><div class="sort-row">
            ${[['latest', 'الأحدث'], ['priceAsc', 'الأقل سعراً'], ['priceDesc', 'الأعلى سعراً'], ['rating', 'الأعلى تقييماً'], ['views', 'الأكثر مشاهدة'], ['near', 'الأقرب']].map(([k, l]) => `<button class="sort-chip ${st.sort === k ? 'active' : ''}" onclick="APP.searchState.sort='${k}';APP.filterPanel();APP.globalSearch(APP.searchState.q)">${l}</button>`).join('')}
          </div></div>
          <div class="filter-group"><label>حالة المنتج</label><div class="sort-row">
            ${['الكل', 'جديد', 'مستعمل'].map(c => `<button class="sort-chip ${st.condition === c ? 'active' : ''}" onclick="APP.searchState.condition='${c}';APP.filterPanel();APP.globalSearch(APP.searchState.q)">${c}</button>`).join('')}
          </div></div>
        </div>
        <div class="filter-grid" style="margin-top:14px">
          <div class="filter-group"><label>المدينة</label><input class="form-input" id="f-city" placeholder="الخليل، نابلس..." value="${this.esc(st.city)}" onchange="APP.searchState.city=this.value;APP.globalSearch(APP.searchState.q)"></div>
          <div class="filter-group"><label>أقصى سعر (شيكل)</label><input class="form-input" id="f-price" type="number" placeholder="500" value="${st.priceMax || ''}" onchange="APP.searchState.priceMax=this.value;APP.globalSearch(APP.searchState.q)"></div>
        </div>
      </div>`;
  },

  resetFilters() {
    this.searchState = { q: this.searchState.q, cat: 'الكل', condition: 'الكل', city: '', sort: 'latest', priceMax: null };
    const g = document.getElementById('g-search'); if (g) this.globalSearch(g.value);
  },

  /* ================= MARKET ================= */
  renderMarket() {
    const p = document.getElementById('page-content');
    const st = this.searchState;
    const products = this.filterProducts();
    const cats = ['الكل', 'طعام', 'إلكترونيات', 'هواتف', 'لابتوبات', 'سيارات', 'عقارات', 'أثاث', 'ملابس', 'ألعاب', 'أجهزة منزلية', 'كتب', 'رياضة', 'هدايا', 'منزل', 'أخرى'];
    p.innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px">
          <h2 style="font-size:20px;font-weight:700;flex:1;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-storefront" style="color:var(--gold)"></i> السوق</h2>
          <button class="btn btn-soft btn-sm" style="display:flex;gap:5px" onclick="APP.openFilters()"><i class="ph ph-duotone ph-funnel"></i> فلاتر</button>
        </div>
        <div class="search-box">
          <span class="icon"><i class="ph ph-duotone ph-magnifying-glass"></i></span>
          <input id="search-q" autocomplete="off" value="${this.esc(st.q)}" placeholder="ابحث في السوق..." oninput="APP.marketType(this.value)" onkeydown="if(event.key==='Enter')APP.marketGo()">
          ${st.q ? `<button class="search-clear show" onclick="APP.searchState.q='';APP.renderMarket()"><i class="ph ph-duotone ph-x"></i></button>` : ''}
        </div>
        <div class="category-scroll">
          ${cats.map(c => `<button class="category-chip ${st.cat === c ? 'active' : ''}" onclick="APP.searchState.cat='${c}';APP.renderMarket()">${c}</button>`).join('')}
        </div>
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
          <span style="font-size:12.5px;color:var(--text-muted)">${products.length} نتيجة</span>
          <span style="font-size:12.5px;color:var(--text-muted)">الترتيب: <b style="color:var(--primary)">${this.sortLabel(st.sort)}</b></span>
        </div>
        ${products.length === 0 ? `<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-package"></i></div><h3>لا توجد نتائج</h3><p>جرّب تعديل الفلاتر أو البحث، أو انشر إعلانك الأول</p><button class="btn btn-primary" style="display:flex;gap:8px" onclick="APP.navigate('add-product')"><i class="ph ph-duotone ph-plus-circle"></i> انشر إعلان</button></div>` : `
          <div class="post-feed">
            ${products.map(x => this.postCard(x)).join('')}
          </div>`}
      </div>`;
  },

  sortLabel(s) {
    return { latest: 'الأحدث', priceAsc: 'الأقل سعراً', priceDesc: 'الأعلى سعراً', rating: 'الأعلى تقييماً', views: 'الأكثر مشاهدة', near: 'الأقرب' }[s] || 'الأحدث';
  },

  marketType(v) { this.searchState.q = v; this.showSuggest(v, document.getElementById('search-q'), 'market'); },
  marketGo() { this.renderMarket(); },

  openFilters() {
    const st = this.searchState;
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:18px;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-funnel" style="color:var(--gold)"></i> الفلاتر والترتيب</h3>
      <div class="filter-group"><label>الترتيب حسب</label><div class="sort-row">
        ${[['latest', 'الأحدث'], ['priceAsc', 'الأقل سعراً'], ['priceDesc', 'الأعلى سعراً'], ['rating', 'الأعلى تقييماً'], ['views', 'الأكثر مشاهدة'], ['near', 'الأقرب']].map(([k, l]) => `<button class="sort-chip ${st.sort === k ? 'active' : ''}" onclick="APP.searchState.sort='${k}';APP.openFilters();APP.renderMarket()">${l}</button>`).join('')}
      </div></div>
      <div class="filter-group"><label>حالة المنتج</label><div class="sort-row">
        ${['الكل', 'جديد', 'مستعمل'].map(c => `<button class="sort-chip ${st.condition === c ? 'active' : ''}" onclick="APP.searchState.condition='${c}';APP.openFilters();APP.renderMarket()">${c}</button>`).join('')}
      </div></div>
      <div class="filter-grid">
        <div class="filter-group"><label>المدينة</label><input class="form-input" id="f-city" placeholder="الخليل، نابلس..." value="${this.esc(st.city)}" onchange="APP.searchState.city=this.value"></div>
        <div class="filter-group"><label>أقصى سعر (شيكل)</label><input class="form-input" id="f-price" type="number" placeholder="500" value="${st.priceMax || ''}" onchange="APP.searchState.priceMax=this.value"></div>
      </div>
      <button class="btn btn-primary" style="margin-top:8px;display:flex;gap:8px" onclick="APP.closeModal();APP.renderMarket()"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تطبيق الفلاتر</button>
    `);
  },

  filterProducts() {
    const st = this.searchState;
    let list = this.products.filter(p => p.isAvailable);
    if (st.cat && st.cat !== 'الكل') list = list.filter(p => p.category === st.cat);
    if (st.condition && st.condition !== 'الكل') list = list.filter(p => p.condition === st.condition);
    if (st.city) list = list.filter(p => (p.city || '').includes(st.city));
    if (st.q) list = list.filter(p => p.title.includes(st.q) || p.description.includes(st.q) || (p.city || '').includes(st.q));
    if (st.priceMax) list = list.filter(p => p.price <= parseFloat(st.priceMax));
    const myCity = this.locCity;
    switch (st.sort) {
      case 'priceAsc': list.sort((a, b) => a.price - b.price); break;
      case 'priceDesc': list.sort((a, b) => b.price - a.price); break;
      case 'rating': list.sort((a, b) => (b.rating || 0) - (a.rating || 0)); break;
      case 'views': list.sort((a, b) => b.views - a.views); break;
      case 'near': list.sort((a, b) => ((b.city || '').includes(myCity) ? 1 : 0) - ((a.city || '').includes(myCity) ? 1 : 0)); break;
      default: list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }
    return list;
  },

  productCard(x) {
    const im = this.productImages(x)[0];
    const saved = this.saved.includes(x.id);
    return `<div class="product-card" onclick="APP.showProductDetail('${x.id}')">
      <div class="product-img" style="background:${im.bg}">
        <img src="${im.img}" alt="${this.esc(x.title)}" loading="lazy">
        <div class="img-shade"></div>
        ${x.featured ? '<span class="badge-feat"><i class="ph ph-duotone ph-star"></i> مميز</span>' : ''}
        <span class="badge-cat">${x.category || 'عام'}</span>
        ${x.condition ? `<span class="badge-cond ${x.condition === 'جديد' ? 'cond-new' : ''}">${x.condition}</span>` : ''}
        <button class="ca-btn ${saved ? 'on' : ''}" onclick="event.stopPropagation();APP.toggleSave('${x.id}')" title="حفظ"><i class="ph ph-duotone ${saved ? 'ph-bookmark' : 'ph-bookmark'}"></i></button>
      </div>
      <div class="product-info">
        <h3>${this.esc(x.title)}</h3>
        <div class="p-row">
          <div class="price">${this.fmt(x.price)}</div>
          <div class="rating-stars">${this.stars(x.rating)}</div>
        </div>
      </div>
    </div>`;
  },

  miniProductCard(x, feat) {
    const im = this.productImages(x)[0];
    const saved = this.saved.includes(x.id);
    return `<div class="mini-card" onclick="APP.showProductDetail('${x.id}')">
      <div class="thumb" style="background:${im.bg}"><img src="${im.img}" alt="" loading="lazy">
        ${feat || x.featured ? '<span class="badge-feat"><i class="ph ph-duotone ph-star"></i></span>' : ''}
        <button class="ca-btn mini ${saved ? 'on' : ''}" onclick="event.stopPropagation();APP.toggleSave('${x.id}')"><i class="ph ph-duotone ${saved ? 'ph-bookmark' : 'ph-bookmark'}"></i></button>
      </div>
      <div class="body">
        <h4>${this.esc(x.title)}</h4>
        <div class="muted"><i class="ph ph-duotone ph-map-pin" style="font-size:10px"></i> ${x.city || ''}</div>
        <div class="price">${this.fmt(x.price)}</div>
      </div>
    </div>`;
  },

  postCard(x, feat) {
    const imgs = this.productImages(x);
    const im = imgs[0];
    const saved = this.saved.includes(x.id);
    const seller = this.users.find(u => u.id === x.sellerId);
    const name = seller?.name || x.sellerName || 'بائع';
    const city = x.city || (seller ? this.userCity(seller.address) : '');
    return `<div class="post-card" onclick="APP.showProductDetail('${x.id}')">
      <div class="post-head">
        <div class="post-ava">${this.esc(name[0] || 'ب')}</div>
        <div class="post-meta">
          <b>${this.esc(name)}${seller?.verified ? '<span class="verified"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></span>' : ''}${feat || x.featured ? '<span class="tag tag-accent" style="margin-inline-start:6px"><i class="ph ph-duotone ph-star"></i> مميز</span>' : ''}</b>
          <span><i class="ph ph-duotone ph-map-pin" style="font-size:11px"></i> ${city || ''} ${x.city || city ? '·' : ''} ${this.timeAgo(x.createdAt)}</span>
        </div>
        <button class="post-kebab ${saved ? 'on' : ''}" onclick="event.stopPropagation();APP.toggleSave('${x.id}')"><i class="ph ph-duotone ph-bookmark-simple"></i></button>
      </div>
      ${im ? `<div class="post-img"><img src="${im.img}" alt="${this.esc(x.title)}" loading="lazy"></div>` : ''}
      <div class="post-body">
        <div class="post-price">${this.fmt(x.price)}</div>
        <h3>${this.esc(x.title)}</h3>
      </div>
      <div class="post-actions">
        <button class="post-action" onclick="event.stopPropagation();APP.startChat('${this.esc(name)}','بخصوص إعلانك: ${this.esc(x.title)}')"><i class="ph ph-duotone ph-chats-circle"></i> تواصل</button>
        <button class="post-action ${saved ? 'on' : ''}" onclick="event.stopPropagation();APP.toggleSave('${x.id}')"><i class="ph ph-duotone ph-bookmark-simple"></i> ${saved ? 'محفوظ' : 'حفظ'}</button>
        <button class="post-action" onclick="event.stopPropagation();APP.shareProduct('${x.id}')"><i class="ph ph-duotone ph-share-network"></i> مشاركة</button>
      </div>
    </div>`;
  },

  catIcons() { return {}; },

  /* ================= PRODUCT DETAIL ================= */
  showProductDetail(id) {
    this._detailId = id;
    const p = this.products.find(x => x.id === id);
    if (p) p.views = (p.views || 0) + 1;
    this.saveAll();
    this.navigate('product-detail');
  },

  renderProductDetail() {
    let p = this.products.find(x => x.id === this._detailId);
    if (!p && this.products.length > 0) { this._detailId = this.products[0].id; p = this.products[0]; }
    if (!p) { this.navigate('home'); return; }
    const images = this.productImages(p);
    const saved = this.saved.includes(p.id);
    const mine = this.currentUser?.id === p.sellerId;
    const seller = this.users.find(u => u.id === p.sellerId);
    const sc = this.catStyle(p.category);
    document.getElementById('page-content').innerHTML = `
      ${images.length ? `
      <div class="detail-hero">
        <div class="gallery" id="gallery" style="background:${images[0].bg}">
          <div class="gallery-track" id="g-track">
            ${images.map((im, i) => `<div class="gallery-slide" style="background:${im.bg}" onclick="APP.openViewer(${i})"><img src="${im.img}" alt="${this.esc(p.title)}"></div>`).join('')}
          </div>
          ${images.length > 1 ? `
            <div class="gallery-count" id="g-count">1 / ${images.length}</div>
            <div class="gallery-dots" id="g-dots">${images.map((_, i) => `<i class="${i === 0 ? 'on' : ''}"></i>`).join('')}</div>` : ''}
        </div>
      </div>` : ''}
      <div class="container" style="padding-top:18px">
        <div class="detail-body">
          <div style="display:flex;gap:8px;margin-bottom:10px;flex-wrap:wrap">
            <span class="tag ${(p.condition || 'جديد') === 'جديد' ? 'tag-olive' : 'tag-slate'}">${p.condition || 'جديد'}</span>
            ${p.featured ? '<span class="tag tag-accent"><i class="ph ph-duotone ph-star"></i> مميز</span>' : ''}
          </div>
          <h1 class="detail-title">${this.esc(p.title)}</h1>
          <div class="detail-price-row">
            <div class="detail-price">${this.fmt(p.price)}</div>
            <div class="rating-stars">${this.stars(p.rating)} <span style="font-size:12px;color:var(--text-muted)">${p.rating || 0} (${p.ratingCount || 0})</span></div>
          </div>

          <div class="action-row">
            <button class="icon-btn ${saved ? 'active save' : ''}" onclick="APP.toggleSave('${p.id}')"><i class="ph ph-duotone ${saved ? 'ph-bookmark' : 'ph-bookmark'}"></i><span class="lbl">حفظ</span><span class="count">${p.saves || 0}</span></button>
            <button class="icon-btn" onclick="APP.shareProduct('${p.id}')"><i class="ph ph-duotone ph-share-network"></i><span class="lbl">مشاركة</span></button>
            <button class="icon-btn" onclick="APP.reportProduct('${p.id}')"><i class="ph ph-duotone ph-flag"></i><span class="lbl">تبليغ</span></button>
          </div>

          <div class="section" style="margin-bottom:14px">
            <div class="meta-list">
              <div><i class="ph ph-duotone ph-map-pin"></i> <b>الموقع:</b> ${this.esc(p.city || 'غير محدد')}</div>
              <div><i class="ph ph-duotone ph-calendar-blank"></i> <b>تاريخ النشر:</b> ${new Date(p.createdAt).toLocaleDateString('ar-EG', { day: 'numeric', month: 'long', year: 'numeric' })} (${this.timeAgo(p.createdAt)})</div>
              <div><i class="ph ph-duotone ph-eye"></i> <b>المشاهدات:</b> ${p.views || 0}</div>
              <div><i class="ph ph-duotone ph-bookmark"></i> <b>مرات الحفظ:</b> ${p.saves || 0}</div>
              <div><i class="ph ph-duotone ph-package"></i> <b>الكمية المتوفرة:</b> ${p.stock > 0 ? `${p.stock} قطعة` : 'غير متوفر'}</div>
            </div>
          </div>

          <div class="section" style="margin-bottom:14px">
            <h3 style="font-size:15px;font-weight:700;margin-bottom:8px;display:flex;align-items:center;gap:6px"><i class="ph ph-duotone ph-file-text" style="color:var(--gold)"></i> الوصف</h3>
            <div class="detail-desc">${this.esc(p.description || 'لا يوجد وصف')}</div>
          </div>

          <div class="seller-card">
            <div class="s-ava">${this.esc((seller?.name || p.sellerName)[0])}</div>
            <div style="flex:1;min-width:0">
              <div class="s-name">${this.esc(seller?.name || p.sellerName)}${(seller?.verified) ? '<span class="verified"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></span>' : ''}</div>
              <div class="s-meta">
                ${seller?.rating ? `<span><i class="ph ph-duotone ph-star" style="color:var(--gold)"></i> ${seller.rating}</span>` : ''}
                ${seller ? `<span><i class="ph ph-duotone ph-map-pin"></i> ${this.userCity(seller.address)}</span>` : ''}
                ${seller?.joinedAt ? `<span><i class="ph ph-duotone ph-clock"></i> منذ ${this.timeAgo(seller.joinedAt)}</span>` : ''}
              </div>
            </div>
          </div>

          ${mine ? `<button class="btn btn-outline" style="margin-bottom:10px;display:flex;gap:8px" onclick="APP.navigate('add-product')"><i class="ph ph-duotone ph-pen"></i> تعديل إعلانك</button>` : `
            <button class="btn btn-primary" style="display:flex;gap:8px;margin-bottom:10px" onclick="APP.addToCart('${p.id}')"><i class="ph ph-duotone ph-shopping-cart"></i> أضف إلى السلة</button>
            <button class="btn btn-outline" style="display:flex;gap:8px;margin-bottom:10px" onclick="APP.startChat('${this.esc(p.sellerName)}','بخصوص إعلانك: ${this.esc(p.title)}')"><i class="ph ph-duotone ph-chats-circle"></i> تواصل مع البائع</button>
            <button class="btn btn-outline" style="display:flex;gap:8px" onclick="APP.requestDelivery('${p.id}')"><i class="ph ph-duotone ph-moped"></i> اطلب التوصيل</button>`}
        </div>
      </div>
      <div class="viewer" id="viewer" onclick="this.classList.remove('show')"></div>`;
    this._viewerIdx = 0;
    const track = document.getElementById('g-track');
    if (track) {
      track.addEventListener('scroll', () => {
        const idx = Math.round(track.scrollLeft / track.clientWidth);
        if (idx === this._viewerIdx) return;
        this._viewerIdx = idx;
        const c = document.getElementById('g-count'); if (c) c.textContent = `${idx + 1} / ${images.length}`;
        document.querySelectorAll('#g-dots i').forEach((d, i) => d.classList.toggle('on', i === idx));
      });
    }
  },

  toggleSave(id) {
    const p = this.products.find(x => x.id === id); if (!p) return;
    const i = this.saved.indexOf(id);
    if (i >= 0) { this.saved.splice(i, 1); p.saves = Math.max(0, (p.saves || 0) - 1); }
    else { this.saved.push(id); p.saves = (p.saves || 0) + 1; }
    this.saveAll(); this.render();
    this.toast(this.saved.includes(id) ? 'تم حفظ الإعلان' : 'أزيل من المحفوظات', this.saved.includes(id) ? 'success' : 'info');
  },

  shareProduct(id) {
    const p = this.products.find(x => x.id === id); if (!p) return;
    const text = `${p.title} — ${p.price} ₪\n${p.description || ''}`;
    if (navigator.share) navigator.share({ title: p.title, text }).catch(() => {});
    else { navigator.clipboard?.writeText(text); this.toast('تم نسخ رابط الإعلان', 'success'); }
  },

  reportProduct(id) {
    const p = this.products.find(x => x.id === id); if (!p) return;
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-flag" style="color:var(--error)"></i> الإبلاغ عن إعلان</h3>
      <p style="font-size:14px;color:var(--text-muted);margin-bottom:16px">لماذا تريد الإبلاغ عن «${this.esc(p.title)}»؟</p>
      <div class="filter-group"><label>السبب</label><select id="rep-reason" class="form-input">
        <option>محتوى مخالف</option><option>احتيال أو عملية وهمية</option><option>منتج مغشوش</option><option>إعلان مكرر</option><option>أخرى</option>
      </select></div>
      <div class="form-group"><label>تفاصيل إضافية (اختياري)</label><textarea id="rep-desc" class="form-input" placeholder="اشرح المشكلة..."></textarea></div>
      <button class="btn btn-danger" style="display:flex;gap:8px" onclick="APP.closeModal();APP.toast('تم استلام بلاغك، شكراً لمساعدتنا','success')"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> إرسال البلاغ</button>
    `);
  },

  requestDelivery(id) {
    const p = this.products.find(x => x.id === id); if (!p) return;
    const u = this.currentUser;
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:4px">طلب توصيل</h3>
      <p style="font-size:13px;color:var(--text-muted);margin-bottom:16px">«${this.esc(p.title)}» من ${this.esc(p.sellerName)}</p>
      <div class="form-group"><label>عنوان الاستلام</label><input id="dreq-addr" class="form-input" value="${this.esc(u.address)}"></div>
      <div class="form-group"><label>رقم الهاتف</label><input id="dreq-phone" class="form-input" value="${this.esc(u.phone)}"></div>
      <button class="btn btn-primary" style="display:flex;gap:8px" onclick="APP.submitDeliveryRequest('${p.id}')"><i class="ph ph-duotone ph-moped"></i> تأكيد طلب التوصيل</button>
    `);
  },

  submitDeliveryRequest(id) {
    const p = this.products.find(x => x.id === id); if (!p) return;
    const u = this.currentUser;
    this.requests.unshift({
      id: 'rq' + Date.now(), userId: u.id, userName: u.name,
      title: `طلب توصيل: ${p.title}`, category: 'توصيل',
      description: `أحتاج توصيل «${p.title}» إلى ${document.getElementById('dreq-addr').value}. هاتف: ${document.getElementById('dreq-phone').value}`,
      status: 'open', offers: [], createdAt: new Date().toISOString(),
    });
    this.saveAll(); this.closeModal(); this.navigate('requests');
    this.toast('تم نشر طلب التوصيل — سيصلك عروض من الموصلين', 'success');
  },

  openViewer(idx) {
    const p = this.products.find(x => x.id === this._detailId); if (!p) return;
    const images = this.productImages(p);
    const v = document.getElementById('viewer');
    v.innerHTML = `<button class="v-close"><i class="ph ph-duotone ph-x"></i></button>
      <img src="${images[idx].img}" alt="${this.esc(p.title)}">
      <div class="v-tag">${idx + 1} / ${images.length} • اضغط في أي مكان للإغلاق</div>`;
    v.classList.add('show');
  },

  /* ================= ADD PRODUCT ================= */
  renderAddProduct() {
    document.getElementById('page-content').innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:20px">
          <button class="icon-btn" style="width:38px;height:38px" onclick="APP.navigate('market')"><i class="ph ph-duotone ph-arrow-right"></i></button>
          <h2 style="font-size:19px;font-weight:700;flex:1">نشر إعلان جديد</h2>
        </div>
        <form onsubmit="event.preventDefault();APP.handleAddProduct()">
          <div class="form-group"><label>اسم المنتج <span class="req">*</span></label><input id="ptitle" class="form-input" placeholder="مثال: زيت زيتون بلدي" required></div>
          <div class="form-group"><label>الوصف الكامل</label><textarea id="pdesc" class="form-input" placeholder="اكتب تفاصيل المنتج، الحالة، سبب البيع..."></textarea></div>
          <div class="form-group"><label>السعر (شيكل) <span class="req">*</span></label><input id="pprice" class="form-input" type="number" step="0.5" placeholder="0" required></div>
          <div class="filter-grid">
            <div class="form-group"><label>التصنيف</label><select id="pcat" class="form-input"><option value="طعام">طعام</option><option value="إلكترونيات">إلكترونيات</option><option value="هواتف">هواتف</option><option value="لابتوبات">لابتوبات</option><option value="سيارات">سيارات</option><option value="عقارات">عقارات</option><option value="أثاث">أثاث</option><option value="ملابس">ملابس</option><option value="ألعاب">ألعاب</option><option value="أجهزة منزلية">أجهزة منزلية</option><option value="كتب">كتب</option><option value="رياضة">رياضة</option><option value="هدايا">هدايا</option><option value="منزل">منزل</option><option value="أخرى">أخرى</option></select></div>
            <div class="form-group"><label>حالة المنتج</label><select id="pcond" class="form-input"><option value="جديد">جديد</option><option value="مستعمل">مستعمل</option></select></div>
          </div>
          <div class="filter-grid">
            <div class="form-group"><label>المدينة / الحي</label><input id="pcity" class="form-input" placeholder="رام الله - البيرة"></div>
            <div class="form-group"><label>الكمية</label><input id="pstock" class="form-input" type="number" value="1"></div>
          </div>
          <button class="btn btn-primary" type="submit" style="display:flex;gap:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> نشر الإعلان</button>
        </form>
      </div>`;
  },

  handleAddProduct() {
    this.addProduct({
      sellerId: this.currentUser.id, sellerName: this.currentUser.name,
      title: document.getElementById('ptitle').value, description: document.getElementById('pdesc').value,
      price: parseFloat(document.getElementById('pprice').value), category: document.getElementById('pcat').value,
      condition: document.getElementById('pcond').value,
      city: document.getElementById('pcity').value,
      stock: parseInt(document.getElementById('pstock').value) || 1,
      views: 0, saves: 0, featured: false,
    });
    this.navigate('market');
  },

  addProduct(d) {
    const p = { id: 'p' + Date.now(), ...d, createdAt: new Date().toISOString(), isAvailable: true, rating: 0, ratingCount: 0, images: [] };
    this.products.unshift(p); this.saveAll(); this.render();
    this.toast('تم نشر إعلانك', 'success');
  },

  /* ================= CART ================= */
  addToCart(id) {
    const e = this.cart.find(c => c.productId === id);
    e ? e.quantity++ : this.cart.push({ productId: id, quantity: 1 });
    this.saveAll(); this.render(); this.toast('أضيف إلى السلة', 'success'); this.updateBadge();
  },

  updateCart(id, d) {
    const i = this.cart.find(c => c.productId === id); if (!i) return;
    i.quantity += d; if (i.quantity <= 0) this.cart = this.cart.filter(c => c.productId !== id);
    this.saveAll(); this.render(); this.updateBadge();
  },

  clearCart() { this.cart = []; this.saveAll(); this.updateBadge(); },

  getCartTotal() { return this.cart.reduce((s, i) => { const p = this.products.find(x => x.id === i.productId); return s + (p ? p.price * i.quantity : 0); }, 0); },
  getCartCount() { return this.cart.reduce((s, i) => s + i.quantity, 0); },

  updateBadge() { const b = document.querySelector('.cart-badge'); if (b) b.textContent = this.getCartCount(); },

  renderCart() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    if (this.cart.length === 0) { p.innerHTML = '<div class="empty-state" style="padding-top:70px"><div class="icon"><i class="ph ph-duotone ph-shopping-cart"></i></div><h3>سلتك فارغة</h3><p>أضف منتجات من المتجر</p><button class="btn btn-primary" style="margin-top:18px;max-width:240px;margin-inline:auto;display:flex;gap:8px" onclick="APP.navigate(\'market\')"><i class="ph ph-duotone ph-storefront"></i> تصفح السوق</button></div>'; b.style.display = 'none'; return; }
    p.innerHTML = `
      <div class="container">
        <h2 style="margin-bottom:16px;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-shopping-cart" style="color:var(--gold)"></i> سلتي (${this.getCartCount()})</h2>
        ${this.cart.map(item => { const x = this.products.find(p => p.id === item.productId); if (!x) return '';
          const im = this.productImages(x)[0];
          return `<div class="cart-item"><div class="cart-item-img" style="background:var(--bg-2)">${im ? `<img src="${im.img}" alt="${this.esc(x.title)}">` : `<div class="ci-icon"><i class="${this.catStyle(x.category).icon}"></i></div>`}</div>
            <div class="cart-item-info"><h4>${this.esc(x.title)}</h4><div class="item-price">${x.price} ₪ × ${item.quantity}</div></div>
            <div class="qty-control"><button onclick="APP.updateCart('${x.id}',-1)">−</button><span>${item.quantity}</span><button onclick="APP.updateCart('${x.id}',1)">+</button></div></div>`;
        }).join('')}
      </div>`;
    b.style.display = 'flex';
    b.innerHTML = `<div><div class="total-label">المجموع</div><div class="total-amount">${this.getCartTotal()} ₪</div></div>
      <button class="btn btn-primary" onclick="APP.navigate('checkout')" style="display:flex;gap:8px"><i class="ph ph-duotone ph-arrow-left"></i> متابعة الطلب</button>`;
  },

  /* ================= CHECKOUT / ORDERS ================= */
  renderCheckout() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none'; const u = this.currentUser;
    const total = this.getCartTotal() + 5, bal = u.balance || 0, walletOk = bal >= total;
    p.innerHTML = `
      <div class="container">
        <h2 style="margin-bottom:16px;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-clipboard-text" style="color:var(--gold)"></i> تأكيد الطلب</h2>
        <div class="section" style="margin-bottom:12px"><h3 style="margin-bottom:8px;display:flex;align-items:center;gap:6px"><i class="ph ph-duotone ph-map-pin" style="color:var(--gold)"></i> عنوان التوصيل</h3>
          <p style="font-weight:600">${this.esc(u.name)}</p><p style="color:var(--text-muted);font-size:13px;margin-top:2px">${this.esc(u.phone)} • ${this.esc(u.address)}</p></div>
        <div class="section" style="margin-bottom:12px"><h3 style="margin-bottom:8px;display:flex;align-items:center;gap:6px"><i class="ph ph-duotone ph-list" style="color:var(--gold)"></i> المنتجات</h3>
          ${this.cart.map(item => { const x = this.products.find(p => p.id === item.productId); if (!x) return ''; return `<div style="display:flex;justify-content:space-between;padding:5px 0"><span>${this.esc(x.title)} × ${item.quantity}</span><span style="font-weight:600">${x.price * item.quantity} ₪</span></div>`; }).join('')}
          <hr style="border:none;border-top:1px solid var(--line);margin:10px 0">
          <div style="display:flex;justify-content:space-between;font-size:13.5px"><span>المجموع</span><span>${this.getCartTotal()} ₪</span></div>
          <div style="display:flex;justify-content:space-between;font-size:13.5px;color:var(--text-muted)"><span>رسوم التوصيل</span><span>5 ₪</span></div>
          <hr style="border:none;border-top:1px solid var(--line);margin:10px 0">
          <div style="display:flex;justify-content:space-between;font-size:21px;font-weight:700;color:var(--primary)"><span>الإجمالي</span><span>${total} ₪</span></div>
        </div>
        <div class="section" style="margin-bottom:12px"><h3 style="margin-bottom:8px;display:flex;align-items:center;gap:6px"><i class="ph ph-duotone ph-wallet" style="color:var(--gold)"></i> طريقة الدفع</h3>
          <div style="display:flex;justify-content:space-between;align-items:center;background:var(--bg);border:1px dashed var(--line);border-radius:12px;padding:10px 14px;margin-bottom:12px;font-size:13.5px">
            <span style="display:flex;align-items:center;gap:6px"><i class="ph ph-duotone ph-wallet" style="color:var(--gold)"></i> رصيد محفظتك</span>
            <b style="color:${walletOk ? 'var(--success)' : 'var(--error)'};font-size:15px">${bal} ₪</b>
          </div>
          ${['كاش', 'محفظة', 'تحويل'].map((m, i) => { const dis = m === 'محفظة' && !walletOk; return `<label class="radio-item"><input type="radio" name="pay" value="${m}" ${i === 0 ? 'checked' : ''} ${dis ? 'disabled' : ''}> ${m}${dis ? ' <span style="color:var(--error);font-size:11.5px">(رصيد غير كافٍ)</span>' : ''}</label>`; }).join('')}
          <p style="font-size:11.5px;color:var(--text-muted);margin-top:10px;line-height:1.6">يُخصم المبلغ فوراً من محفظتك عند الدفع بالمحفظة. عند الكاش يدفع المشتري للموصل عند الاستلام، وتُحول أجرة التوصيل إلى محفظة الموصل بعد اكتمال التوصيل.</p>
        </div>
        <div class="form-group"><label>ملاحظات (اختياري)</label><textarea id="notes" class="form-input" placeholder="أي ملاحظات للبائع..."></textarea></div>
        <button class="btn btn-primary" onclick="APP.placeOrder(document.querySelector('input[name=pay]:checked')?.value || 'كاش')" style="display:flex;gap:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تأكيد الطلب</button>
        <div style="height:40px"></div>
      </div>`;
  },

  placeOrder(pm) {
    if (this.cart.length === 0) return;
    const total = this.getCartTotal() + 5;
    if (pm === 'محفظة') {
      const bal = this.currentUser.balance || 0;
      if (bal < total) { this.toast('رصيد المحفظة غير كافٍ لتغطية الطلب', 'error'); return; }
      this.currentUser.balance = Math.round((bal - total) * 100) / 100;
    }
    const o = {
      id: 'ORD' + Date.now(), buyerId: this.currentUser.id, buyerName: this.currentUser.name,
      buyerPhone: this.currentUser.phone, buyerAddress: this.currentUser.address, status: 'pending',
      items: this.cart.map(c => { const p = this.products.find(x => x.id === c.productId); return { productId: c.productId, productTitle: p.title, price: p.price, quantity: c.quantity }; }),
      subtotal: this.getCartTotal(), deliveryFee: 5, total,
      paymentMethod: pm, paymentStatus: pm === 'كاش' ? 'pending' : 'paid',
      createdAt: new Date().toISOString(), deliveredAt: null,
    };
    this.orders.unshift(o); this.clearCart(); this.saveAll(); this.navigate('order-success');
  },

  renderOrderSuccess() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    p.innerHTML = `<div class="container"><div class="success-page" style="text-align:center;padding:56px 24px">
      <div class="success-check" style="width:84px;height:84px;border-radius:50%;background:linear-gradient(135deg,var(--gold),var(--gold-2));display:flex;align-items:center;justify-content:center;font-size:34px;color:white;margin:0 auto 18px;box-shadow:0 12px 30px rgba(169,130,60,0.4);animation:zoomIn 0.4s var(--ease-spring)"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></div>
      <h2 style="margin:6px 0 8px;font-size:22px;font-weight:700">تم تأكيد الطلب!</h2>
      <p style="color:var(--text-muted);margin-bottom:28px">جاري البحث عن موصل قريب منك...</p>
      <button class="btn btn-primary" onclick="APP.navigate('home')" style="display:flex;gap:8px"><i class="ph ph-duotone ph-house"></i> العودة للرئيسية</button>
      <button class="btn btn-outline" onclick="APP.navigate('orders')" style="margin-top:10px;display:flex;gap:8px"><i class="ph ph-duotone ph-list"></i> عرض طلباتي</button>
    </div></div>`;
  },

  getOrders() { return this.orders.filter(o => o.buyerId === this.currentUser?.id); },

  cancelOrder(id) {
    const o = this.orders.find(x => x.id === id); if (!o || o.status !== 'pending') return;
    o.status = 'cancelled'; this.saveAll(); this.render(); this.toast('تم إلغاء الطلب', 'info');
  },

  showOrderDetail(id) {
    const o = this.orders.find(x => x.id === id); if (!o) return;
    const statusMap = { pending: 'قيد الانتظار', accepted: 'تم القبول', delivering: 'قيد التوصيل', delivered: 'تم التوصيل', cancelled: 'ملغي' };
    const steps = ['pending', 'accepted', 'delivering', 'delivered'];
    const si = steps.indexOf(o.status);
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:16px">طلب #${o.id.slice(-6)}</h3>
      <div style="display:flex;gap:4px;margin-bottom:20px;padding:0 4px">
        ${steps.map((s, i) => `
          <div style="flex:1;text-align:center">
            <div style="width:26px;height:26px;border-radius:50%;margin:0 auto 5px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;${i <= si ? 'background:linear-gradient(135deg,var(--gold),var(--gold-2));color:white;box-shadow:0 3px 8px rgba(169,130,60,0.35)' : 'background:var(--bg-2);color:var(--text-muted)'}">
              ${i < si ? '<svg class="chk" style="font-size:12px" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg>' : i + 1}
            </div>
            <div style="font-size:9.5px;color:var(--text-muted);line-height:1.2">${statusMap[s]}</div>
          </div>
        `).join('')}
      </div>
      <div class="section" style="margin-bottom:12px">
        <div style="font-size:13px;color:var(--text-muted);margin-bottom:4px">المنتجات</div>
        ${o.items.map(i => `<div style="display:flex;justify-content:space-between;padding:4px 0;font-size:14px"><span>${this.esc(i.productTitle)} × ${i.quantity}</span><span style="font-weight:600">${i.price * i.quantity} ₪</span></div>`).join('')}
        <hr style="border:none;border-top:1px solid var(--line);margin:8px 0">
        <div style="display:flex;justify-content:space-between;font-size:13px"><span>المجموع</span><span>${o.subtotal} ₪</span></div>
        <div style="display:flex;justify-content:space-between;font-size:13px;color:var(--text-muted)"><span>التوصيل</span><span>${o.deliveryFee} ₪</span></div>
        <div style="display:flex;justify-content:space-between;font-size:18px;font-weight:700;color:var(--primary);margin-top:4px"><span>الإجمالي</span><span>${o.total} ₪</span></div>
      </div>
      <div class="section" style="margin-bottom:12px">
        <div style="display:flex;align-items:center;gap:6px;margin-bottom:4px"><i class="ph ph-duotone ph-map-pin" style="color:var(--gold)"></i><span style="font-weight:600">${this.esc(o.buyerName)}</span></div>
        <div style="font-size:13px;color:var(--text-muted)">${this.esc(o.buyerAddress)}</div>
        <div style="font-size:13px;color:var(--text-muted)">${this.esc(o.buyerPhone)}</div>
      </div>
      <div style="display:flex;gap:8px;font-size:13px;color:var(--text-muted);margin-bottom:16px">
        <span>${o.paymentMethod}</span><span>•</span><span>${new Date(o.createdAt).toLocaleDateString('ar-EG')}</span>
      </div>
      ${o.deliveryPersonName ? `<div style="display:flex;align-items:center;gap:6px;padding:11px 14px;background:var(--bg);border-radius:var(--radius-sm);margin-bottom:16px;font-size:14px"><i class="ph ph-duotone ph-moped" style="color:var(--gold)"></i> الموصل: ${this.esc(o.deliveryPersonName)}</div>` : ''}
      ${o.status === 'pending' ? `<button class="btn btn-danger btn-sm" onclick="APP.cancelOrder('${o.id}');APP.closeModal()" style="display:flex;gap:6px"><i class="ph ph-duotone ph-x"></i> إلغاء الطلب</button>` : ''}
    `);
  },

  renderOrders() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none'; const orders = this.getOrders();
    const statusMap = { pending: 'قيد الانتظار', accepted: 'تم القبول', delivering: 'قيد التوصيل', delivered: 'تم التوصيل', cancelled: 'ملغي' };
    const sIcon = { pending: 'ph-clock', accepted: 'chk', delivering: 'ph-moped', delivered: 'chk', cancelled: 'ph-x-circle' };
    const activeCount = orders.filter(o => o.status !== 'delivered' && o.status !== 'cancelled').length;
    p.innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:20px">
          <h2 style="font-size:20px;font-weight:700">طلباتي</h2>
          ${activeCount > 0 ? `<span style="background:var(--gold);color:white;font-size:12px;font-weight:700;padding:3px 11px;border-radius:100px">${activeCount} نشط</span>` : ''}
        </div>
        ${orders.length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-clipboard"></i></div><h3>لا توجد طلبات</h3><p>سوف تظهر طلباتك هنا</p></div>' :
          orders.map(o => `<div class="order-card clickable" onclick="APP.showOrderDetail('${o.id}')">
            <div class="order-top">
              <div class="order-ico"><i class="ph ph-duotone ph-package"></i></div>
              <div class="order-main">
                <div class="order-title">
                  <h4>طلب #${o.id.slice(-6)}</h4>
                  <span class="status-badge status-${o.status}">${sIcon[o.status] === 'chk' ? CHK_SVG : `<i class="ph ph-duotone ${sIcon[o.status] || 'ph-clock'}"></i>`} ${statusMap[o.status] || o.status}</span>
                </div>
                <div class="order-id">${new Date(o.createdAt).toLocaleDateString('ar-EG', { day: 'numeric', month: 'short', year: 'numeric' })} • ${this.timeAgo(o.createdAt)}</div>
              </div>
              <div class="order-amount">${this.fmt(o.total)}</div>
            </div>
            <div class="order-meta">
              <span><i class="ph ph-duotone ph-package"></i> ${o.items.length} منتجات</span>
              <span><i class="ph ph-duotone ph-credit-card"></i> ${o.paymentMethod}</span>
              <span><i class="ph ph-duotone ph-cash-register"></i> ${o.paymentStatus === 'pending' ? 'كاش عند الاستلام' : 'مدفوع'}</span>
            </div>
            ${o.deliveryPersonName ? `<div class="order-delivery"><i class="ph ph-duotone ph-moped"></i> موصل: ${this.esc(o.deliveryPersonName)}</div>` : ''}
            ${o.status === 'pending' ? `<div class="order-actions"><button class="btn btn-danger btn-sm" onclick="event.stopPropagation();APP.cancelOrder('${o.id}')"><i class="ph ph-duotone ph-x"></i> إلغاء الطلب</button></div>` : ''}
          </div>`).join('')
        }
      </div>`;
  },

  renderSaved() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    const items = this.products.filter(x => this.saved.includes(x.id));
    p.innerHTML = `
      <div class="container">
        <h2 class="page-head"><i class="ph ph-duotone ph-bookmark"></i> المفضلة (${items.length})</h2>
        ${items.length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-bookmark"></i></div><h3>لا توجد مفضلات بعد</h3><p>اضغط على أيقونة الحفظ في أي إعلان ليظهر هنا</p><button class="btn btn-primary" style="display:flex;gap:8px" onclick="APP.navigate(\'market\')"><i class="ph ph-duotone ph-storefront"></i> تصفح السوق</button></div>' : `<div class="post-feed">${items.map(x => this.postCard(x)).join('')}</div>`}
      </div>`;
  },

  renderNotifications() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    const u = this.currentUser;
    const notifs = [];
    this.orders.forEach(o => {
      if (o.buyerId === u.id || o.deliveryPersonId === u.id) {
        const mine = o.buyerId === u.id;
        const m = {
          pending: { t: mine ? `طلبك #${o.id} بانتظار موصل` : `طلب جديد #${o.id} بانتظار موصل`, i: 'ph-hourglass', c: 'var(--gold)' },
          accepted: { t: mine ? `تم قبول طلبك #${o.id}` : `قبلت طلب #${o.id}`, i: 'chk', c: 'var(--olive)' },
          delivering: { t: mine ? `موصلك في الطريق — طلب #${o.id}` : `طلبية #${o.id} قيد التوصيل`, i: 'ph-moped', c: 'var(--olive)' },
          delivered: { t: mine ? `تم توصيل طلبك #${o.id} بنجاح` : `تم توصيل طلب #${o.id}`, i: 'chk', c: 'var(--olive)' },
          cancelled: { t: `تم إلغاء طلب #${o.id}`, i: 'ph-x-circle', c: 'var(--error)' },
        }[o.status];
        if (m) notifs.push({ t: m.t, i: m.i, c: m.c, time: o.createdAt });
      }
    });
    this.requests.forEach(r => {
      if (r.userId === u.id && r.offers && r.offers.length) {
        const last = r.offers[r.offers.length - 1];
        notifs.push({ t: `عرض جديد من ${last.offererName} على طلبك «${r.title}»`, i: 'ph-hand-coins', c: 'var(--gold)', time: last.createdAt });
      }
      if (r.offers && r.offers.some(x => x.userId === u.id) && r.status === 'done') {
        notifs.push({ t: `تم إغلاق طلب «${r.title}»`, i: 'chk', c: 'var(--olive)', time: r.createdAt });
      }
    });
    notifs.sort((a, b) => new Date(b.time) - new Date(a.time));
    p.innerHTML = `
      <div class="container">
        <h2 class="page-head"><i class="ph ph-duotone ph-bell"></i> الإشعارات</h2>
        ${notifs.length === 0
          ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-bell"></i></div><h3>لا توجد إشعارات</h3><p>ستظهر هنا تحديثات طلباتك وعروضك</p></div>'
          : `<div class="section" style="padding:6px">${notifs.map(n => `
            <div class="chat-row" style="cursor:default">
              <div class="chat-ava" style="color:${n.c};background:${n.c}1a">${n.i === 'chk' ? CHK_SVG : `<i class="ph ph-duotone ${n.i}"></i>`}</div>
              <div class="chat-main"><b style="font-size:13.5px">${n.t}</b><span>${this.timeAgo(n.time)}</span></div>
            </div>`).join('')}</div>`}
      </div>`;
  },

  renderMessages() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    const convs = [...this.chats].sort((a, c2) => this.lastMsg(c2).time > this.lastMsg(a).time ? 1 : -1);
    p.innerHTML = `
      <div class="container">
        <h2 class="page-head"><i class="ph ph-duotone ph-chats-circle"></i> الرسائل</h2>
        <div class="section">
          ${convs.length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-chats-circle"></i></div><h3>لا توجد محادثات بعد</h3><p>اضغط على «تواصل» في أي إعلان أو خدمة لبدء محادثة</p></div>' :
            convs.map(c => this.convRow(c)).join('')}
        </div>
      </div>`;
  },

  unreadChats() { return this.chats.reduce((s, c) => s + (c.unread || 0), 0); },

  lastMsg(c) { return c.messages[c.messages.length - 1] || { from: 'them', text: '', time: 0 }; },

  chatTime(iso) {
    if (!iso) return '';
    const d = new Date(iso), now = new Date();
    if (isNaN(d)) return '';
    if (d.toDateString() === now.toDateString()) return d.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' });
    if (d.getFullYear() === now.getFullYear()) return d.toLocaleDateString('ar-EG', { day: 'numeric', month: 'short' });
    return d.toLocaleDateString('ar-EG', { day: 'numeric', month: 'short', year: 'numeric' });
  },

  convRow(c) {
    const lm = this.lastMsg(c);
    const preview = lm.text ? (lm.from === 'me' ? 'أنت: ' + lm.text : lm.text) : 'لا توجد رسائل بعد';
    return `<div class="chat-row" onclick="APP.openChat('${this.esc(c.name)}')">
      <div class="chat-ava"><i class="ph ph-duotone ${c.icon || 'ph-user-circle'}"></i></div>
      <div class="chat-main"><b>${this.esc(c.name)}</b><span class="${c.unread ? 'chat-preview unread' : 'chat-preview'}">${this.esc(preview)}</span></div>
      <div class="chat-side"><span class="chat-time">${this.chatTime(lm.time)}</span>${c.unread ? `<span class="chat-unread">${c.unread > 9 ? '9+' : c.unread}</span>` : ''}</div>
    </div>`;
  },

  ensureChat(name) {
    let c = this.chats.find(x => x.name === name);
    if (!c) {
      const p = this.products.find(x => x.sellerName === name);
      const sv = this.services.find(x => x.providerName === name);
      const d = this.users.find(x => x.name === name);
      c = {
        id: 'c' + Date.now(), name,
        role: p ? 'بائع' : sv ? 'مقدم خدمة' : (d && d.userType === 'delivery') ? 'موصل' : 'عضو في حارتك',
        icon: p ? 'ph-storefront' : sv ? 'ph-wrench' : (d && d.userType === 'delivery') ? 'ph-moped' : 'ph-user-circle',
        unread: 0, messages: []
      };
      this.chats.push(c); this.saveAll();
    }
    return c;
  },

  startChat(name, ctx) {
    const c = this.ensureChat(name);
    if (ctx && c.messages.length === 0) {
      c.messages.push({ from: 'me', text: ctx, time: new Date().toISOString() });
      this.saveAll();
    }
    this.openChat(name);
  },

  openChat(name) {
    const c = this.ensureChat(name);
    if (c) { c.unread = 0; this.saveAll(); }
    this._chatName = name;
    this.navigate('chat');
  },

  renderChat() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    const name = this._chatName || (this.chats[0] && this.chats[0].name) || '';
    const c = name ? this.ensureChat(name) : { name: '', role: '', icon: 'ph-user-circle', messages: [] };
    if (!name) { p.innerHTML = '<div class="container"><div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-chats-circle"></i></div><h3>لا توجد محادثات</h3><p>ابدأ محادثة من أي إعلان أو خدمة</p><button class="btn btn-primary" style="display:flex;gap:8px" onclick="APP.navigate(\'messages\')"><i class="ph ph-duotone ph-arrow-right"></i> الرجوع للرسائل</button></div></div>'; return; }
    p.innerHTML = `
      <div class="chat-page">
        <div class="chat-head">
          <button class="icon-btn chat-back" onclick="APP.navigate('messages')"><i class="ph ph-duotone ph-arrow-right"></i></button>
          <div class="chat-head-ava"><i class="ph ph-duotone ${c.icon || 'ph-user-circle'}"></i></div>
          <div class="chat-head-info"><b>${this.esc(name)}</b><span>${c.role || ''}</span></div>
        </div>
        <div class="chat-body" id="chat-body">
          ${c.messages.length === 0 ? '<div class="chat-empty">ابدأ المحادثة — قل مرحباً 👋</div>' :
            c.messages.map(m => `<div class="msg ${m.from === 'me' ? 'sent' : 'recv'}"><div class="msg-bubble">${m.img ? `<img class="msg-img" src="${m.img}" alt="صورة" onclick="APP.showImage(this.src)">` : ''}${m.text ? this.esc(m.text) : ''}<span class="msg-time">${this.chatTime(m.time)}</span></div></div>`).join('')}
        </div>
        <div class="chat-composer">
          <input type="file" id="chat-file" accept="image/*" hidden onchange="APP.sendChatImage(this)">
          <button class="chat-attach" onclick="document.getElementById('chat-file').click()"><i class="ph ph-duotone ph-image"></i></button>
          <input id="chat-input" class="form-input chat-input" placeholder="اكتب رسالتك..." autocomplete="off" onkeydown="if(event.key==='Enter'){event.preventDefault();APP.sendChat()}">
          <button class="chat-send" onclick="APP.sendChat()"><i class="ph ph-duotone ph-paper-plane-tilt"></i></button>
        </div>
      </div>`;
    setTimeout(() => {
      const body = document.getElementById('chat-body');
      if (body) body.scrollTop = body.scrollHeight;
      const inp = document.getElementById('chat-input');
      if (inp) inp.focus();
    }, 30);
  },

  sendChat() {
    const inp = document.getElementById('chat-input');
    const name = this._chatName;
    if (!inp || !name) return;
    const text = inp.value.trim();
    if (!text) return;
    const c = this.ensureChat(name);
    c.messages.push({ from: 'me', text, time: new Date().toISOString() });
    this.saveAll();
    this.renderChat();
    this.autoReply(c);
  },

  sendChatImage(input) {
    const name = this._chatName;
    if (!input || !input.files || !input.files[0] || !name) return;
    const file = input.files[0];
    if (!file.type.startsWith('image/')) { this.toast('اختر صورة فقط', 'error'); input.value = ''; return; }
    const reader = new FileReader();
    reader.onload = e => {
      const img = new Image();
      img.onload = () => {
        const max = 900;
        let w = img.width, h = img.height;
        if (w > max || h > max) { const sc = Math.min(max / w, max / h); w = Math.round(w * sc); h = Math.round(h * sc); }
        const cv = document.createElement('canvas');
        cv.width = w; cv.height = h;
        cv.getContext('2d').drawImage(img, 0, 0, w, h);
        const c = this.ensureChat(name);
        c.messages.push({ from: 'me', text: '', img: cv.toDataURL('image/jpeg', 0.82), time: new Date().toISOString() });
        this.saveAll();
        this.renderChat();
        this.autoReply(c, true);
      };
      img.src = e.target.result;
    };
    reader.readAsDataURL(file);
    input.value = '';
  },

  showImage(src) {
    const v = document.createElement('div');
    v.className = 'img-view';
    v.onclick = () => v.remove();
    v.innerHTML = `<img src="${src}" alt="صورة"><button class="img-close" aria-label="إغلاق"><i class="ph ph-duotone ph-x"></i></button>`;
    document.body.appendChild(v);
    requestAnimationFrame(() => v.classList.add('show'));
  },

  autoReply(c, isImg) {
    const replies = [
      'تمام، استلمت رسالتك 👍',
      'حاضر، أنا متواجد حالياً.',
      'حسناً، سأراجع الأمر وأرد عليك خلال وقت قصير.',
      'ممكن نتفق على التفاصيل بشكل أدق؟',
      'يسعدني التعامل معك، سأجهز لك كل شيء.',
    ];
    const imgReplies = [
      'وصلتني الصورة، تبدو رائعة 👌',
      'شكراً على الصورة، تمام معي.',
      'الصورة واضحة، سأتابع معك قريباً.',
      'تسلمت الصورة، لي رجعة بعد معاينتها.',
    ];
    const arr = isImg ? imgReplies : replies;
    const r = arr[Math.floor(Math.random() * arr.length)];
    setTimeout(() => {
      if (this._chatName !== c.name) return;
      c.messages.push({ from: 'them', text: r, time: new Date().toISOString() });
      c.unread = 0;
      this.saveAll();
      this.renderChat();
    }, 1400);
  },

  /* ================= DELIVERY ================= */
  renderDelivery() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none'; const u = this.currentUser;
    if (!u.deliveryAreas || u.deliveryAreas.length === 0) { this.renderDeliveryRegister(); return; }
    const pending = this.orders.filter(o => o.status === 'pending');
    const my = this.orders.filter(o => o.deliveryPersonId === u.id);
    const active = my.filter(o => o.status === 'accepted' || o.status === 'delivering');
    const done = my.filter(o => o.status === 'delivered');
    const statusMap = { accepted: 'تم القبول', delivering: 'قيد التوصيل', delivered: 'تم التوصيل' };
    p.innerHTML = `
      <div class="container">
        <div class="section" style="text-align:center;padding:22px;margin-bottom:16px">
          <div style="font-size:38px;color:var(--gold);margin-bottom:8px"><i class="ph ph-duotone ph-moped"></i></div>
          <div style="font-size:18px;font-weight:700">${this.esc(u.name)}</div>
          <div style="font-size:13px;color:var(--text-muted);margin-top:3px">${u.deliveryAreas.join('، ')} • ${u.vehicleType}</div>
          <div style="display:flex;justify-content:center;gap:10px;margin-top:12px;flex-wrap:wrap">
            <span class="tag ${u.available ? 'tag-green' : 'tag-red'}">${u.available ? 'متاح للتوصيل' : 'غير متاح حالياً'}</span>
            <span class="tag tag-accent"><i class="ph ph-duotone ph-star"></i> ${u.rating || 0} (${u.ratingCount || 0})</span>
            <span class="tag tag-olive"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> ${done.length} منجز</span>
          </div>
          <div style="display:flex;justify-content:center;gap:8px;margin-top:12px">
            <button class="btn ${u.available ? 'btn-danger' : 'btn-primary'} btn-sm" onclick="APP.toggleAvailability()" style="display:flex;gap:5px"><i class="ph ph-duotone ph-power"></i> ${u.available ? 'إيقاف التوفر' : 'تفعيل التوفر'}</button>
          </div>
        </div>

        <div class="section" style="padding:16px;margin-bottom:16px">
          <div class="section-head"><h3><i class="ph ph-duotone ph-map-pin"></i> مناطق التوصيل</h3></div>
          <div style="display:flex;flex-wrap:wrap;gap:8px">
            ${u.deliveryAreas.map(a => `<span class="tag tag-slate" style="font-size:12px;padding:6px 13px">${a}</span>`).join('')}
          </div>
          <div style="display:flex;gap:14px;margin-top:12px;font-size:13px;color:var(--text-muted)">
            <span><i class="ph ph-duotone ph-currency-dollar" style="color:var(--gold)"></i> الأجرة: <b style="color:var(--primary)">${u.deliveryFee} ₪</b></span>
            <span><i class="ph ph-duotone ph-clock" style="color:var(--gold)"></i> ${u.workHours || 'غير محدد'}</span>
          </div>
        </div>

        <div class="section">
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px">
            <div style="flex:1;height:1px;background:var(--line)"></div>
            <span style="font-size:13px;font-weight:600;color:var(--text-muted);white-space:nowrap">طلبات متاحة</span>
            ${pending.length > 0 ? `<span style="background:var(--gold);color:white;font-size:11px;font-weight:700;min-width:20px;height:20px;border-radius:10px;display:flex;align-items:center;justify-content:center">${pending.length}</span>` : ''}
            <div style="flex:1;height:1px;background:var(--line)"></div>
          </div>
          ${pending.length === 0 ? '<p style="color:var(--text-light);text-align:center;font-size:14px;padding:8px 0">لا توجد طلبات متاحة</p>' :
            pending.map(o => `<div class="order-card" style="margin-bottom:10px">
              <div style="display:flex;justify-content:space-between;align-items:flex-start">
                <div>
                  <div style="font-weight:700;font-size:14px">${this.esc(o.buyerName)}</div>
                  <div style="font-size:12px;color:var(--text-muted);margin-top:2px">${this.esc(o.buyerAddress)}</div>
                </div>
                <span style="font-weight:700;font-size:18px;color:var(--primary)">${this.fmt(o.total)}</span>
              </div>
              <div style="font-size:12px;color:var(--text-muted);margin:6px 0">${o.items.length} منتجات • ${this.esc(o.buyerPhone)}</div>
              <button class="btn btn-primary btn-sm" onclick="APP.acceptDeliveryOrder('${o.id}')" style="display:flex;gap:6px;width:100%;margin-top:4px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> قبول الطلب</button>
            </div>`).join('')
          }
        </div>

        <div class="section" style="margin-top:16px">
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px">
            <div style="flex:1;height:1px;background:var(--line)"></div>
            <span style="font-size:13px;font-weight:600;color:var(--text-muted);white-space:nowrap">طلباتي كموصل</span>
            ${active.length > 0 ? `<span style="background:var(--primary);color:white;font-size:11px;font-weight:700;min-width:20px;height:20px;border-radius:10px;display:flex;align-items:center;justify-content:center">${active.length}</span>` : ''}
            <div style="flex:1;height:1px;background:var(--line)"></div>
          </div>
          ${my.length === 0 ? '<p style="color:var(--text-light);text-align:center;font-size:14px;padding:8px 0">لا توجد طلبات بعد</p>' :
            my.map(o => `<div class="order-card" style="margin-bottom:10px">
              <div style="display:flex;justify-content:space-between;align-items:flex-start">
                <div>
                  <div style="font-weight:700;font-size:14px">${this.esc(o.buyerName)}</div>
                  <div style="font-size:12px;color:var(--text-muted);margin-top:2px">${this.esc(o.buyerAddress)}</div>
                </div>
                <span class="status-badge status-${o.status}">${statusMap[o.status] || o.status}</span>
              </div>
              <div style="font-size:12px;color:var(--text-muted);margin:6px 0"><span style="font-weight:600;color:var(--primary)">${o.total} ₪</span> • ${o.paymentMethod} • ${o.items.length} منتجات</div>
              ${o.status === 'accepted' ? `<button class="btn btn-primary btn-sm" onclick="APP.updateOrderStatus('${o.id}','delivering')" style="display:flex;gap:6px;width:100%"><i class="ph ph-duotone ph-truck"></i> بدء التوصيل</button>` : ''}
              ${o.status === 'delivering' ? `<button class="btn btn-primary btn-sm" onclick="APP.updateOrderStatus('${o.id}','delivered')" style="display:flex;gap:6px;width:100%"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تم التوصيل</button>` : ''}
              ${o.status === 'delivered' ? `<div style="margin-top:6px;font-size:12px;color:var(--text-muted);display:flex;align-items:center;gap:4px"><svg class="chk" style="color:var(--gold)" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تم التوصيل ${o.deliveredAt ? new Date(o.deliveredAt).toLocaleDateString('ar-EG') : ''}</div>` : ''}
            </div>`).join('')
          }
        </div>
      </div>`;
  },

  toggleAvailability() {
    const u = this.currentUser;
    u.available = !u.available;
    const i = this.users.findIndex(x => x.id === u.id); if (i >= 0) this.users[i] = u;
    this.saveAll(); this.render();
    this.toast(u.available ? 'أصبحت متاحاً للتوصيل' : 'أوقفت استقبال الطلبات', u.available ? 'success' : 'info');
  },

  acceptDeliveryOrder(id) {
    const o = this.orders.find(x => x.id === id); if (!o) return;
    o.status = 'accepted'; o.deliveryPersonId = this.currentUser.id; o.deliveryPersonName = this.currentUser.name;
    this.saveAll(); this.render(); this.toast('تم قبول الطلب', 'success');
  },

  updateOrderStatus(id, s) {
    const o = this.orders.find(x => x.id === id); if (!o) return;
    o.status = s;
    if (s === 'delivered') {
      o.deliveredAt = new Date().toISOString();
      const d = this.users.find(x => x.id === o.deliveryPersonId);
      if (d) d.balance = Math.round(((d.balance || 0) + o.deliveryFee) * 100) / 100;
    }
    this.saveAll(); this.render();
    if (s === 'delivered') this.toast('تم التوصيل — أُضيفت أجرة التوصيل إلى محفظتك', 'success');
  },

  renderDeliveryRegister() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    p.innerHTML = `
      <div class="container">
        <div style="text-align:center;padding:20px 0">
          <div style="font-size:44px;color:var(--gold);margin-bottom:8px"><i class="ph ph-duotone ph-moped"></i></div>
          <h2 style="font-size:20px;font-weight:700">انضم لفريق التوصيل</h2>
          <p style="color:var(--text-muted);font-size:14px;margin-top:4px">وفر خدمات التوصيل في منطقتك واربح</p>
        </div>
        <form onsubmit="event.preventDefault();APP.handleDeliveryRegister()">
          <div class="form-group"><label>مناطق التوصيل <span class="req">*</span></label><input id="dareas" class="form-input" placeholder="رام الله, البيرة, نابلس" required></div>
          <div class="form-group"><label>أجرة التوصيل (شيكل)</label><input id="dfee" class="form-input" type="number" value="7"></div>
          <div class="form-group"><label>المركبة</label><select id="dvehicle" class="form-input"><option value="دراجة">دراجة</option><option value="سيارة">سيارة</option><option value="شاحنة">شاحنة</option></select></div>
          <button class="btn btn-primary" type="submit" style="display:flex;gap:8px;margin-top:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تسجيل كموصل</button>
        </form>
      </div>`;
  },

  handleDeliveryRegister() {
    const u = this.currentUser;
    u.deliveryAreas = document.getElementById('dareas').value.split(',').map(s => s.trim()).filter(Boolean);
    u.deliveryFee = parseFloat(document.getElementById('dfee').value) || 7;
    u.vehicleType = document.getElementById('dvehicle').value;
    u.available = true; u.workHours = '8 ص - 8 م';
    const i = this.users.findIndex(x => x.id === u.id); if (i >= 0) this.users[i] = u;
    this.saveAll(); this.navigate('delivery'); this.toast('تم التسجيل كموصل', 'success');
  },

  /* ================= ADMIN ================= */
  renderAdmin() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none';
    if (this.currentUser?.userType !== 'admin') { p.innerHTML = '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-prohibit"></i></div><h3>غير مصرح</h3></div>'; return; }
    const statusMap = { pending: 'قيد الانتظار', accepted: 'تم القبول', delivering: 'قيد التوصيل', delivered: 'تم التوصيل', cancelled: 'ملغي' };
    const revenue = this.orders.filter(o => o.status === 'delivered').reduce((s, o) => s + (o.total || 0), 0);
    p.innerHTML = `
      <div class="container">
        <div class="card" style="background:linear-gradient(135deg,var(--primary),var(--primary-deep));color:white;text-align:center;padding:22px;border-radius:var(--radius-lg);margin-bottom:18px">
          <h2 style="display:flex;align-items:center;justify-content:center;gap:8px;font-size:19px"><i class="ph ph-duotone ph-shield-check"></i> لوحة الإدارة</h2>
          <p style="opacity:0.8;font-size:13px;margin-top:4px">مرحباً، ${this.esc(this.currentUser.name)}</p></div>
        <div class="stat-grid cols3">
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-users"></i></div><div class="stat-number">${this.users.length}</div><div class="stat-label">المستخدمين</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-user-circle"></i></div><div class="stat-number">${this.users.filter(u => u.userType === 'regular').length}</div><div class="stat-label">المستخدمين العاديين</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-moped"></i></div><div class="stat-number">${this.users.filter(u => u.userType === 'delivery').length}</div><div class="stat-label">الموصلين</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-package"></i></div><div class="stat-number">${this.products.length}</div><div class="stat-label">المنتجات</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-wrench"></i></div><div class="stat-number">${this.services.length}</div><div class="stat-label">الخدمات</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-briefcase"></i></div><div class="stat-number">${this.jobs.length}</div><div class="stat-label">الوظائف</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-megaphone"></i></div><div class="stat-number">${this.requests.length}</div><div class="stat-label">الطلبات المنشورة</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-clipboard-text"></i></div><div class="stat-number">${this.orders.length}</div><div class="stat-label">الطلبات</div></div>
          <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-currency-dollar"></i></div><div class="stat-number">${revenue} ₪</div><div class="stat-label">إيرادات مُنجزة</div></div>
        </div>
        <h3 style="margin:22px 0 12px;display:flex;align-items:center;gap:6px;font-size:16px"><i class="ph ph-duotone ph-list-bullets" style="color:var(--gold)"></i> جميع الطلبات</h3>
        ${this.orders.length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-clipboard-text"></i></div><h3>لا توجد طلبات</h3></div>' :
          this.orders.map(o => `<div class="order-card"><div class="order-header"><div><h4>${this.esc(o.buyerName)}</h4><div class="order-id">#${o.id.slice(-6)}</div></div><span class="status-badge status-${o.status}">${statusMap[o.status] || o.status}</span></div>
            <div style="font-size:13px;color:var(--text-muted)">${o.total} ₪ | ${o.paymentMethod}</div>
            ${o.deliveryPersonName ? `<div style="font-size:13px;color:var(--gold);display:flex;align-items:center;gap:4px"><i class="ph ph-duotone ph-moped"></i> ${this.esc(o.deliveryPersonName)}</div>` : ''}</div>`).join('')
        }
      </div>`;
  },

  /* ================= SERVICES ================= */
  renderServices() {
    const p = document.getElementById('page-content');
    const q = document.getElementById('sv-search')?.value || '';
    let list = this.services;
    if (q) list = list.filter(s => s.title.includes(q) || s.category.includes(q) || s.providerName.includes(q) || (s.areas || []).join('').includes(q));
    const cats = ['الكل', 'مصمم', 'مصور', 'مدرس', 'كهربائي', 'سباك', 'نجار', 'ميكانيكي', 'مبرمج', 'مترجم', 'كاتب محتوى', 'مسوق إلكتروني', 'مونتير', 'أخرى'];
    p.innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px">
          <h2 style="font-size:20px;font-weight:700;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-wrench" style="color:var(--olive)"></i> الخدمات</h2>
          <button class="btn btn-primary btn-sm" onclick="APP.navigate('new-service')" style="display:flex;gap:6px"><i class="ph ph-duotone ph-plus-circle"></i> قدّم خدمة</button>
        </div>
        <div class="search-box">
          <span class="icon"><i class="ph ph-duotone ph-magnifying-glass"></i></span>
          <input id="sv-search" placeholder="ابحث عن خدمة أو منطقة..." oninput="APP.renderServices()">
        </div>
        <div class="category-scroll">
          ${cats.map(c => `<button class="category-chip ${this._svCat === c ? 'active' : ''}" onclick="APP._svCat='${c}';APP.renderServices()">${c}</button>`).join('')}
        </div>
        ${(this._svCat && this._svCat !== 'الكل' ? list = list.filter(s => s.category === this._svCat) : list).length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-wrench"></i></div><h3>لا توجد خدمات</h3></div>' :
          list.map(s => this.serviceListItem(s)).join('')}
      </div>`;
  },

  serviceListItem(s) {
    const c = this.catStyle('خدمات');
    return `<div class="svc-card" onclick="APP.showServiceDetail('${s.id}')">
      <div class="svc-head">
        <div class="svc-ico" style="background:${this.grad(c)}"><i class="${c.icon}"></i></div>
        <div class="svc-meta">
          <h4>${this.esc(s.title)}${s.verified ? '<span class="verified"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></span>' : ''}</h4>
          <div class="sub"><i class="ph ph-duotone ph-user"></i> ${this.esc(s.providerName)} <span class="tag tag-olive">${s.category}</span></div>
        </div>
        <div class="svc-price"><b>${s.price} ₪</b><small><span class="rating-stars">${this.stars(s.rating)}</span></small></div>
      </div>
      <div class="svc-desc">${this.esc(s.description)}</div>
      <div class="svc-meta-row">
        <span><i class="ph ph-duotone ph-map-pin"></i> ${(s.areas || []).join('، ')}</span>
        <span><i class="ph ph-duotone ph-clock"></i> ${s.workHours}</span>
        <span><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> ${s.completedJobs || 0} أعمال</span>
      </div>
      <div class="svc-actions">
        <button class="btn btn-primary btn-sm" style="flex:1;display:flex;gap:5px" onclick="event.stopPropagation();APP.requestService('${s.id}')"><i class="ph ph-duotone ph-shopping-bag-open"></i> اطلب الخدمة</button>
        <button class="btn btn-outline btn-sm" style="flex:1;display:flex;gap:5px" onclick="event.stopPropagation();APP.startChat('${this.esc(s.providerName)}','بخصوص خدمتك: ${this.esc(s.title)}')"><i class="ph ph-duotone ph-chats-circle"></i> تواصل</button>
      </div>
    </div>`;
  },

  showServiceDetail(id) {
    const s = this.services.find(x => x.id === id); if (!s) return;
    const c = this.catStyle('خدمات');
    this.showModal(`
      <div class="modal-handle"></div>
      <div style="display:flex;align-items:center;gap:13px;margin-bottom:14px">
        <div style="width:58px;height:58px;border-radius:16px;background:${this.grad(c)};display:flex;align-items:center;justify-content:center;font-size:26px;color:#fff;flex-shrink:0"><i class="${c.icon}"></i></div>
        <div><h3 style="font-size:18px;font-weight:700">${this.esc(s.title)}${s.verified ? '<span class="verified"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></span>' : ''}</h3>
        <div style="font-size:13px;color:var(--text-muted);margin-top:2px"><i class="ph ph-duotone ph-user"></i> ${this.esc(s.providerName)} • <span class="tag tag-olive">${s.category}</span></div></div>
      </div>
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px;flex-wrap:wrap">
        <div style="font-size:24px;font-weight:700;color:var(--primary)">${s.price} ₪</div>
        <div class="rating-stars">${this.stars(s.rating)} <span style="color:var(--text-muted);font-size:12.5px">${s.rating} (${s.ratingCount} تقييم)</span></div>
      </div>
      <div class="section" style="margin-bottom:12px"><div class="detail-desc">${this.esc(s.description)}</div></div>
      <div class="meta-list" style="margin-bottom:16px">
        <div><i class="ph ph-duotone ph-map-pin"></i> ${(s.areas || []).join('، ')}</div>
        <div><i class="ph ph-duotone ph-clock"></i> ${s.workHours}</div>
        <div><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> ${s.completedJobs || 0} أعمال منجزة</div>
      </div>
      <button class="btn btn-primary" style="display:flex;gap:8px;margin-bottom:8px" onclick="APP.closeModal();APP.requestService('${s.id}')"><i class="ph ph-duotone ph-shopping-bag-open"></i> اطلب هذه الخدمة</button>
      <button class="btn btn-outline" style="display:flex;gap:8px" onclick="APP.closeModal();APP.startChat('${this.esc(s.providerName)}','بخصوص خدمتك: ${this.esc(s.title)}')"><i class="ph ph-duotone ph-chats-circle"></i> تواصل مع مقدم الخدمة</button>
    `);
  },

  requestService(id) {
    const s = this.services.find(x => x.id === id); if (!s) return;
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:4px">طلب خدمة</h3>
      <p style="font-size:13px;color:var(--text-muted);margin-bottom:16px">«${this.esc(s.title)}» — ${this.esc(s.providerName)}</p>
      <div class="form-group"><label>تفاصيل طلبك</label><textarea id="sreq-msg" class="form-input" placeholder="اشرح ما تحتاجه بالضبط..."></textarea></div>
      <button class="btn btn-primary" style="display:flex;gap:8px" onclick="APP.submitServiceRequest('${s.id}')"><i class="ph ph-duotone ph-paper-plane-tilt"></i> إرسال الطلب</button>
    `);
  },

  submitServiceRequest(id) {
    const s = this.services.find(x => x.id === id); if (!s) return;
    const u = this.currentUser;
    this.requests.unshift({
      id: 'rq' + Date.now(), userId: u.id, userName: u.name,
      title: `طلب خدمة: ${s.title}`, category: s.category,
      description: document.getElementById('sreq-msg').value || `أريد حجز خدمة «${s.title}» من ${s.providerName}`,
      status: 'open', offers: [], createdAt: new Date().toISOString(),
    });
    this.saveAll(); this.closeModal(); this.navigate('requests');
    this.toast('تم إرسال طلب الخدمة', 'success');
  },

  renderNewService() {
    document.getElementById('page-content').innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:20px">
          <button class="icon-btn" style="width:38px;height:38px" onclick="APP.navigate('services')"><i class="ph ph-duotone ph-arrow-right"></i></button>
          <h2 style="font-size:19px;font-weight:700;flex:1">قدّم خدمة جديدة</h2>
        </div>
        <form onsubmit="event.preventDefault();APP.handleNewService()">
          <div class="form-group"><label>عنوان الخدمة <span class="req">*</span></label><input id="s-title" class="form-input" placeholder="مثال: تدريس رياضيات" required></div>
          <div class="form-group"><label>التصنيف</label><select id="s-cat" class="form-input"><option value="مصمم">مصمم</option><option value="مصور">مصور</option><option value="مدرس">مدرس</option><option value="كهربائي">كهربائي</option><option value="سباك">سباك</option><option value="نجار">نجار</option><option value="ميكانيكي">ميكانيكي</option><option value="مبرمج">مبرمج</option><option value="مترجم">مترجم</option><option value="كاتب محتوى">كاتب محتوى</option><option value="مسوق إلكتروني">مسوق إلكتروني</option><option value="مونتير">مونتير</option><option value="أخرى">أخرى</option></select></div>
          <div class="form-group"><label>وصف الخدمة وخبراتك</label><textarea id="s-desc" class="form-input" placeholder="اشرح خبرتك، مجالات عملك، مدة التنفيذ..."></textarea></div>
          <div class="filter-grid">
            <div class="form-group"><label>السعر (شيكل) <span class="req">*</span></label><input id="s-price" class="form-input" type="number" placeholder="0" required></div>
            <div class="form-group"><label>ساعات العمل</label><input id="s-hours" class="form-input" placeholder="9 ص - 6 م"></div>
          </div>
          <div class="form-group"><label>المناطق (افصل بفاصلة)</label><input id="s-areas" class="form-input" placeholder="رام الله, البيرة, نابلس"></div>
          <button class="btn btn-primary" type="submit" style="display:flex;gap:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> نشر الخدمة</button>
        </form>
      </div>`;
  },

  handleNewService() {
    const sv = {
      id: 'sv' + Date.now(), userId: this.currentUser.id, providerName: this.currentUser.name,
      title: document.getElementById('s-title').value, category: document.getElementById('s-cat').value,
      description: document.getElementById('s-desc').value,
      price: parseFloat(document.getElementById('s-price').value) || 0,
      areas: document.getElementById('s-areas').value.split(',').map(s => s.trim()).filter(Boolean),
      workHours: document.getElementById('s-hours').value || 'غير محدد',
      rating: 0, ratingCount: 0, completedJobs: 0, verified: this.currentUser.verified,
      createdAt: new Date().toISOString(),
    };
    this.services.unshift(sv); this.saveAll(); this.navigate('services');
    this.toast('تم نشر خدمتك', 'success');
  },

  /* ================= JOBS ================= */
  renderJobs() {
    const p = document.getElementById('page-content');
    const q = document.getElementById('jb-search')?.value || '';
    let list = this.jobs;
    if (q) list = list.filter(j => j.title.includes(q) || j.companyName.includes(q) || (j.city || '').includes(q));
    const types = ['الكل', 'دوام كامل', 'دوام جزئي', 'عمل حر', 'عن بعد', 'تدريب', 'مؤقت'];
    p.innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px">
          <h2 style="font-size:20px;font-weight:700;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-briefcase" style="color:var(--olive)"></i> الوظائف</h2>
          <button class="btn btn-primary btn-sm" onclick="APP.navigate('new-job')" style="display:flex;gap:6px"><i class="ph ph-duotone ph-plus-circle"></i> انشر وظيفة</button>
        </div>
        <div class="search-box">
          <span class="icon"><i class="ph ph-duotone ph-magnifying-glass"></i></span>
          <input id="jb-search" placeholder="ابحث عن وظيفة أو جهة..." oninput="APP.renderJobs()">
        </div>
        <div class="category-scroll">
          ${types.map(t => `<button class="category-chip ${this._jbType === t ? 'active' : ''}" onclick="APP._jbType='${t}';APP.renderJobs()">${t}</button>`).join('')}
        </div>
        ${(this._jbType && this._jbType !== 'الكل' ? list = list.filter(j => j.type === this._jbType) : list).length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-briefcase"></i></div><h3>لا توجد وظائف</h3></div>' :
          list.map(j => this.jobListItem(j)).join('')}
      </div>`;
  },

  jobListItem(j) {
    const typeTag = { 'دوام كامل': 'tag-olive', 'دوام جزئي': 'tag-slate', 'عمل حر': 'tag-blue', 'عن بعد': 'tag-blue', 'تدريب': 'tag-slate', 'مؤقت': 'tag-red' };
    const applied = (j.applicants || []).some(a => a.id === this.currentUser?.id);
    return `<div class="job-card" onclick="APP.showJobDetail('${j.id}')">
      <div class="job-head">
        <div class="job-ico"><i class="ph ph-duotone ph-buildings"></i></div>
        <div class="job-meta">
          <h4>${this.esc(j.title)}</h4>
          <div class="sub"><i class="ph ph-duotone ph-buildings"></i> ${this.esc(j.companyName)} <span class="tag ${typeTag[j.type] || 'tag-slate'}">${j.type}</span></div>
        </div>
        <div class="job-salary"><b>${j.salary}</b><small>${this.timeAgo(j.createdAt)}</small></div>
      </div>
      <div class="job-desc">${this.esc(j.description)}</div>
      <div class="job-meta-row">
        <span><i class="ph ph-duotone ph-map-pin"></i> ${this.esc(j.city)}</span>
        <span><i class="ph ph-duotone ph-graduation-cap"></i> ${this.esc(j.experience)}</span>
        <span><i class="ph ph-duotone ph-stack"></i> ${(j.skills || []).slice(0, 3).join('، ')}</span>
      </div>
      <div class="job-actions">
        <button class="btn ${applied ? 'btn-soft' : 'btn-primary'} btn-sm" style="flex:1;display:flex;gap:5px" onclick="event.stopPropagation();APP.applyJob('${j.id}')">${applied ? '<svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تم التقديم' : '<i class="ph ph-duotone ph-paper-plane-tilt"></i> قدّم الآن'}</button>
      </div>
    </div>`;
  },

  showJobDetail(id) {
    const j = this.jobs.find(x => x.id === id); if (!j) return;
    const typeTag = { 'دوام كامل': 'tag-olive', 'دوام جزئي': 'tag-slate', 'عمل حر': 'tag-blue', 'عن بعد': 'tag-blue', 'تدريب': 'tag-slate', 'مؤقت': 'tag-red' };
    const applied = (j.applicants || []).some(a => a.id === this.currentUser?.id);
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:4px">${this.esc(j.title)}</h3>
      <div style="font-size:13px;color:var(--text-muted);margin-bottom:10px"><i class="ph ph-duotone ph-buildings"></i> ${this.esc(j.companyName)} • <span class="tag ${typeTag[j.type] || 'tag-slate'}">${j.type}</span></div>
      <div style="font-size:22px;font-weight:700;color:var(--primary);margin-bottom:14px">${j.salary}</div>
      <div class="section" style="margin-bottom:12px"><div class="detail-desc">${this.esc(j.description)}</div></div>
      <div class="meta-list" style="margin-bottom:16px">
        <div><i class="ph ph-duotone ph-map-pin"></i> ${this.esc(j.city)}</div>
        <div><i class="ph ph-duotone ph-graduation-cap"></i> ${this.esc(j.experience)}</div>
        <div><i class="ph ph-duotone ph-stack"></i> ${(j.skills || []).join('، ')}</div>
        <div><i class="ph ph-duotone ph-clock"></i> نُشر ${this.timeAgo(j.createdAt)}</div>
      </div>
      <button class="btn ${applied ? 'btn-soft' : 'btn-primary'}" style="display:flex;gap:8px" onclick="APP.applyJob('${j.id}')">${applied ? '<svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تم تقديمك على هذه الوظيفة' : '<i class="ph ph-duotone ph-paper-plane-tilt"></i> قدّم على هذه الوظيفة'}</button>
    `);
  },

  applyJob(id) {
    const j = this.jobs.find(x => x.id === id); if (!j) return;
    if ((j.applicants || []).some(a => a.id === this.currentUser?.id)) { this.toast('قمت بالتقديم مسبقاً', 'info'); return; }
    j.applicants = j.applicants || [];
    j.applicants.push({ id: this.currentUser.id, name: this.currentUser.name, appliedAt: new Date().toISOString() });
    this.saveAll(); this.closeModal(); this.render(); this.toast('تم تقديمك على الوظيفة 🎉', 'success');
  },

  renderNewJob() {
    document.getElementById('page-content').innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:20px">
          <button class="icon-btn" style="width:38px;height:38px" onclick="APP.navigate('jobs')"><i class="ph ph-duotone ph-arrow-right"></i></button>
          <h2 style="font-size:19px;font-weight:700;flex:1">نشر وظيفة جديدة</h2>
        </div>
        <form onsubmit="event.preventDefault();APP.handleNewJob()">
          <div class="form-group"><label>اسم الجهة/الشركة <span class="req">*</span></label><input id="j-company" class="form-input" required></div>
          <div class="form-group"><label>عنوان الوظيفة <span class="req">*</span></label><input id="j-title" class="form-input" required></div>
          <div class="filter-grid">
            <div class="form-group"><label>نوع الدوام</label><select id="j-type" class="form-input"><option value="دوام كامل">دوام كامل</option><option value="دوام جزئي">دوام جزئي</option><option value="عمل حر">عمل حر</option><option value="عن بعد">عن بعد</option><option value="تدريب">تدريب</option><option value="مؤقت">مؤقت</option></select></div>
            <div class="form-group"><label>الراتب</label><input id="j-salary" class="form-input" placeholder="1500 - 2000$"></div>
          </div>
          <div class="filter-grid">
            <div class="form-group"><label>المدينة</label><input id="j-city" class="form-input" placeholder="رام الله" required></div>
            <div class="form-group"><label>الخبرة المطلوبة</label><input id="j-exp" class="form-input" placeholder="سنة - سنتين"></div>
          </div>
          <div class="form-group"><label>المهارات (افصل بفاصلة)</label><input id="j-skills" class="form-input" placeholder="Flutter, Dart, Firebase"></div>
          <div class="form-group"><label>الوصف</label><textarea id="j-desc" class="form-input"></textarea></div>
          <button class="btn btn-primary" type="submit" style="display:flex;gap:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> نشر الوظيفة</button>
        </form>
      </div>`;
  },

  handleNewJob() {
    const j = {
      id: 'jb' + Date.now(), companyName: document.getElementById('j-company').value,
      title: document.getElementById('j-title').value, type: document.getElementById('j-type').value,
      salary: document.getElementById('j-salary').value || 'غير محدد', city: document.getElementById('j-city').value,
      experience: document.getElementById('j-exp').value || 'غير محدد',
      skills: document.getElementById('j-skills').value.split(',').map(s => s.trim()).filter(Boolean),
      description: document.getElementById('j-desc').value, applicants: [],
      createdAt: new Date().toISOString(),
    };
    this.jobs.unshift(j); this.saveAll(); this.navigate('jobs');
    this.toast('تم نشر الوظيفة', 'success');
  },

  /* ================= REQUESTS ================= */
  renderRequests() {
    const p = document.getElementById('page-content');
    const tabs = ['الكل', 'open', 'negotiating', 'done'];
    const tabMap = { 'الكل': 'الكل', open: 'مفتوحة', negotiating: 'قيد التفاوض', done: 'منفذة' };
    const current = this._rqTab || 'الكل';
    let list = current === 'الكل' ? this.requests : this.requests.filter(r => r.status === current);
    list = [...list].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    p.innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px">
          <h2 style="font-size:20px;font-weight:700;display:flex;align-items:center;gap:8px"><i class="ph ph-duotone ph-megaphone" style="color:var(--olive)"></i> الطلبات</h2>
          <button class="btn btn-primary btn-sm" onclick="APP.navigate('new-request')" style="display:flex;gap:6px"><i class="ph ph-duotone ph-plus-circle"></i> انشر طلباً</button>
        </div>
        <div class="profile-tabs" style="margin-bottom:16px">
          ${tabs.map(t => `<button class="${current === t ? 'active' : ''}" onclick="APP._rqTab='${t}';APP.renderRequests()">${tabMap[t]}</button>`).join('')}
        </div>
        <p style="font-size:13px;color:var(--text-muted);margin-bottom:16px">تحتاج شيئاً؟ انشر طلباً واترك العروض تصل إليك.</p>
        ${list.length === 0 ? '<div class="empty-state"><div class="icon"><i class="ph ph-duotone ph-megaphone"></i></div><h3>لا توجد طلبات</h3></div>' :
          list.map(r => this.requestListItem(r)).join('')}
      </div>`;
  },

  requestListItem(r) {
    const statusMap = { open: ['tag-green', 'مفتوح'], negotiating: ['tag-violet', 'قيد التفاوض'], done: ['tag-blue', 'منفذ'] };
    const [cls, lbl] = statusMap[r.status] || ['tag-slate', r.status];
    return `<div class="req-card" onclick="APP.showRequestDetail('${r.id}')">
      <div class="req-top">
        <h4>${this.esc(r.title)}</h4>
        <span class="tag ${cls}">${lbl}</span>
      </div>
      <div class="req-sub"><i class="ph ph-duotone ph-user"></i> ${this.esc(r.userName)} <span class="tag tag-olive">${r.category}</span></div>
      <div class="req-desc">${this.esc(r.description)}</div>
      <div class="req-meta">
        <span><i class="ph ph-duotone ph-clock"></i> ${this.timeAgo(r.createdAt)}</span>
        <span><i class="ph ph-duotone ph-handshake"></i> ${r.offers.length} عروض</span>
      </div>
    </div>`;
  },

  showRequestDetail(id) {
    const r = this.requests.find(x => x.id === id); if (!r) return;
    const statusMap = { open: ['tag-green', 'مفتوح'], negotiating: ['tag-violet', 'قيد التفاوض'], done: ['tag-blue', 'منفذ'] };
    const [cls, lbl] = statusMap[r.status] || ['tag-slate', r.status];
    const mine = r.userId === this.currentUser?.id;
    this.showModal(`
      <div class="modal-handle"></div>
      <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:6px">
        <h3 style="font-size:18px;font-weight:700">${this.esc(r.title)}</h3>
        <span class="tag ${cls}">${lbl}</span>
      </div>
      <div style="font-size:13px;color:var(--text-muted);margin-bottom:12px"><i class="ph ph-duotone ph-user"></i> ${this.esc(r.userName)} • <span class="tag tag-olive">${r.category}</span></div>
      <div class="section" style="margin-bottom:12px"><div class="detail-desc">${this.esc(r.description)}</div></div>
      <h4 style="font-size:15px;font-weight:700;margin-bottom:10px">العروض (${r.offers.length})</h4>
      ${r.offers.length === 0 ? '<p style="font-size:13px;color:var(--text-muted);margin-bottom:12px">لا توجد عروض بعد — كن أول من يعرض.</p>' :
        r.offers.map(o => `<div style="background:var(--bg);border-radius:12px;padding:13px;margin-bottom:8px;font-size:13px"><div style="display:flex;justify-content:space-between"><b>${this.esc(o.offererName)}</b><b style="color:var(--primary)">${o.price} ₪</b></div>${o.message ? `<div style="color:var(--text-muted);margin-top:4px">${this.esc(o.message)}</div>` : ''}<div style="font-size:10.5px;color:var(--text-light);margin-top:4px">${this.timeAgo(o.createdAt)}</div></div>`).join('')}

      ${r.status === 'done' ? '<div style="padding:12px;background:var(--olive-light);border-radius:var(--radius-sm);font-size:13px;color:var(--olive-2);display:flex;align-items:center;gap:8px;margin-top:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تم تنفيذ هذا الطلب</div>' : ''}

      ${!mine && r.status !== 'done' ? `
      <hr style="border:none;border-top:1px solid var(--line);margin:14px 0">
      <form onsubmit="event.preventDefault();APP.sendOffer('${r.id}')">
        <div class="form-group"><label>سعر العرض (شيكل) <span class="req">*</span></label><input id="of-price" class="form-input" type="number" placeholder="0" required></div>
        <div class="form-group"><label>رسالتك</label><textarea id="of-msg" class="form-input" placeholder="اشرح كيف يمكنك المساعدة..."></textarea></div>
        <button class="btn btn-primary" type="submit" style="display:flex;gap:8px"><i class="ph ph-duotone ph-paper-plane-tilt"></i> إرسال العرض</button>
      </form>` : ''}

      ${mine && r.status !== 'done' ? `<div style="display:flex;gap:8px;margin-top:8px">
        <button class="btn btn-primary btn-sm" style="flex:1;display:flex;gap:5px" onclick="APP.setRequestStatus('${r.id}','done');APP.closeModal()"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> تم التنفيذ</button>
        <button class="btn btn-danger btn-sm" style="flex:1;display:flex;gap:5px" onclick="APP.deleteRequest('${r.id}');APP.closeModal()"><i class="ph ph-duotone ph-trash"></i> حذف</button>
      </div>` : ''}
    `);
  },

  sendOffer(id) {
    const r = this.requests.find(x => x.id === id); if (!r) return;
    r.offers.push({ id: 'of' + Date.now(), userId: this.currentUser.id, offererName: this.currentUser.name, price: parseFloat(document.getElementById('of-price').value) || 0, message: document.getElementById('of-msg').value || '', createdAt: new Date().toISOString() });
    r.status = 'negotiating';
    this.saveAll(); this.closeModal(); this.toast('تم إرسال عرضك', 'success');
  },

  setRequestStatus(id, s) {
    const r = this.requests.find(x => x.id === id); if (!r) return;
    r.status = s; this.saveAll(); this.render();
    this.toast('تم تحديث حالة الطلب', 'success');
  },

  deleteRequest(id) {
    this.requests = this.requests.filter(x => x.id !== id);
    this.saveAll(); this.render(); this.toast('تم حذف الطلب', 'info');
  },

  renderNewRequest() {
    document.getElementById('page-content').innerHTML = `
      <div class="container">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:20px">
          <button class="icon-btn" style="width:38px;height:38px" onclick="APP.navigate('requests')"><i class="ph ph-duotone ph-arrow-right"></i></button>
          <h2 style="font-size:19px;font-weight:700;flex:1">انشر طلباً</h2>
        </div>
        <form onsubmit="event.preventDefault();APP.handleNewRequest()">
          <div class="form-group"><label>ماذا تحتاج؟ <span class="req">*</span></label><input id="rq-title" class="form-input" placeholder="أبحث عن لابتوب مستعمل..." required></div>
          <div class="form-group"><label>التصنيف</label><select id="rq-cat" class="form-input"><option value="لابتوبات">لابتوبات</option><option value="هواتف">هواتف</option><option value="إلكترونيات">إلكترونيات</option><option value="سيارات">سيارات</option><option value="عقارات">عقارات</option><option value="أثاث">أثاث</option><option value="خدمات منزلية">خدمات منزلية</option><option value="خدمات">خدمات</option><option value="توصيل">توصيل</option><option value="أخرى">أخرى</option></select></div>
          <div class="form-group"><label>تفاصيل الطلب</label><textarea id="rq-desc" class="form-input" placeholder="اكتب التفاصيل، الميزانية، الموقع..."></textarea></div>
          <button class="btn btn-primary" type="submit" style="display:flex;gap:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> نشر الطلب</button>
        </form>
      </div>`;
  },

  handleNewRequest() {
    const r = {
      id: 'rq' + Date.now(), userId: this.currentUser.id, userName: this.currentUser.name,
      title: document.getElementById('rq-title').value, category: document.getElementById('rq-cat').value,
      description: document.getElementById('rq-desc').value, status: 'open', offers: [],
      createdAt: new Date().toISOString(),
    };
    this.requests.unshift(r); this.saveAll(); this.navigate('requests');
    this.toast('تم نشر طلبك', 'success');
  },

  /* ================= PROFILE ================= */
  getUserStats(u) {
    const orders = this.orders.filter(x => x.buyerId === u.id);
    const products = this.products.filter(x => x.sellerId === u.id);
    const services = this.services.filter(x => x.userId === u.id);
    const sales = this.orders.filter(o => o.items.some(i => i.productId && this.products.find(x => x.id === i.productId)?.sellerId === u.id));
    const deliveries = this.orders.filter(o => o.deliveryPersonId === u.id);
    return {
      orders: orders.length,
      products: products.length,
      services: services.length,
      purchases: orders.reduce((s, x) => s + x.total, 0),
      salesCount: sales.length,
      deliveriesDone: deliveries.filter(o => o.status === 'delivered').length,
      rating: u.rating || 0,
      ratingCount: u.ratingCount || 0,
    };
  },

  renderProfile() {
    const p = document.getElementById('page-content'), b = document.getElementById('bottom-bar');
    b.style.display = 'none'; const u = this.currentUser;
    if (!u) { this.navigate('login'); return; }
    const tm = { regular: 'مستخدم عادي', delivery: 'موصل', admin: 'أدمن' };
    const s = this.getUserStats(u);
    p.innerHTML = `
      <div class="container">
        <div class="profile-cover">
          <div class="p-ava"><i class="ph ph-duotone ph-user"></i></div>
          <div class="p-name">${this.esc(u.name)}${u.verified ? '<span class="verified"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></span>' : ''}</div>
          <div class="p-sub"><i class="ph ph-duotone ph-map-pin"></i> ${this.esc(u.address)}</div>
          <div class="p-type"><i class="ph ph-duotone ${u.userType === 'delivery' ? 'ph-moped' : u.userType === 'admin' ? 'ph-shield-check' : 'ph-user-circle'}"></i> ${tm[u.userType] || u.userType}</div>
          ${u.rating ? `<div class="p-sub" style="margin-top:8px"><span class="rating-stars">${this.stars(u.rating)}</span> ${u.rating} (${u.ratingCount} تقييم)</div>` : ''}
          ${u.bio ? `<div class="p-bio">${this.esc(u.bio)}</div>` : ''}
          ${u.joinedAt ? `<div class="p-sub" style="margin-top:8px;font-size:11.5px"><i class="ph ph-duotone ph-calendar-blank"></i> انضم ${new Date(u.joinedAt).toLocaleDateString('ar-EG', { day: 'numeric', month: 'long', year: 'numeric' })}</div>` : ''}
        </div>

        <div class="profile-stats">
          <div class="stat-grid cols3">
            ${u.userType === 'delivery' ? `
              <div class="stat-card"><div class="stat-icon"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg></div><div class="stat-number">${s.deliveriesDone}</div><div class="stat-label">منجز</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-star"></i></div><div class="stat-number">${s.rating || '—'}</div><div class="stat-label">التقييم</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-map-pin"></i></div><div class="stat-number">${u.deliveryAreas?.length || 0}</div><div class="stat-label">مناطق</div></div>` :
            u.userType === 'admin' ? `
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-users"></i></div><div class="stat-number">${this.users.length}</div><div class="stat-label">مستخدم</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-package"></i></div><div class="stat-number">${this.products.length}</div><div class="stat-label">منتجات</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-wrench"></i></div><div class="stat-number">${this.services.length}</div><div class="stat-label">خدمات</div></div>` :
              `
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-package"></i></div><div class="stat-number">${s.products}</div><div class="stat-label">منتجاتي</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-wrench"></i></div><div class="stat-number">${s.services}</div><div class="stat-label">خدماتي</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-star"></i></div><div class="stat-number">${s.rating || '—'}</div><div class="stat-label">التقييم</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-shopping-cart"></i></div><div class="stat-number">${s.orders}</div><div class="stat-label">طلباتي</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-trend-up"></i></div><div class="stat-number">${s.salesCount}</div><div class="stat-label">مبيعاتي</div></div>
              <div class="stat-card"><div class="stat-icon"><i class="ph ph-duotone ph-currency-dollar"></i></div><div class="stat-number">${s.purchases}</div><div class="stat-label">مشترياتي</div></div>`}
          </div>
        </div>

        <div class="wallet-card">
          <div class="wc-ico"><i class="ph ph-duotone ph-wallet"></i></div>
          <div class="wc-info"><div class="wc-lbl">رصيد المحفظة</div><div class="wc-amt">${u.balance || 0} ₪</div><div class="wc-hint">يُخصم عند الدفع بالمحفظة، وتربح أجرة التوصيل عند إتمامه</div></div>
        </div>

        <div class="section" style="margin-top:20px">
          <div class="menu-item" onclick="APP.navigate('orders')"><span class="icon"><i class="ph ph-duotone ph-clipboard-text"></i></span><span class="label">طلباتي</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
          <div class="menu-item" onclick="APP.navigate('add-product')"><span class="icon"><i class="ph ph-duotone ph-plus-circle"></i></span><span class="label">نشر إعلان</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
          <div class="menu-item" onclick="APP.navigate('new-service')"><span class="icon"><i class="ph ph-duotone ph-wrench"></i></span><span class="label">تقديم خدمة</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
          <div class="menu-item" onclick="APP.navigate('new-job')"><span class="icon"><i class="ph ph-duotone ph-briefcase"></i></span><span class="label">نشر وظيفة</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
          <div class="menu-item" onclick="APP.navigate('new-request')"><span class="icon"><i class="ph ph-duotone ph-megaphone"></i></span><span class="label">نشر طلب</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
          ${u.userType === 'delivery' ? '<div class="menu-item" onclick="APP.navigate(\'delivery\')"><span class="icon"><i class="ph ph-duotone ph-moped"></i></span><span class="label">لوحة التوصيل</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>' : ''}
          ${u.userType === 'admin' ? '<div class="menu-item" onclick="APP.navigate(\'admin\')"><span class="icon"><i class="ph ph-duotone ph-shield"></i></span><span class="label">لوحة الإدارة</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>' : ''}
          <div class="menu-item" onclick="APP.showEditProfile()"><span class="icon"><i class="ph ph-duotone ph-pen"></i></span><span class="label">تعديل البيانات</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
          <div class="menu-item" style="border-bottom:none" onclick="APP.showSaved()"><span class="icon"><i class="ph ph-duotone ph-bookmark"></i></span><span class="label">الإعلانات المحفوظة (${this.saved.length})</span><span class="arrow"><i class="ph ph-duotone ph-caret-left"></i></span></div>
        </div>
        <button class="btn btn-danger" onclick="APP.logout()" style="margin-top:8px;display:flex;gap:8px"><i class="ph ph-duotone ph-sign-out"></i> تسجيل الخروج</button>
      </div>`;
  },

  showSaved() {
    const items = this.products.filter(x => this.saved.includes(x.id));
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="font-size:18px;font-weight:700;margin-bottom:16px">الإعلانات المحفوظة (${items.length})</h3>
      ${items.length === 0 ? '<div class="empty-state" style="padding:24px"><div class="icon"><i class="ph ph-duotone ph-bookmark"></i></div><h3>لا توجد محفوظات</h3><p>احفظ الإعلانات التي تعجبك</p></div>' : `
        <div class="post-feed">
          ${items.map(x => this.postCard(x)).join('')}
        </div>`}
    `);
  },

  showEditProfile() {
    const u = this.currentUser;
    this.showModal(`
      <div class="modal-handle"></div>
      <h3 style="margin-bottom:18px;font-size:18px;font-weight:700">تعديل البيانات</h3>
      <form onsubmit="event.preventDefault();APP.updateProfile()">
        <div class="form-group"><label>الاسم</label><input id="ep-name" class="form-input" value="${this.esc(u.name)}" required></div>
        <div class="form-group"><label>رقم الهاتف</label><input id="ep-phone" class="form-input" value="${this.esc(u.phone)}" required></div>
        <div class="form-group"><label>العنوان</label><input id="ep-address" class="form-input" value="${this.esc(u.address || '')}"></div>
        <div class="form-group"><label>نبذة قصيرة</label><textarea id="ep-bio" class="form-input" placeholder="اكتب نبذة عنك...">${this.esc(u.bio || '')}</textarea></div>
        ${u.userType === 'delivery' ? `<div class="form-group"><label>رسوم التوصيل (₪)</label><input id="ep-fee" type="number" class="form-input" value="${u.deliveryFee || 0}"></div>` : ''}
        <button class="btn btn-primary" type="submit" style="display:flex;gap:8px"><svg class="chk" viewBox="0 0 24 24" aria-hidden="true"><path d="M5.5 12.5l4.5 4.5 8.5-10"/></svg> حفظ التغييرات</button>
      </form>
    `);
  },

  updateProfile() {
    const u = this.currentUser;
    u.name = document.getElementById('ep-name').value;
    u.phone = document.getElementById('ep-phone').value;
    u.address = document.getElementById('ep-address').value;
    u.bio = document.getElementById('ep-bio')?.value || '';
    if (u.userType === 'delivery') u.deliveryFee = parseFloat(document.getElementById('ep-fee').value) || 0;
    const i = this.users.findIndex(x => x.id === u.id); if (i >= 0) this.users[i] = u;
    this.saveAll(); this.closeModal(); this.render(); this.toast('تم حفظ التغييرات', 'success');
  },

  /* ================= UX ================= */
  toast(msg, type = 'info') {
    const t = document.getElementById('toast');
    const icons = { success: 'chk', error: 'ph-warning-circle', info: 'ph-info' };
    t.innerHTML = `${icons[type] === 'chk' ? CHK_SVG : `<i class="ph ph-duotone ${icons[type]}"></i>`}${msg}`;
    t.className = `toast ${type} show`;
    clearTimeout(this._t); this._t = setTimeout(() => t.classList.remove('show'), 2600);
  },

  showModal(html) { document.getElementById('modal-content').innerHTML = html; document.getElementById('modal-overlay').classList.add('show'); },
  closeModal() { document.getElementById('modal-overlay').classList.remove('show'); },
};

document.addEventListener('DOMContentLoaded', () => APP.init());

