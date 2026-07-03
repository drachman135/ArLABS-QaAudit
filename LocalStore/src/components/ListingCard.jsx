// ListingCard Component to display items in feed grids
import React from 'react';
import { Heart, MapPin, ShieldAlert, Star } from 'lucide-react';
import { calculateDistance } from '../utils/geo';
import { MockDB } from '../db/MockDB';

export default function ListingCard({ listing, userLocation, currentUser, onSelect, onWishlistToggle, isWishlisted }) {
  // Find seller info for location and trust score
  const users = MockDB.getUsers();
  const seller = users.find(u => u.id === listing.sellerId);

  // Format currency
  const formatPrice = (price) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
  };

  // Calculate distance
  let distanceStr = '';
  let distanceValue = null;
  if (userLocation.lat && seller && seller.lat) {
    distanceValue = calculateDistance(
      userLocation.lat,
      userLocation.lng,
      seller.lat,
      seller.lng
    );
    if (distanceValue !== null) {
      distanceStr = distanceValue < 1 
        ? `${Math.round(distanceValue * 1000)} m` 
        : `${distanceValue.toFixed(1)} km`;
    }
  }

  const handleWishlistClick = (e) => {
    e.stopPropagation();
    if (!currentUser) {
      alert('Silakan login terlebih dahulu untuk menyimpan ke favorit.');
      return;
    }
    onWishlistToggle(listing.id);
  };

  const hasHighTrust = seller && seller.trustScore >= 90;

  return (
    <div 
      className="glass-card" 
      onClick={() => onSelect(listing)}
      style={{
        padding: '0',
        borderRadius: 'var(--radius-md)',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        cursor: 'pointer',
        position: 'relative',
        height: '100%',
        margin: '0',
        border: '1px solid rgba(255, 255, 255, 0.05)'
      }}
    >
      {/* Product Image */}
      <div style={{ position: 'relative', width: '100%', paddingTop: '75%', backgroundColor: '#131924' }}>
        <img 
          src={listing.image} 
          alt={listing.title} 
          onError={(e) => {
            // Fallback if image fails to load
            e.target.src = 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=400';
          }}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            objectFit: 'cover'
          }}
        />

        {/* Favorite Button */}
        <button
          onClick={handleWishlistClick}
          style={{
            position: 'absolute',
            top: '8px',
            right: '8px',
            background: 'rgba(11, 15, 25, 0.6)',
            backdropFilter: 'blur(8px)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            borderRadius: '50%',
            width: '32px',
            height: '32px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            zIndex: 5,
            color: isWishlisted ? 'hsl(var(--accent-red))' : '#ffffff',
            transition: 'transform 0.15s ease'
          }}
          onMouseDown={(e) => e.target.style.transform = 'scale(0.85)'}
          onMouseUp={(e) => e.target.style.transform = 'scale(1)'}
        >
          <Heart size={16} fill={isWishlisted ? 'currentColor' : 'none'} />
        </button>

        {/* Distance Badge */}
        {distanceStr && (
          <div
            style={{
              position: 'absolute',
              bottom: '8px',
              left: '8px',
              backgroundColor: 'rgba(11, 15, 25, 0.75)',
              backdropFilter: 'blur(8px)',
              padding: '2px 8px',
              borderRadius: '6px',
              fontSize: '10px',
              fontWeight: '700',
              color: 'hsl(var(--primary))',
              border: '1px solid rgba(16, 185, 129, 0.2)',
              display: 'flex',
              alignItems: 'center',
              gap: '3px'
            }}
          >
            <MapPin size={10} />
            <span>{distanceStr}</span>
          </div>
        )}
      </div>

      {/* Listing Content */}
      <div style={{ padding: '12px', display: 'flex', flexDirection: 'column', flexGrow: 1, justifyContent: 'space-between', gap: '8px' }}>
        <div>
          {/* Kelurahan Badge */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '4px' }}>
            <span style={{ fontSize: '10px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>
              {seller ? seller.kelurahan : 'Lokasi Tidak Diketahui'}
            </span>
          </div>

          <h3 
            style={{ 
              fontSize: '13px', 
              fontWeight: '600', 
              lineHeight: '1.4', 
              maxHeight: '38px', 
              overflow: 'hidden', 
              textOverflow: 'ellipsis', 
              display: '-webkit-box', 
              WebkitLineClamp: 2, 
              WebkitBoxOrient: 'vertical',
              color: '#ffffff',
              marginBottom: '4px'
            }}
            title={listing.title}
          >
            {listing.title}
          </h3>
        </div>

        <div>
          <div style={{ fontSize: '15px', fontWeight: '800', color: '#10b981', marginBottom: '6px' }}>
            {formatPrice(listing.price)}
          </div>

          {/* Seller Trust Bar */}
          {seller && (
            <div 
              style={{ 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'space-between',
                borderTop: '1px solid rgba(255, 255, 255, 0.05)',
                paddingTop: '6px',
                fontSize: '10px',
                color: 'hsl(var(--text-muted))'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '2px' }}>
                <Star size={10} fill="#fbbf24" color="#fbbf24" />
                <span>Score: <strong style={{ color: hasHighTrust ? '#10b981' : '#f59e0b' }}>{seller.trustScore}%</strong></span>
              </div>
              
              {hasHighTrust ? (
                <span style={{ color: '#10b981', fontWeight: '700', fontSize: '9px' }}>TRUSTED</span>
              ) : (
                <span style={{ color: '#f59e0b', fontWeight: '700', fontSize: '9px' }}>REGULAR</span>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
