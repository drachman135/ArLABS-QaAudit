// HomeView Component - Main Landing Feed
import React from 'react';
import ListingCard from '../components/ListingCard';
import { Sparkles, MapPin, Store } from 'lucide-react';

// Map categories to decorative emojis
const CATEGORY_EMOJIS = {
  'Elektronik': '🔌',
  'Pakaian': '👕',
  'Perlengkapan Rumah': '🏠',
  'Otomotif': '🚗',
  'Hobi & Olahraga': '🚲',
  'Kecantikan & Kesehatan': '💄',
  'Lain-lain': '📦'
};

export default function HomeView({ 
  listings, 
  userLocation, 
  currentUser, 
  categories, 
  onSelectProduct, 
  onWishlistToggle, 
  wishlistedIds,
  onCategorySelect,
  onNavigateToTab
}) {
  // Only display published listings on the home feed
  const publishedListings = listings.filter(l => l.status === 'published');

  return (
    <div style={{ animation: 'fadeIn 0.25s' }}>
      {/* Welcome & Location Summary */}
      <div style={{ marginBottom: '16px' }}>
        <h2 style={{ fontSize: '18px', fontWeight: '800', lineHeight: '1.2' }}>
          Halo, {currentUser ? currentUser.name.split(' ')[0] : 'Tetangga'}! 👋
        </h2>
        <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))', marginTop: '2px' }}>
          Cari barang bekas/baru terdekat di lingkungan sekitarmu.
        </p>
      </div>

      {/* Hero Banner */}
      <div 
        style={{
          background: 'linear-gradient(135deg, hsla(var(--primary), 0.8) 0%, #1d4ed8 100%)',
          borderRadius: 'var(--radius-md)',
          padding: '16px',
          color: '#ffffff',
          marginBottom: '20px',
          boxShadow: 'var(--shadow-md)',
          position: 'relative',
          overflow: 'hidden'
        }}
      >
        <div style={{ position: 'relative', zIndex: 2 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
            <Sparkles size={14} color="#fbbf24" fill="#fbbf24" />
            <span style={{ fontSize: '10px', fontWeight: '800', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
              GPS Verified Sellers Only
            </span>
          </div>
          <h3 style={{ fontSize: '16px', fontWeight: '800', lineHeight: '1.2', marginBottom: '6px' }}>
            Belanja Lokal Lebih Aman & Bebas Penipuan COD!
          </h3>
          <p style={{ fontSize: '11px', opacity: 0.9, lineHeight: '1.4' }}>
            Semua lokasi penjual divalidasi via GPS browser. Tidak ada manipulasi alamat demi privasi dan keamanan Anda.
          </p>
        </div>
        {/* Background Decorative Graphic */}
        <div style={{ position: 'absolute', right: '-10px', bottom: '-20px', fontSize: '80px', opacity: 0.15, pointerEvents: 'none' }}>
          🏪
        </div>
      </div>

      {/* Horizontal Category Slider */}
      <div style={{ marginBottom: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700' }}>Kategori Pilihan</h3>
        </div>
        
        <div 
          style={{ 
            display: 'flex', 
            gap: '8px', 
            overflowX: 'auto', 
            paddingBottom: '8px',
            scrollbarWidth: 'none',
            msOverflowStyle: 'none'
          }}
          className="no-scrollbar"
        >
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => onCategorySelect(cat)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 12px',
                borderRadius: '20px',
                backgroundColor: 'rgba(255, 255, 255, 0.04)',
                border: '1px solid rgba(255, 255, 255, 0.08)',
                color: '#ffffff',
                fontSize: '12px',
                fontWeight: '500',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                transition: 'all 0.15s ease'
              }}
              onMouseEnter={(e) => {
                e.target.style.backgroundColor = 'rgba(255, 255, 255, 0.08)';
                e.target.style.borderColor = 'rgba(255, 255, 255, 0.15)';
              }}
              onMouseLeave={(e) => {
                e.target.style.backgroundColor = 'rgba(255, 255, 255, 0.04)';
                e.target.style.borderColor = 'rgba(255, 255, 255, 0.08)';
              }}
            >
              <span>{CATEGORY_EMOJIS[cat] || '📦'}</span>
              <span>{cat}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Location Area Context Banner */}
      <div 
        style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'space-between',
          backgroundColor: 'rgba(255,255,255,0.02)',
          border: '1px solid rgba(255,255,255,0.04)',
          borderRadius: '10px',
          padding: '10px 14px',
          marginBottom: '16px'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '11px', color: 'hsl(var(--text-muted))' }}>
          <MapPin size={12} color="#10b981" />
          <span>Barang terdekat dari <strong>{userLocation.name || 'GPS Anda'}</strong></span>
        </div>
        <button 
          onClick={() => onNavigateToTab('search')}
          style={{ background: 'none', border: 'none', color: 'hsl(var(--primary))', fontSize: '11px', fontWeight: '600', cursor: 'pointer' }}
        >
          Radius Filter
        </button>
      </div>

      {/* Product Listings Section */}
      <div>
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '8px' }}>Rekomendasi Terdekat</h3>
        
        {publishedListings.length === 0 ? (
          <div className="glass-card" style={{ padding: '40px 10px', textAlign: 'center', color: 'hsl(var(--text-muted))' }}>
            <p style={{ fontSize: '13px' }}>Tidak ada barang terbit yang tersedia di wilayah ini.</p>
          </div>
        ) : (
          <div className="product-grid">
            {publishedListings.map((listing) => (
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
    </div>
  );
}
