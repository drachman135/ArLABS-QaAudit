// ProductDetailView Component - Full details with reviews and WhatsApp integration
import React, { useState } from 'react';
import { ArrowLeft, Heart, MapPin, Star, MessageSquare, ShieldAlert, Award, Send } from 'lucide-react';
import { calculateDistance } from '../utils/geo';
import { MockDB } from '../db/MockDB';

export default function ProductDetailView({ 
  product, 
  userLocation, 
  currentUser, 
  onBack, 
  onWishlistToggle, 
  isWishlisted,
  addToast,
  onUpdateListings
}) {
  const [isFollowing, setIsFollowing] = useState(
    currentUser ? MockDB.isFollowing(currentUser.id, product.sellerId) : false
  );
  
  // Reviews & Rating states
  const [reviews, setReviews] = useState(
    MockDB.getReviews().filter(r => r.sellerId === product.sellerId)
  );
  const [ratingInput, setRatingInput] = useState(5);
  const [reviewTextInput, setReviewTextInput] = useState('');
  const [hoveredStar, setHoveredStar] = useState(0);

  // Report states
  const [showReportModal, setShowReportModal] = useState(false);
  const [reportReason, setReportReason] = useState('Iklan Palsu');
  const [reportText, setReportText] = useState('');

  // Seller info
  const users = MockDB.getUsers();
  const seller = users.find(u => u.id === product.sellerId);

  if (!seller) {
    return (
      <div style={{ padding: '20px', textAlign: 'center' }}>
        <p>Penjual tidak ditemukan atau akun telah dihapus.</p>
        <button className="btn btn-secondary" onClick={onBack} style={{ marginTop: '10px' }}>
          Kembali
        </button>
      </div>
    );
  }

  // Distance calculation
  let distanceStr = '';
  if (userLocation.lat && seller.lat) {
    const dist = calculateDistance(userLocation.lat, userLocation.lng, seller.lat, seller.lng);
    if (dist !== null) {
      distanceStr = dist < 1 ? `${Math.round(dist * 1000)} m` : `${dist.toFixed(1)} km`;
    }
  }

  // Follow Seller toggle
  const handleFollowToggle = () => {
    if (!currentUser) {
      addToast('Silakan login terlebih dahulu untuk mengikuti toko.', 'error');
      return;
    }
    const followed = MockDB.toggleFollow(currentUser.id, seller.id);
    setIsFollowing(followed);
    addToast(followed ? `Berhasil mengikuti toko ${seller.shopName}!` : `Batal mengikuti toko ${seller.shopName}.`, 'success');
  };

  // Submit Review
  const handleReviewSubmit = (e) => {
    e.preventDefault();
    if (!currentUser) {
      addToast('Silakan login untuk memberikan ulasan.', 'error');
      return;
    }
    if (!reviewTextInput.trim()) {
      addToast('Teks ulasan tidak boleh kosong.', 'error');
      return;
    }

    const newRev = MockDB.addReview(
      seller.id,
      currentUser.name,
      ratingInput,
      reviewTextInput.trim()
    );

    setReviews([newRev, ...reviews]);
    setReviewTextInput('');
    addToast('Ulasan berhasil dikirim!', 'success');
  };

  // Submit Report
  const handleReportSubmit = (e) => {
    e.preventDefault();
    if (!currentUser) {
      addToast('Silakan login untuk membuat laporan.', 'error');
      return;
    }

    MockDB.addReport(product.id, currentUser.id, reportReason, reportText.trim());
    setShowReportModal(false);
    setReportText('');
    addToast('Laporan berhasil dikirim ke Admin untuk ditinjau.', 'success');
  };

  // WhatsApp link generation
  const handleContactWhatsApp = () => {
    const phoneNo = seller.phone.replace(/^0/, '62'); // format to international
    const priceFormatted = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(product.price);
    
    const templateText = `Halo ${seller.shopName}, saya tertarik membeli barang Anda "${product.title}" seharga ${priceFormatted} yang dipublish di LocalStore. Apakah masih tersedia dan bisa COD?`;
    const waUrl = `https://wa.me/${phoneNo}?text=${encodeURIComponent(templateText)}`;
    
    window.open(waUrl, '_blank');
  };

  const hasHighTrust = seller.trustScore >= 90;

  return (
    <div style={{ animation: 'fadeIn 0.25s', paddingBottom: '30px' }}>
      {/* Top Header Controls */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <button 
          onClick={onBack}
          style={{ background: 'none', border: 'none', color: '#ffffff', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
        >
          <ArrowLeft size={20} />
          <span style={{ fontSize: '14px', fontWeight: '600' }}>Kembali</span>
        </button>
        
        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            onClick={() => onWishlistToggle(product.id)}
            style={{
              background: 'rgba(255,255,255,0.06)',
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '50%',
              width: '36px',
              height: '36px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              color: isWishlisted ? 'hsl(var(--accent-red))' : '#ffffff'
            }}
          >
            <Heart size={18} fill={isWishlisted ? 'currentColor' : 'none'} />
          </button>
        </div>
      </div>

      {/* Main Image */}
      <div 
        style={{ 
          width: '100%', 
          height: '240px', 
          borderRadius: 'var(--radius-lg)', 
          overflow: 'hidden', 
          marginBottom: '16px',
          border: '1px solid rgba(255,255,255,0.08)',
          backgroundColor: '#131924'
        }}
      >
        <img 
          src={product.image} 
          alt={product.title} 
          style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
          onError={e => e.target.src = 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=600'}
        />
      </div>

      {/* Product Title & Basic Details */}
      <div style={{ marginBottom: '16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
          <span className="badge badge-verified" style={{ marginBottom: '6px' }}>{product.category}</span>
          <span style={{ fontSize: '11px', color: 'hsl(var(--text-muted))' }}>
            Diposting: {new Date(product.createdAt).toLocaleDateString('id-ID')}
          </span>
        </div>
        <h2 style={{ fontSize: '20px', fontWeight: '800', lineHeight: '1.3', color: '#ffffff' }}>
          {product.title}
        </h2>
        <div style={{ fontSize: '22px', fontWeight: '900', color: '#10b981', marginTop: '6px', marginBottom: '8px' }}>
          Rp {product.price.toLocaleString('id-ID')}
        </div>

        {/* Location & GPS Info */}
        <div 
          style={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: '8px', 
            backgroundColor: 'rgba(255,255,255,0.02)',
            padding: '10px 14px',
            borderRadius: '10px',
            border: '1px solid rgba(255,255,255,0.05)',
            fontSize: '12px'
          }}
        >
          <MapPin size={14} color="#10b981" />
          <div>
            <strong>Kelurahan {seller.kelurahan}</strong>
            {distanceStr && <span style={{ color: 'hsl(var(--text-muted))' }}> ({distanceStr} dari GPS Anda)</span>}
          </div>
        </div>
      </div>

      {/* Description */}
      <div className="glass-card" style={{ marginBottom: '20px' }}>
        <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '8px' }}>Deskripsi Barang</h3>
        <p style={{ fontSize: '13px', color: 'hsl(var(--text-muted))', lineHeight: '1.6', whiteSpace: 'pre-wrap' }}>
          {product.description}
        </p>
      </div>

      {/* Seller Profile Card */}
      <div className="glass-card" style={{ marginBottom: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
          <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <img src={seller.avatar} alt="avatar" style={{ width: '44px', height: '44px', borderRadius: '50%', border: '1.5px solid hsl(var(--primary))' }} />
            <div>
              <h4 style={{ fontSize: '14px', fontWeight: '700', color: '#ffffff' }}>{seller.shopName}</h4>
              <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))' }}>Pemilik: {seller.name}</p>
            </div>
          </div>
          <button 
            onClick={handleFollowToggle}
            className={`btn ${isFollowing ? 'btn-secondary' : 'btn-primary'}`}
            style={{ width: 'auto', padding: '6px 12px', fontSize: '11px' }}
          >
            {isFollowing ? 'Mengikuti' : '+ Ikuti'}
          </button>
        </div>

        {/* Trust Indicators */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: '12px', fontSize: '11px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
            <span style={{ color: 'hsl(var(--text-muted))' }}>Trust Score:</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Award size={14} color={hasHighTrust ? '#10b981' : '#f59e0b'} />
              <strong style={{ color: hasHighTrust ? '#10b981' : '#f59e0b', fontSize: '13px' }}>
                {seller.trustScore}%
              </strong>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
            <span style={{ color: 'hsl(var(--text-muted))' }}>Jumlah Pengikut:</span>
            <strong style={{ color: '#ffffff', fontSize: '13px' }}>
              {seller.followersCount} Pengikut
            </strong>
          </div>
        </div>
      </div>

      {/* Reviews & Ratings Section */}
      <div className="glass-card" style={{ marginBottom: '20px' }}>
        <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '6px' }}>
          <MessageSquare size={16} />
          <span>Ulasan Toko ({reviews.length})</span>
        </h3>

        {/* Add Review Form */}
        {currentUser && currentUser.id !== seller.id && (
          <form onSubmit={handleReviewSubmit} style={{ borderBottom: '1px solid rgba(255,255,255,0.08)', paddingBottom: '16px', marginBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px' }}>
              <span style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', fontWeight: '600' }}>Beri Rating COD:</span>
              <div className="stars-display">
                {[1, 2, 3, 4, 5].map(starIndex => (
                  <Star 
                    key={starIndex}
                    size={16} 
                    className="star-interactive"
                    fill={starIndex <= (hoveredStar || ratingInput) ? '#fbbf24' : 'none'} 
                    color="#fbbf24"
                    onClick={() => setRatingInput(starIndex)}
                    onMouseEnter={() => setHoveredStar(starIndex)}
                    onMouseLeave={() => setHoveredStar(0)}
                  />
                ))}
              </div>
            </div>
            <div style={{ display: 'flex', gap: '6px' }}>
              <input 
                type="text" 
                className="form-input" 
                style={{ paddingLeft: '16px', fontSize: '12px' }}
                placeholder="Bagikan pengalaman transaksi COD Anda..."
                value={reviewTextInput}
                onChange={e => setReviewTextInput(e.target.value)}
              />
              <button type="submit" className="btn btn-primary" style={{ width: 'auto', padding: '12px' }}>
                <Send size={14} />
              </button>
            </div>
          </form>
        )}

        {/* Reviews List */}
        {reviews.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '10px', color: 'hsl(var(--text-muted))', fontSize: '12px' }}>
            Belum ada ulasan untuk penjual ini. Jadilah yang pertama setelah transaksi COD sukses!
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', maxHeight: '200px', overflowY: 'auto' }}>
            {reviews.map(rev => (
              <div key={rev.id} style={{ backgroundColor: 'rgba(255,255,255,0.02)', padding: '8px 12px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.04)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                  <span style={{ fontSize: '11px', fontWeight: '700' }}>{rev.reviewerName}</span>
                  <div className="stars-display">
                    {[1, 2, 3, 4, 5].map(s => (
                      <Star key={s} size={8} fill={s <= rev.rating ? '#fbbf24' : 'none'} color="#fbbf24" />
                    ))}
                  </div>
                </div>
                <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', lineHeight: '1.4' }}>
                  {rev.text}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Primary Action Row */}
      <div style={{ display: 'flex', gap: '8px' }}>
        <button 
          onClick={() => setShowReportModal(true)}
          className="btn btn-secondary" 
          style={{ width: '60px', padding: '12px', display: 'flex', justifyContent: 'center', border: '1px solid rgba(239,68,68,0.2)', color: 'hsl(var(--accent-red))' }}
          title="Laporkan barang"
        >
          <ShieldAlert size={18} />
        </button>
        <button 
          onClick={handleContactWhatsApp}
          className="btn btn-whatsapp" 
          style={{ flex: 1 }}
        >
          Hubungi via WhatsApp
        </button>
      </div>

      {/* Report Modal Sheet */}
      {showReportModal && (
        <div className="modal-overlay" onClick={() => setShowReportModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ paddingBottom: '30px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '800', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <ShieldAlert color="hsl(var(--accent-red))" size={18} />
              <span>Laporkan Iklan Ini</span>
            </h3>
            <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))', marginBottom: '16px' }}>
              Bantu kami menjaga LocalStore tetap aman. Pilih alasan pelaporan di bawah ini.
            </p>

            <form onSubmit={handleReportSubmit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '20px' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Alasan Utama</label>
                  <select 
                    className="form-select"
                    value={reportReason}
                    onChange={e => setReportReason(e.target.value)}
                  >
                    <option value="Iklan Palsu">Iklan Palsu / Lokasi Palsu</option>
                    <option value="Barang Terlarang">Barang Terlarang / Ilegal</option>
                    <option value="Penipuan/Scam">Indikasi Penipuan / Scam</option>
                    <option value="Lainnya">Lainnya</option>
                  </select>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Detail Penjelasan</label>
                  <textarea 
                    className="form-input"
                    style={{ padding: '12px', height: '80px', resize: 'none' }}
                    placeholder="Tuliskan alasan detail mengapa Anda melaporkan iklan ini..."
                    value={reportText}
                    onChange={e => setReportText(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div style={{ display: 'flex', gap: '8px' }}>
                <button 
                  type="button"
                  className="btn btn-secondary" 
                  onClick={() => setShowReportModal(false)}
                  style={{ flex: 1 }}
                >
                  Batal
                </button>
                <button 
                  type="submit" 
                  className="btn btn-danger"
                  style={{ flex: 1 }}
                >
                  Kirim Laporan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
