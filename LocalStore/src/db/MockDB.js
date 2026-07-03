// Mock Database wrapper using LocalStorage for LocalStore MVP

const STORAGE_KEYS = {
  USERS: 'localstore_users',
  LISTINGS: 'localstore_listings',
  CATEGORIES: 'localstore_categories',
  REVIEWS: 'localstore_reviews',
  REPORTS: 'localstore_reports',
  WISHLIST: 'localstore_wishlist',
  FOLLOWERS: 'localstore_followers',
  GEO_CACHE: 'localstore_geo_cache',
  CURRENT_USER: 'localstore_current_user'
};

const DEFAULT_CATEGORIES = [
  'Elektronik',
  'Pakaian',
  'Perlengkapan Rumah',
  'Otomotif',
  'Hobi & Olahraga',
  'Kecantikan & Kesehatan',
  'Lain-lain'
];

// Pre-seeded Users
const DEFAULT_USERS = [
  {
    id: 'admin_1',
    email: 'admin@localstore.com',
    name: 'Administrator',
    role: 'admin',
    avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=admin1',
    phone: '',
    sellerStatus: 'approved',
    trustScore: 100,
    followersCount: 0,
    shopName: 'Admin Center',
    lat: null,
    lng: null,
    kelurahan: ''
  },
  {
    id: 'seller_budi',
    email: 'budi@gmail.com',
    name: 'Budi Raharjo',
    role: 'seller', // Can be seller and buyer
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=budi',
    phone: '08123456789',
    sellerStatus: 'approved',
    trustScore: 95,
    followersCount: 15,
    shopName: 'Toko Serba Budi',
    lat: -6.2384,
    lng: 106.7456,
    kelurahan: 'Petukangan Utara'
  },
  {
    id: 'seller_siti',
    email: 'siti@gmail.com',
    name: 'Siti Rahmawati',
    role: 'seller',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=siti',
    phone: '08987654321',
    sellerStatus: 'approved',
    trustScore: 98,
    followersCount: 28,
    shopName: 'Warung Berkah Siti',
    lat: -6.2412,
    lng: 106.7421,
    kelurahan: 'Petukangan Selatan'
  },
  {
    id: 'seller_bintaro',
    email: 'bintaro.thrift@gmail.com',
    name: 'Faisal Akbar',
    role: 'seller',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=faisal',
    phone: '08554433221',
    sellerStatus: 'approved',
    trustScore: 88,
    followersCount: 8,
    shopName: 'Bintaro Secondhand',
    lat: -6.2655,
    lng: 106.7389,
    kelurahan: 'Bintaro'
  },
  {
    id: 'seller_cipulir',
    email: 'cipulirthrift@gmail.com',
    name: 'Andi Wijaya',
    role: 'buyer', // Role is still buyer because sellerStatus is pending
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=andi',
    phone: '08999999999',
    sellerStatus: 'pending', // Starts as pending onboarding to test admin workflow!
    trustScore: 100,
    followersCount: 0,
    shopName: 'Cipulir Thrift Store',
    lat: -6.2361,
    lng: 106.7725,
    kelurahan: 'Cipulir'
  },
  {
    id: 'buyer_joko',
    email: 'joko@gmail.com',
    name: 'Joko Prasetyo',
    role: 'buyer',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=joko',
    phone: '08129988776',
    sellerStatus: 'none',
    trustScore: 100,
    followersCount: 0,
    shopName: '',
    lat: null,
    lng: null,
    kelurahan: ''
  }
];

