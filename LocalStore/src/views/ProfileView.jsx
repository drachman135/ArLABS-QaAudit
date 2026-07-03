// ProfileView Component - User profile info, wishlist bookmarks, and database resets
import React from 'react';
import { Shield, Heart, Store, RotateCcw, AlertTriangle, ArrowRight } from 'lucide-react';
import { MockDB } from '../db/MockDB';

export default function ProfileView({ 
  currentUser, 
  listings, 
  wishlistedIds, 
  onSelectProduct, 
  onWishlistToggle,
  onNavigateToTab, 
  onResetDB 
}) {
  const users = MockDB.getUsers();

  // Get wishlisted products
  const wishlistedItems = listings.filter(l => wishlistedIds.includes(l.id));

  // Find followed shops/sellers
  const followedSellers = users.filter(u => 
    u.sellerStatus === 'approved' && MockDB.isFollowing(currentUser.id, u.id)
  );

  const isSeller = currentUser && currentUser.sellerStatus === 'approved';
  const isAdmin = currentUser && currentUser.role === 'admin';

  return (
    <div style={{ animation: 'fadeIn 0.25s' }}>
      {/* Profile Card Summary */}
      <div className="glass-card" style={{ display: 'flex', gap: '16px', alignItems: 'center', marginBottom: '20px' }}>
        <img 
          src={currentUser.avatar} 
          alt={currentUser.name} 
          style={{ 
            width: '64px', 
            height: '64px', 
            borderRadius: '50%', 
            border: '2px solid hsl(var(--primary))',
            backgroundColor: 'rgba(255,255,255,0.02)'
          }} 
        />
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#ffffff' }}>{currentUser.name}</h3>
          <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))' }}>{currentUser.email || 'No Email Registered'}</p>
          
          <div style={{ display: 'flex', gap: '4px', marginTop: '6px' }}>
            {isAdmin && (
              <span className="badge" style={{ backgroundColor: 'rgba(245,158,11,0.1)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.2)' }}>
                🛡️ Admin
              </span>
            )}
            {isSeller ? (
              <span className="badge badge-verified">🏪 Seller ({currentUser.kelurahan})</span>
            ) : (
              !isAdmin && <span className="badge" style={{ backgroundColor: 'rgba(255,255,255,0.06)', color: 'hsl(var(--text-muted))', border: '1px solid rgba(255,255,255,0.1)' }}>👤 Pembeli</span>
            )}
            {currentUser.sellerStatus === 'pending' && (
              <span className="badge badge-pending">⏳ Menunggu Kurasi</span>
            )}
          </div>
        </div>
      </div>

      {/* Seller Dashboard / Onboarding CTA */}
      {!isAdmin && (
        <div className="glass-card" style={{ padding: '16px', border: '1px dashed hsl(var(--primary))', marginBottom: '20px' }}>
          {isSeller ? (
            <div>
              <h4 style={{ fontSize: '13px', fontWeight: '800', color: '#ffffff', marginBottom: '4px' }}>Toko Anda Aktif</h4>
              <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', marginBottom: '12px' }}>
                Anda terdaftar sebagai seller di wilayah <strong>{currentUser.kelurahan}</strong>. Kelola stok barang Anda di Dashboard Seller.
              </p>
              <button 
                onClick={() => onNavigateToTab('sell')}
                className="btn btn-primary" 
                style={{ fontSize: '12px', padding: '8px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
              >
                <span>Buka Dashboard Toko Saya</span>
                <ArrowRight size={14} />
              </button>
            </div>
          ) : currentUser.sellerStatus === 'pending' ? (
            <div>
              <h4 style={{ fontSize: '13px', fontWeight: '800', color: '#f59e0b', marginBottom: '4px' }}>Toko Sedang Direview</h4>
              <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', marginBottom: '12px' }}>
                Pengajuan toko "{currentUser.shopName}" di wilayah <strong>{currentUser.kelurahan}</strong> sedang ditinjau. Anda akan diberitahu jika disetujui.
              </p>
              <button 
                onClick={() => onNavigateToTab('sell')}
                className="btn btn-secondary" 
                style={{ fontSize: '12px', padding: '8px 16px' }}
              >
                Lihat Detail Pengajuan
              </button>
            </div>
          ) : (
            <div>
              <h4 style={{ fontSize: '13px', fontWeight: '800', color: '#ffffff', marginBottom: '4px' }}>Ingin Mulai Jual Barang?</h4>
              <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', marginBottom: '12px' }}>
                Daftar sebagai seller LocalStore dalam 2 menit! Wajib verifikasi OTP HP & validasi koordinat GPS wilayah Anda.
              </p>
              <button 
                onClick={() => onNavigateToTab('sell')}
                className="btn btn-primary" 
                style={{ fontSize: '12px', padding: '8px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
              >
                <span>Daftar Onboarding Seller</span>
                <ArrowRight size={14} />
              </button>
            </div>
          )}
        </div>
      )}

      {/* Followed Sellers */}
      <div className="glass-card" style={{ marginBottom: '20px' }}>
        <h4 style={{ fontSize: '13px', fontWeight: '800', marginBottom: '10px', color: '#ffffff' }}>Toko Favorit Diikuti ({followedSellers.length})</h4>
        {followedSellers.length === 0 ? (
          <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))' }}>Belum mengikuti toko manapun.</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {followedSellers.map(s => (
              <div 
                key={s.id} 
                style={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center', 
                  padding: '8px 12px', 
                  backgroundColor: 'rgba(255,255,255,0.02)', 
                  borderRadius: '8px',
                  border: '1px solid rgba(255,255,255,0.04)'
                }}
              >
                <div>
                  <span style={{ fontSize: '12px', fontWeight: '700', color: '#ffffff' }}>{s.shopName}</span>
                  <div style={{ fontSize: '10px', color: 'hsl(var(--text-muted))' }}>Wilayah: {s.kelurahan} | Trust: {s.trustScore}%</div>
                </div>
                <button 
                  onClick={() => onNavigateToTab('search')} 
                  style={{ background: 'none', border: 'none', color: 'hsl(var(--primary))', fontSize: '10px', fontWeight: '600', cursor: 'pointer' }}
                >
                  Lihat Barang
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Wishlisted Items list */}
      <div className="glass-card" style={{ marginBottom: '20px' }}>
        <h4 style={{ fontSize: '13px', fontWeight: '800', marginBottom: '10px', color: '#ffffff', display: 'flex', alignItems: 'center', gap: '4px' }}>
          <Heart size={14} fill="hsl(var(--accent-red))" color="hsl(var(--accent-red))" />
          <span>Barang Disimpan ({wishlistedItems.length})</span>
        </h4>
        {wishlistedItems.length === 0 ? (
          <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))' }}>Tidak ada barang yang disimpan.</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {wishlistedItems.map(item => (
              <div 
                key={item.id} 
                onClick={() => onSelectProduct(item)}
                style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '10px', 
                  padding: '8px', 
                  backgroundColor: 'rgba(255,255,255,0.02)', 
                  borderRadius: '8px',
                  cursor: 'pointer',
                  border: '1px solid rgba(255,255,255,0.04)'
                }}
              >
                <img src={item.image} alt={item.title} style={{ width: '36px', height: '36px', borderRadius: '4px', objectFit: 'cover' }} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: '12px', fontWeight: '700', color: '#ffffff', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>{item.title}</div>
                  <div style={{ fontSize: '11px', color: '#10b981', fontWeight: '600' }}>Rp {item.price.toLocaleString('id-ID')}</div>
                </div>
                <button 
                  onClick={(e) => { e.stopPropagation(); onWishlistToggle(item.id); }}
                  style={{ background: 'none', border: 'none', color: 'hsl(var(--accent-red))', cursor: 'pointer', padding: '4px' }}
                >
                  Hapus
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Developer Utilities / Database reset */}
      <div className="glass-card" style={{ border: '1px solid rgba(239,68,68,0.2)', backgroundColor: 'rgba(239,68,68,0.03)' }}>
        <h4 style={{ fontSize: '13px', fontWeight: '800', color: 'hsl(var(--accent-red))', display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '4px' }}>
          <AlertTriangle size={14} />
          <span>Utilitas Developer (Demo)</span>
        </h4>
        <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', lineHeight: '1.4', marginBottom: '12px' }}>
          Gunakan tombol di bawah untuk menyetel ulang database LocalStorage ke pengaturan awal (menghapus postingan baru, menyetel akun default Joko, dsb).
        </p>
        <button 
          onClick={onResetDB}
          className="btn btn-secondary" 
          style={{ fontSize: '11px', padding: '8px 12px', border: '1px solid rgba(239,68,68,0.3)', color: 'hsl(var(--accent-red))', display: 'flex', gap: '6px', alignItems: 'center', justifyContent: 'center' }}
        >
          <RotateCcw size={12} />
          Reset Database Simulasi
        </button>
      </div>
    </div>
  );
}
