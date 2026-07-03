// SearchView Component - Search page with distance and category filters
import React, { useState, useEffect } from 'react';
import ListingCard from '../components/ListingCard';
import { Search, SlidersHorizontal, MapPin } from 'lucide-react';
import { calculateDistance } from '../utils/geo';
import { MockDB } from '../db/MockDB';

export default function SearchView({ 
  listings, 
  userLocation, 
  currentUser, 
  categories, 
  initialCategory,
  onSelectProduct, 
  onWishlistToggle, 
  wishlistedIds 
}) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState(initialCategory || 'Semua');
  const [radius, setRadius] = useState('any'); // any, 1, 3, 5, 10
  const [sortBy, setSortBy] = useState('distance'); // distance, date, priceAsc, priceDesc
  const [showFilters, setShowFilters] = useState(true);

  // Sync category if passed from landing page
  useEffect(() => {
    if (initialCategory) {
      setSelectedCategory(initialCategory);
    }
  }, [initialCategory]);

  // Find all active published listings
  const publishedListings = listings.filter(l => l.status === 'published');

  // Process filters
  const users = MockDB.getUsers();
  
  const filteredListings = publishedListings.map(listing => {
    const seller = users.find(u => u.id === listing.sellerId);
    let distance = null;
    if (userLocation.lat && seller && seller.lat) {
      distance = calculateDistance(
        userLocation.lat,
        userLocation.lng,
        seller.lat,
        seller.lng
      );
    }
    return { ...listing, distance, seller };
  }).filter(item => {
    // 1. Text search
    const matchesQuery = 
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.description.toLowerCase().includes(searchQuery.toLowerCase());
      
    // 2. Category search
    const matchesCategory = 
      selectedCategory === 'Semua' || 
      item.category === selectedCategory;

    // 3. Radius search
    let matchesRadius = true;
    if (radius !== 'any' && userLocation.lat) {
      const maxDist = parseFloat(radius);
      matchesRadius = item.distance !== null && item.distance <= maxDist;
    }

    return matchesQuery && matchesCategory && matchesRadius;
  });

  // Sorting
  const sortedListings = [...filteredListings].sort((a, b) => {
    if (sortBy === 'distance') {
      if (a.distance === null) return 1;
      if (b.distance === null) return -1;
      return a.distance - b.distance;
    }
    if (sortBy === 'date') {
      return new Date(b.createdAt) - new Date(a.createdAt);
    }
    if (sortBy === 'priceAsc') {
      return a.price - b.price;
    }
    if (sortBy === 'priceDesc') {
      return b.price - a.price;
    }
    return 0;
  });

  return (
    <div style={{ animation: 'fadeIn 0.25s' }}>
      {/* Search Input Bar */}
      <div className="search-container">
        <div className="input-group">
          <Search size={18} />
          <input 
            type="text" 
            className="form-input" 
            placeholder="Cari barang terdekat (misal: sepeda, kipas)..." 
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
          />
        </div>
        
        <button 
          onClick={() => setShowFilters(!showFilters)}
          className="btn btn-secondary" 
          style={{ width: 'auto', padding: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
        >
          <SlidersHorizontal size={18} color={radius !== 'any' || selectedCategory !== 'Semua' ? '#10b981' : '#fff'} />
        </button>
      </div>

      {/* Advanced Filters Drawer */}
      {showFilters && (
        <div 
          className="glass-card" 
          style={{ 
            padding: '14px', 
            marginBottom: '16px',
            backgroundColor: 'rgba(30, 41, 59, 0.2)',
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: '10px'
          }}
        >
          {/* Category Selector */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <label style={{ fontSize: '10px', fontWeight: '700', color: 'hsl(var(--text-muted))', textTransform: 'uppercase' }}>Kategori</label>
            <select 
              className="form-select"
              value={selectedCategory}
              onChange={e => setSelectedCategory(e.target.value)}
            >
              <option value="Semua">Semua Kategori</option>
              {categories.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>

          {/* Radius Selector */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <label style={{ fontSize: '10px', fontWeight: '700', color: 'hsl(var(--text-muted))', textTransform: 'uppercase' }}>
              Radius Jarak
            </label>
            <select 
              className="form-select"
              value={radius}
              onChange={e => setRadius(e.target.value)}
            >
              <option value="any">Semua Jarak (COD)</option>
              <option value="1">Dalam 1 KM</option>
              <option value="3">Dalam 3 KM</option>
              <option value="5">Dalam 5 KM</option>
              <option value="10">Dalam 10 KM</option>
            </select>
          </div>

          {/* Sort Selector */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', gridColumn: 'span 2' }}>
            <label style={{ fontSize: '10px', fontWeight: '700', color: 'hsl(var(--text-muted))', textTransform: 'uppercase' }}>Urutkan Berdasarkan</label>
            <select 
              className="form-select"
              value={sortBy}
              onChange={e => setSortBy(e.target.value)}
            >
              <option value="distance">📍 Jarak Terdekat</option>
              <option value="date">📅 Tanggal Terbaru</option>
              <option value="priceAsc">💰 Harga: Murah ke Mahal</option>
              <option value="priceDesc">💰 Harga: Mahal ke Murah</option>
            </select>
          </div>
        </div>
      )}

      {/* Result Status */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px', padding: '0 4px' }}>
        <span style={{ fontSize: '11px', color: 'hsl(var(--text-muted))' }}>
          Menemukan <strong>{sortedListings.length}</strong> barang terbit
        </span>
        {userLocation.lat && (
          <span style={{ fontSize: '10px', color: 'hsl(var(--primary))', display: 'flex', alignItems: 'center', gap: '3px' }}>
            <MapPin size={10} />
            <span>GPS: {userLocation.name}</span>
          </span>
        )}
      </div>

      {/* Product Catalog Grid */}
      {sortedListings.length === 0 ? (
        <div className="glass-card" style={{ padding: '60px 10px', textAlign: 'center', color: 'hsl(var(--text-muted))' }}>
          <p style={{ fontSize: '13px', fontWeight: '500' }}>Tidak ada barang terdekat yang sesuai filter.</p>
          <p style={{ fontSize: '11px', marginTop: '6px' }}>Coba perluas radius jarak atau gunakan kata kunci lain.</p>
        </div>
      ) : (
        <div className="product-grid">
          {sortedListings.map(listing => (
            <ListingCard 
              key={listing.id}
              listing={listing}
              userLocation={userLocation}
              currentUser={currentUser}
              onSelect={onSelectProduct}
              onWishlistToggle={onWishlistToggle}
              isWishlisted={wishlistedIds.includes(listing.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