// Pre-seeded Listings
const DEFAULT_LISTINGS = [
  {
    id: 'list_1',
    title: 'Kipas Angin Cosmos Dinding',
    price: 150000,
    sellerId: 'seller_budi',
    category: 'Elektronik',
    status: 'published', // pending, published, sold, archived
    description: 'Kondisi 90% mulus, tiupan angin kencang dan tidak bising. Minus berdebu pemakaian wajar. Bisa COD sekitar kelurahan Petukangan Utara atau langsung ke rumah saya.',
    image: 'https://images.unsplash.com/photo-1618945032043-c793132e4d0d?auto=format&fit=crop&w=600&q=80',
    createdAt: '2026-06-15T10:00:00.000Z'
  },
  {
    id: 'list_2',
    title: 'Sepeda Lipat Exotic 20 Inch',
    price: 1200000,
    sellerId: 'seller_siti',
    category: 'Hobi & Olahraga',
    status: 'published',
    description: 'Sepeda lipat Exotic 20 inch, shimano 7 speed, rem cakram aktif. Rangka mulus, lipatan kokoh tidak goyang. COD daerah Petukangan Selatan, pasar ceger, atau pom bensin terdekat.',
    image: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=600&q=80',
    createdAt: '2026-06-14T14:30:00.000Z'
  },
  {
    id: 'list_3',
    title: 'Jaket Bomber Kulit Zara M',
    price: 350000,
    sellerId: 'seller_bintaro',
    category: 'Pakaian',
    status: 'published',
    description: 'Jaket bomber zara man original, bahan kulit sintetis premium tebal. Ukuran M fit to L kecil. Kondisi masih sangat mulus 95% jarang pakai. COD sektor 1 Bintaro.',
    image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=600&q=80',
    createdAt: '2026-06-13T08:15:00.000Z'
  },
  {
    id: 'list_4',
    title: 'Set Piring Keramik Cantik Vintage',
    price: 95000,
    sellerId: 'seller_budi',
    category: 'Perlengkapan Rumah',
    status: 'published',
    description: '1 set piring keramik motif bunga gaya vintage isi 6 pcs. Sangat tebal, cocok untuk pajangan ruang makan atau penggunaan sehari-hari. COD Petukangan Utara.',
    image: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=600&q=80',
    createdAt: '2026-06-12T16:45:00.000Z'
  },
  {
    id: 'list_5',
    title: 'Helm KYT DJ Maru Size L',
    price: 220000,
    sellerId: 'seller_cipulir',
    category: 'Otomotif',
    status: 'pending', // Starts as pending to test Admin Listing Approval flow!
    description: 'Helm KYT DJ Maru warna hitam doff, busa tebal, kaca visor bening mulus. Ada baret halus pemakaian luar. Dus & tas helm masih ada. COD pasar Cipulir.',
    image: 'https://images.unsplash.com/photo-1599819811279-d5ad9cccf838?auto=format&fit=crop&w=600&q=80',
    createdAt: '2026-06-16T12:00:00.000Z'
  }
];

// Pre-seeded Reviews
const DEFAULT_REVIEWS = [
  {
    id: 'rev_1',
    sellerId: 'seller_budi',
    reviewerName: 'Joko Prasetyo',
    rating: 5,
    text: 'Sangat ramah penjualnya. Barang kipas anginnya masih dingin dan lancar jaya pas dicoba COD langsung di depan kelurahan. Rekomended seller!',
    date: '2026-06-10T11:20:00.000Z'
  },
  {
    id: 'rev_2',
    sellerId: 'seller_siti',
    reviewerName: 'Joko Prasetyo',
    rating: 5,
    text: 'Barang bagus, sesuai janji. Tepat waktu pas COD-an. Makasih ya Bu!',
    date: '2026-06-12T09:00:00.000Z'
  }
];

// Seed geocoding coordinates cache to comply with OSM Nominatim API terms
const DEFAULT_GEO_CACHE = {
  '-6.2384,106.7456': 'Petukangan Utara',
  '-6.2412,106.7421': 'Petukangan Selatan',
  '-6.2655,106.7389': 'Bintaro',
  '-6.2361,106.7725': 'Cipulir'
};

