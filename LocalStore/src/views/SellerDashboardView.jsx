// SellerDashboardView Component - Store dashboard & inventory manager
import React, { useState } from 'react';
import { Plus, Trash, Check, Eye, Archive, Star, Users, FolderOpen, X } from 'lucide-react';
import { MockDB } from '../db/MockDB';

const PRESET_IMAGES = [
  { name: '🔌 Elektronik (Kipas)', url: 'https://images.unsplash.com/photo-1618945032043-c793132e4d0d?w=400' },
  { name: '🚲 Sepeda Gunung', url: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=400' },
  { name: '👕 Jaket Bomber', url: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400' },
  { name: '🏠 Piring Keramik', url: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400' },
  { name: '📱 iPhone 12 Pro', url: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400' }
];

export default function SellerDashboardView({ 
  currentUser, 
  listings, 
  categories, 
  addToast, 
  onUpdateListings 
}) {
  const [showAddModal, setShowAddModal] = useState(false);
  const [title, setTitle] = useState('');
  const [price, setPrice] = useState('');
  const [category, setCategory] = useState(categories[0] || 'Lain-lain');
  const [description, setDescription] = useState('');
  const [image, setImage] = useState(PRESET_IMAGES[0].url);

  // Filter listings owned by this seller
  const sellerListings = listings.filter(l => l.sellerId === currentUser.id);

  // Actions
  const handleAddProduct = (e) => {
    e.preventDefault();
    const priceNum = parseInt(price);
    if (!title || isNaN(priceNum) || priceNum <= 0) {
      addToast('Data produk tidak valid. Periksa judul dan harga.', 'error');
      return;
    }

    const newListing = MockDB.addListing({
      title,
      price: priceNum,
      category,
      description,
      image,
      sellerId: currentUser.id
    });

    onUpdateListings(); // Trigger state refresh in App.jsx
    setShowAddModal(false);
    
    // Clear inputs
    setTitle('');
    setPrice('');
    setDescription('');
    setImage(PRESET_IMAGES[0].url);
    
    addToast(`Barang "${title}" sukses diajukan! Menunggu persetujuan Admin.`, 'success');
  };

  const handleMarkSold = (id) => {
    MockDB.updateListing(id, { status: 'sold' });
    onUpdateListings();
    addToast('Barang berhasil ditandai sebagai TERJUAL!', 'success');
  };

  const handleArchive = (id) => {
    MockDB.updateListing(id, { status: 'archived' });
    onUpdateListings();
    addToast('Barang berhasil diarsipkan.', 'success');
  };

  const handlePublishAgain = (id) => {
    // Submitting again sends it to pending approval
    MockDB.updateListing(id, { status: 'pending' });
    onUpdateListings();
    addToast('Barang diajukan kembali ke antrean persetujuan Admin.', 'success');
  };

  const handleDelete = (id) => {
    if (window.confirm('Apakah Anda yakin ingin menghapus barang ini secara permanen?')) {
      MockDB.deleteListing(id);
      onUpdateListings();
      addToast('Barang berhasil dihapus.', 'success');
    }
  };

  return (
    <div style={{ animation: 'fadeIn 0.25s' }}>
      {/* Store Statistics Row */}
      <div 
        style={{ 
          display: 'grid', 
          gridTemplateColumns: '1fr 1fr 1fr', 
          gap: '8px', 
          marginBottom: '20px' 
        }}
      >
        <div className="glass-card" style={{ padding: '12px 8px', textAlign: 'center', margin: '0' }}>
          <div style={{ color: '#fbbf24', display: 'flex', justifyContent: 'center', marginBottom: '4px' }}>
            <Star size={18} fill="#fbbf24" />
          </div>
          <span style={{ fontSize: '10px', color: 'hsl(var(--text-muted))' }}>Trust Score</span>
          <div style={{ fontSize: '15px', fontWeight: '800', marginTop: '2px', color: '#ffffff' }}>
            {currentUser.trustScore}%
          </div>
        </div>

        <div className="glass-card" style={{ padding: '12px 8px', textAlign: 'center', margin: '0' }}>
          <div style={{ color: 'hsl(var(--primary))', display: 'flex', justifyContent: 'center', marginBottom: '4px' }}>
            <FolderOpen size={18} />
          </div>
          <span style={{ fontSize: '10px', color: 'hsl(var(--text-muted))' }}>Iklan Aktif</span>
          <div style={{ fontSize: '15px', fontWeight: '800', marginTop: '2px', color: '#ffffff' }}>
            {sellerListings.filter(l => l.status === 'published').length}
          </div>
        </div>

        <div className="glass-card" style={{ padding: '12px 8px', textAlign: 'center', margin: '0' }}>
          <div style={{ color: '#3b82f6', display: 'flex', justifyContent: 'center', marginBottom: '4px' }}>
            <Users size={18} />
          </div>
          <span style={{ fontSize: '10px', color: 'hsl(var(--text-muted))' }}>Pengikut</span>
          <div style={{ fontSize: '15px', fontWeight: '800', marginTop: '2px', color: '#ffffff' }}>
            {currentUser.followersCount}
          </div>
        </div>
      </div>

      {/* Product Management Title Row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <h3 style={{ fontSize: '15px', fontWeight: '700' }}>Manajemen Iklan Anda</h3>
        <button 
          onClick={() => setShowAddModal(true)}
          className="btn btn-primary" 
          style={{ width: 'auto', padding: '8px 12px', fontSize: '12px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '4px' }}
        >
          <Plus size={14} /> Tambah Barang
        </button>
      </div>

      {/* Inventory Listings List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {sellerListings.length === 0 ? (
          <div className="glass-card" style={{ padding: '40px 10px', textAlign: 'center', color: 'hsl(var(--text-muted))' }}>
            <p style={{ fontSize: '13px' }}>Anda belum memiliki iklan barang.</p>
            <button 
              className="btn btn-primary" 
              onClick={() => setShowAddModal(true)}
              style={{ width: 'auto', margin: '12px auto 0 auto', padding: '8px 16px', fontSize: '12px' }}
            >
              Mulai Jual Sekarang
            </button>
          </div>
        ) : (
          sellerListings.map(list => {
            const isPending = list.status === 'pending';
            const isPublished = list.status === 'published';
            const isSold = list.status === 'sold';
            const isArchived = list.status === 'archived';

            return (
              <div 
                key={list.id} 
                className="glass-card" 
                style={{ 
                  padding: '12px', 
                  margin: '0', 
                  display: 'flex', 
                  gap: '12px',
                  alignItems: 'center',
                  borderLeft: isPending ? '4px solid #f59e0b' : isPublished ? '4px solid #10b981' : isSold ? '4px solid #3b82f6' : '4px solid #64748b'
                }}
              >
                {/* Product Thumbnail */}
                <img 
                  src={list.image} 
                  alt={list.title} 
                  onError={e => e.target.src = 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=200'}
                  style={{ width: '56px', height: '56px', borderRadius: '8px', objectFit: 'cover', backgroundColor: '#131924' }} 
                />

                {/* Listing Metadata */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h4 style={{ fontSize: '13px', fontWeight: '700', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap', color: '#ffffff' }}>
                    {list.title}
                  </h4>
                  <div style={{ fontSize: '12px', fontWeight: '800', color: '#10b981', marginTop: '2px' }}>
                    Rp {list.price.toLocaleString('id-ID')}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px' }}>
                    {isPublished && <span className="badge badge-verified" style={{ fontSize: '8px', padding: '1px 4px' }}>Terbit</span>}
                    {isPending && <span className="badge badge-pending" style={{ fontSize: '8px', padding: '1px 4px' }}>Menunggu Admin</span>}
                    {isSold && <span className="badge" style={{ backgroundColor: 'rgba(59,130,246,0.1)', color: '#3b82f6', border: '1px solid rgba(59,130,246,0.2)', fontSize: '8px', padding: '1px 4px' }}>Terjual</span>}
                    {isArchived && <span className="badge badge-danger" style={{ fontSize: '8px', padding: '1px 4px' }}>Diarsipkan</span>}
                  </div>
                </div>

                {/* Inline Action Controls */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  {isPublished && (
                    <>
                      <button 
                        onClick={() => handleMarkSold(list.id)}
                        style={{ background: 'rgba(59,130,246,0.1)', border: 'none', color: '#3b82f6', borderRadius: '4px', padding: '4px 8px', fontSize: '9px', fontWeight: '700', cursor: 'pointer' }}
                      >
                        Terjual
                      </button>
                      <button 
                        onClick={() => handleArchive(list.id)}
                        style={{ background: 'rgba(255,255,255,0.04)', border: 'none', color: 'hsl(var(--text-muted))', borderRadius: '4px', padding: '4px 8px', fontSize: '9px', fontWeight: '700', cursor: 'pointer' }}
                      >
                        Arsipkan
                      </button>
                    </>
                  )}

                  {(isSold || isArchived) && (
                    <button 
                      onClick={() => handlePublishAgain(list.id)}
                      style={{ background: 'rgba(16,185,129,0.1)', border: 'none', color: '#10b981', borderRadius: '4px', padding: '4px 8px', fontSize: '9px', fontWeight: '700', cursor: 'pointer' }}
                    >
                      Jual Lagi
                    </button>
                  )}

                  <button 
                    onClick={() => handleDelete(list.id)}
                    style={{ background: 'rgba(239,68,68,0.1)', border: 'none', color: '#ef4444', borderRadius: '4px', padding: '4px 8px', fontSize: '9px', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '2px' }}
                  >
                    <Trash size={8} /> Hapus
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Add Product Modal Sheet */}
      {showAddModal && (
        <div className="modal-overlay" onClick={() => setShowAddModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ paddingBottom: '30px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ fontSize: '16px', fontWeight: '800' }}>Pasang Iklan Barang Baru</h3>
              <button onClick={() => setShowAddModal(false)} style={{ background: 'none', border: 'none', color: 'hsl(var(--text-muted))', cursor: 'pointer' }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleAddProduct}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '20px' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Judul Barang</label>
                  <input 
                    className="form-input" 
                    style={{ paddingLeft: '16px' }}
                    placeholder="Contoh: Sepeda Lipat Polygon Sero" 
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    required
                  />
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Harga Barang (Rupiah)</label>
                  <input 
                    className="form-input" 
                    style={{ paddingLeft: '16px' }}
                    type="number"
                    placeholder="Contoh: 150000" 
                    value={price}
                    onChange={e => setPrice(e.target.value)}
                    required
                  />
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Kategori</label>
                  <select 
                    className="form-select"
                    value={category}
                    onChange={e => setCategory(e.target.value)}
                  >
                    {categories.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>

                {/* Preset Image Chooser for Quick Testing */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Pilih Foto Demo (Gampang Coba)</label>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '4px' }}>
                    {PRESET_IMAGES.map((imgOpt) => {
                      const isSelected = image === imgOpt.url;
                      return (
                        <button
                          key={imgOpt.name}
                          type="button"
                          onClick={() => setImage(imgOpt.url)}
                          style={{
                            backgroundColor: isSelected ? 'hsl(var(--primary-glow))' : 'rgba(255,255,255,0.03)',
                            border: isSelected ? '1.5px solid hsl(var(--primary))' : '1px solid rgba(255,255,255,0.08)',
                            color: isSelected ? '#10b981' : 'hsl(var(--text-muted))',
                            padding: '6px',
                            fontSize: '9px',
                            fontWeight: isSelected ? '700' : 'normal',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            textAlign: 'left',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis'
                          }}
                        >
                          {imgOpt.name}
                        </button>
                      );
                    })}
                  </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                  <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Deskripsi Barang</label>
                  <textarea 
                    className="form-input"
                    style={{ padding: '10px 16px', height: '90px', resize: 'none' }}
                    placeholder="Tuliskan kondisi barang, kelengkapan, minus, dan lokasi ketemuan COD..." 
                    value={description}
                    onChange={e => setDescription(e.target.value)}
                    required
                  />
                </div>
              </div>

              <button type="submit" className="btn btn-primary">
                Ajukan Iklan Barang
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