export const MockDB = {
  init: () => {
    if (!localStorage.getItem(STORAGE_KEYS.USERS)) {
      localStorage.setItem(STORAGE_KEYS.USERS, JSON.stringify(DEFAULT_USERS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.LISTINGS)) {
      localStorage.setItem(STORAGE_KEYS.LISTINGS, JSON.stringify(DEFAULT_LISTINGS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.CATEGORIES)) {
      localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(DEFAULT_CATEGORIES));
    }
    if (!localStorage.getItem(STORAGE_KEYS.REVIEWS)) {
      localStorage.setItem(STORAGE_KEYS.REVIEWS, JSON.stringify(DEFAULT_REVIEWS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.REPORTS)) {
      localStorage.setItem(STORAGE_KEYS.REPORTS, JSON.stringify([]));
    }
    if (!localStorage.getItem(STORAGE_KEYS.WISHLIST)) {
      localStorage.setItem(STORAGE_KEYS.WISHLIST, JSON.stringify({}));
    }
    if (!localStorage.getItem(STORAGE_KEYS.FOLLOWERS)) {
      localStorage.setItem(STORAGE_KEYS.FOLLOWERS, JSON.stringify({}));
    }
    if (!localStorage.getItem(STORAGE_KEYS.GEO_CACHE)) {
      localStorage.setItem(STORAGE_KEYS.GEO_CACHE, JSON.stringify(DEFAULT_GEO_CACHE));
    }
    if (!localStorage.getItem(STORAGE_KEYS.CURRENT_USER)) {
      // Default logged in user: Joko Prasetyo (Buyer)
      localStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(DEFAULT_USERS.find(u => u.id === 'buyer_joko')));
    }
  },

  reset: () => {
    localStorage.setItem(STORAGE_KEYS.USERS, JSON.stringify(DEFAULT_USERS));
    localStorage.setItem(STORAGE_KEYS.LISTINGS, JSON.stringify(DEFAULT_LISTINGS));
    localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(DEFAULT_CATEGORIES));
    localStorage.setItem(STORAGE_KEYS.REVIEWS, JSON.stringify(DEFAULT_REVIEWS));
    localStorage.setItem(STORAGE_KEYS.REPORTS, JSON.stringify([]));
    localStorage.setItem(STORAGE_KEYS.WISHLIST, JSON.stringify({}));
    localStorage.setItem(STORAGE_KEYS.FOLLOWERS, JSON.stringify({}));
    localStorage.setItem(STORAGE_KEYS.GEO_CACHE, JSON.stringify(DEFAULT_GEO_CACHE));
    localStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(DEFAULT_USERS.find(u => u.id === 'buyer_joko')));
    window.location.reload();
  },

  // USERS
  getUsers: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.USERS) || '[]'),
  saveUsers: (users) => localStorage.setItem(STORAGE_KEYS.USERS, JSON.stringify(users)),
  
  getLoggedInUser: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.CURRENT_USER) || 'null'),
  setLoggedInUser: (user) => {
    localStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(user));
    // Also update in user list
    if (user) {
      const users = MockDB.getUsers();
      const index = users.findIndex(u => u.id === user.id);
      if (index !== -1) {
        users[index] = user;
        MockDB.saveUsers(users);
      }
    }
  },

  updateUserProfile: (userId, updates) => {
    const users = MockDB.getUsers();
    const index = users.findIndex(u => u.id === userId);
    if (index !== -1) {
      users[index] = { ...users[index], ...updates };
      MockDB.saveUsers(users);
      
      const current = MockDB.getLoggedInUser();
      if (current && current.id === userId) {
        MockDB.setLoggedInUser(users[index]);
      }
      return users[index];
    }
    return null;
  },

  // LISTINGS
  getListings: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.LISTINGS) || '[]'),
  saveListings: (listings) => localStorage.setItem(STORAGE_KEYS.LISTINGS, JSON.stringify(listings)),
  
  addListing: (listing) => {
    const listings = MockDB.getListings();
    const newListing = {
      id: 'list_' + Date.now(),
      createdAt: new Date().toISOString(),
      status: 'pending', // Requires admin approval
      ...listing
    };
    listings.unshift(newListing);
    MockDB.saveListings(listings);
    return newListing;
  },

  updateListing: (listingId, updates) => {
    const listings = MockDB.getListings();
    const index = listings.findIndex(l => l.id === listingId);
    if (index !== -1) {
      listings[index] = { ...listings[index], ...updates };
      MockDB.saveListings(listings);
      return listings[index];
    }
    return null;
  },

  deleteListing: (listingId) => {
    let listings = MockDB.getListings();
    listings = listings.filter(l => l.id !== listingId);
    MockDB.saveListings(listings);
  },

  // CATEGORIES
  getCategories: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.CATEGORIES) || '[]'),
  saveCategories: (categories) => localStorage.setItem(STORAGE_KEYS.CATEGORIES, JSON.stringify(categories)),

  // REVIEWS
  getReviews: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.REVIEWS) || '[]'),
  saveReviews: (reviews) => localStorage.setItem(STORAGE_KEYS.REVIEWS, JSON.stringify(reviews)),
  
  addReview: (sellerId, reviewerName, rating, text) => {
    const reviews = MockDB.getReviews();
    const newReview = {
      id: 'rev_' + Date.now(),
      sellerId,
      reviewerName,
      rating: parseInt(rating),
      text,
      date: new Date().toISOString()
    };
    reviews.unshift(newReview);
    MockDB.saveReviews(reviews);

    // Update Seller's accumulated Trust Score
    const sellerReviews = reviews.filter(r => r.sellerId === sellerId);
    const totalScore = sellerReviews.reduce((sum, r) => sum + r.rating, 0);
    // Base trust is 80%, review averages shift it. For rating stars: 5 stars = 100%, 4 stars = 90%, 3 stars = 80%, etc.
    const averageRating = totalScore / sellerReviews.length;
    const newTrustScore = Math.min(100, Math.max(50, Math.round((averageRating / 5) * 100)));
    
    MockDB.updateUserProfile(sellerId, { trustScore: newTrustScore });
    return newReview;
  },

  // REPORTS
  getReports: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.REPORTS) || '[]'),
  saveReports: (reports) => localStorage.setItem(STORAGE_KEYS.REPORTS, JSON.stringify(reports)),
  
  addReport: (listingId, reporterId, reason, text) => {
    const reports = MockDB.getReports();
    const newReport = {
      id: 'rep_' + Date.now(),
      listingId,
      reporterId,
      reason,
      text,
      status: 'pending', // pending, resolved
      createdAt: new Date().toISOString()
    };
    reports.unshift(newReport);
    MockDB.saveReports(reports);
    return newReport;
  },

  // WISHLIST
  getWishlist: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.WISHLIST) || '{}'),
  saveWishlist: (wishlist) => localStorage.setItem(STORAGE_KEYS.WISHLIST, JSON.stringify(wishlist)),
  
  toggleWishlist: (userId, listingId) => {
    const wishlist = MockDB.getWishlist();
    if (!wishlist[userId]) wishlist[userId] = [];
    
    const index = wishlist[userId].indexOf(listingId);
    if (index === -1) {
      wishlist[userId].push(listingId);
    } else {
      wishlist[userId].splice(index, 1);
    }
    MockDB.saveWishlist(wishlist);
    return wishlist[userId];
  },
  
  isInWishlist: (userId, listingId) => {
    const wishlist = MockDB.getWishlist();
    if (!wishlist[userId]) return false;
    return wishlist[userId].includes(listingId);
  },

  // FOLLOWERS
  getFollowers: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.FOLLOWERS) || '{}'),
  saveFollowers: (followers) => localStorage.setItem(STORAGE_KEYS.FOLLOWERS, JSON.stringify(followers)),
  
  toggleFollow: (buyerId, sellerId) => {
    const followers = MockDB.getFollowers();
    if (!followers[sellerId]) followers[sellerId] = [];
    
    const index = followers[sellerId].indexOf(buyerId);
    let followed = false;
    if (index === -1) {
      followers[sellerId].push(buyerId);
      followed = true;
    } else {
      followers[sellerId].splice(index, 1);
    }
    MockDB.saveFollowers(followers);
    
    // Update Seller's follower count
    const count = followers[sellerId].length;
    MockDB.updateUserProfile(sellerId, { followersCount: count });
    
    return followed;
  },

  isFollowing: (buyerId, sellerId) => {
    const followers = MockDB.getFollowers();
    if (!followers[sellerId]) return false;
    return followers[sellerId].includes(buyerId);
  },

  // GEO CACHE
  getGeocodeCache: () => JSON.parse(localStorage.getItem(STORAGE_KEYS.GEO_CACHE) || '{}'),
  
  getCachedGeocode: (lat, lng) => {
    const cache = MockDB.getGeocodeCache();
    // Cache key format: lat,lng rounded to 4 decimal places (about 11m precision, perfect for local area lookup)
    const key = `${parseFloat(lat).toFixed(4)},${parseFloat(lng).toFixed(4)}`;
    return cache[key] || null;
  },

  saveCachedGeocode: (lat, lng, kelurahan) => {
    const cache = MockDB.getGeocodeCache();
    const key = `${parseFloat(lat).toFixed(4)},${parseFloat(lng).toFixed(4)}`;
    cache[key] = kelurahan;
    localStorage.setItem(STORAGE_KEYS.GEO_CACHE, JSON.stringify(cache));
  }
};
