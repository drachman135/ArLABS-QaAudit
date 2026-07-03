// AdminPanel Component - Content Moderation & Configuration Panel
import React, { useState } from 'react';
import { Users, FileText, FolderPlus, AlertTriangle, Check, X, ShieldAlert, Trash, Ban } from 'lucide-react';
import { MockDB } from '../db/MockDB';

export default function AdminPanel({ currentUser, addToast, onUpdateListings }) {
  const [activeSubTab, setActiveSubTab] = useState('sellers');
  const [newCategory, setNewCategory] = useState('');

  // Fetch reactive data from MockDB
  const users = MockDB.getUsers();
  const listings = MockDB.getListings();
  const categories = MockDB.getCategories();
  const reports = MockDB.getReports();

  // Filters
  const pendingSellers = users.filter(u => u.sellerStatus === 'pending');
  const pendingListings = listings.filter(l => l.status === 'pending');
  const activeReports = reports.filter(r => r.status === 'pending');

  // Actions: Sellers
  const handleApproveSeller = (userId) => {
    const seller = users.find(u => u.id === userId);
    MockDB.updateUserProfile(userId, {
      sellerStatus: 'approved',
      role: 'seller' // Upgrade to seller role
    });
    onUpdateListings();
    addToast(`Toko "${seller.shopName}" berhasil disetujui!`, 'success');
  };

  const handleRejectSeller = (userId) => {
    const seller = users.find(u => u.id === userId);
    MockDB.updateUserProfile(userId, {
      sellerStatus: 'none',
      shopName: '',
      shopDescription: '',
      phone: ''
    });
    onUpdateListings();
    addToast(`Pengajuan Toko "${seller?.shopName || 'User'}" ditolak.`, 'error');
  };

  // Actions: Listings
  const handleApproveListing = (listingId) => {
    const listing = listings.find(l => l.id === listingId);
    MockDB.updateListing(listingId, { status: 'published' });
    onUpdateListings();
    addToast(`Iklan "${listing.title}" disetujui & dipublikasikan!`, 'success');
  };

  const handleRejectListing = (listingId) => {
    const listing = listings.find(l => l.id === listingId);
    MockDB.updateListing(listingId, { status: 'archived' });
    onUpdateListings();
    addToast(`Iklan "${listing.title}" ditolak & diarsipkan.`, 'error');
  };

  // Actions: Categories
  const handleAddCategory = (e) => {
    e.preventDefault();
    if (!newCategory.trim()) return;
    if (categories.includes(newCategory.trim())) {
      addToast('Kategori sudah ada.', 'error');
      return;
    }
    const updated = [...categories, newCategory.trim()];
    MockDB.saveCategories(updated);
    setNewCategory('');
    onUpdateListings();
    addToast('Kategori baru ditambahkan!', 'success');
  };

  const handleDeleteCategory = (catName) => {
    const updated = categories.filter(c => c !== catName);
    MockDB.saveCategories(updated);
    onUpdateListings();
    addToast('Kategori berhasil dihapus.', 'success');
  };

  // Actions: Reports
  const handleDismissReport = (reportId) => {
    // Resolve report
    const reps = MockDB.getReports();
    const index = reps.findIndex(r => r.id === reportId);
    if (index !== -1) {
      reps[index].status = 'resolved';
      MockDB.saveReports(reps);
    }
    onUpdateListings();
    addToast('Laporan diabaikan (dinyatakan aman).', 'success');
  };

  const handleBlockListing = (reportId, listingId) => {
    // 1. Mark listing as archived/removed
    MockDB.updateListing(listingId, { status: 'archived' });
    
    // 2. Resolve report
    const reps = MockDB.getReports();
    const index = reps.findIndex(r => r.id === reportId);
    if (index !== -1) {
      reps[index].status = 'resolved';
      MockDB.saveReports(reps);
    }
    onUpdateListings();
    addToast('Iklan berhasil diturunkan (archived).', 'success');
  };

  const handleBanSeller = (reportId, sellerId) => {
    // 1. Suspend Seller
    MockDB.updateUserProfile(sellerId, { sellerStatus: 'suspended' });
    
    // 2. Archive all listings by this seller
    const allListings = MockDB.getListings();
    const updatedListings = allListings.map(l => {
      if (l.sellerId === sellerId) {
        return { ...l, status: 'archived' };
      }
      return l;
    });
    MockDB.saveListings(updatedListings);

    // 3. Resolve report
    const reps = MockDB.getReports();
    const index = reps.findIndex(r => r.id === reportId);
    if (index !== -1) {
      reps[index].status = 'resolved';
      MockDB.saveReports(reps);
    }
    
    onUpdateListings();
    const seller = users.find(u => u.id === sellerId);
    addToast(`Penjual "${seller?.name || 'Toko'}" dan semua iklannya diblokir!`, 'error');
  };

  return (
    <div style={{ animation: 'fadeIn 0.3s' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
        <ShieldAlert color="#f59e0b" />
        <h2 style={{ fontSize: '20px', fontWeight: '800' }}>Panel Moderasi Admin</h2>
      </div>

      {/* Admin Tab Header */}
      <div 
        style={{ 
          display: 'flex', 
          backgroundColor: 'rgba(255,255,255,0.03)', 
          border: '1px solid rgba(255,255,255,0.06)', 
          borderRadius: '12px', 
          padding: '4px',
          marginBottom: '20px' 
        }}
      >
        <button
          onClick={() => setActiveSubTab('sellers')}
          style={{
            flex: 1,
            padding: '10px 4px',
            fontSize: '11px',
            fontWeight: '600',
            backgroundColor: activeSubTab === 'sellers' ? 'hsl(var(--bg-secondary))' : 'transparent',
            border: 'none',
            borderRadius: '8px',
            color: activeSubTab === 'sellers' ? '#ffffff' : 'hsl(var(--text-muted))',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '4px'
          }}
        >
          <Users size={12} />
          Sellers ({pendingSellers.length})
        </button>

        <button
          onClick={() => setActiveSubTab('listings')}
          style={{
            flex: 1,
            padding: '10px 4px',
            fontSize: '11px',
            fontWeight: '600',
            backgroundColor: activeSubTab === 'listings' ? 'hsl(var(--bg-secondary))' : 'transparent',
            border: 'none',
            borderRadius: '8px',
            color: activeSubTab === 'listings' ? '#ffffff' : 'hsl(var(--text-muted))',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '4px'
          }}
        >
          <FileText size={12} />
          Iklan ({pendingListings.length})
        </button>

        <button
          onClick={() => setActiveSubTab('categories')}
          style={{
            flex: 1,
            padding: '10px 4px',
            fontSize: '11px',
            fontWeight: '600',
            backgroundColor: activeSubTab === 'categories' ? 'hsl(var(--bg-secondary))' : 'transparent',
            border: 'none',
            borderRadius: '8px',
            color: activeSubTab === 'categories' ? '#ffffff' : 'hsl(var(--text-muted))',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '4px'
          }}
        >
          <FolderPlus size={12} />
          Kategori
        </button>

        <button
          onClick={() => setActiveSubTab('reports')}
          style={{
            flex: 1,
            padding: '10px 4px',
            fontSize: '11px',
            fontWeight: '600',
            backgroundColor: activeSubTab === 'reports' ? 'hsl(var(--bg-secondary))' : 'transparent',
            border: 'none',
            borderRadius: '8px',
            color: activeSubTab === 'reports' ? 'hsl(var(--accent-red))' : 'hsl(var(--text-muted))',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '4px'
          }}
        >
          <AlertTriangle size={12} />
          Laporan ({activeReports.length})
        </button>
      </div>

      {/* Subtab Contents */}
      {/* 1. Seller Moderation */}
      {activeSubTab === 'sellers' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {pendingSellers.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 10px', color: 'hsl(var(--text-muted))', fontSize: '13px' }}>
              Tidak ada pengajuan seller pending saat ini.
            </div>
          ) : (
            pendingSellers.map(seller => (
              <div key={seller.id} className="glass-card" style={{ padding: '16px', margin: '0' }}>
                <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}>
                  <img src={seller.avatar} alt="avatar" style={{ width: '40px', height: '40px', borderRadius: '50%', border: '1px solid rgba(255,255,255,0.1)' }} />
                  <div>
                    <h4 style={{ fontSize: '14px', fontWeight: '700' }}>{seller.shopName}</h4>
                    <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))' }}>Owner: {seller.name}</p>
                  </div>
                </div>
                
                <div style={{ backgroundColor: 'rgba(255,255,255,0.03)', padding: '10px', borderRadius: '8px', fontSize: '11px', display: 'flex', flexDirection: 'column', gap: '4px', marginBottom: '12px' }}>
                  <div>📞 <strong>HP/WA:</strong> {seller.phone}</div>
                  <div>📍 <strong>Lokasi:</strong> {seller.kelurahan} ({seller.lat?.toFixed(4)}, {seller.lng?.toFixed(4)})</div>
                  {seller.shopDescription && <div>📝 <strong>Deskripsi:</strong> {seller.shopDescription}</div>}
                </div>

                <div style={{ display: 'flex', gap: '8px' }}>
                  <button 
                    onClick={() => handleRejectSeller(seller.id)}
                    className="btn btn-secondary" 
                    style={{ flex: 1, padding: '8px 16px', display: 'flex', gap: '4px', color: 'hsl(var(--accent-red))' }}
                  >
                    <X size={14} /> Tolak
                  </button>
                  <button 
                    onClick={() => handleApproveSeller(seller.id)}
                    className="btn btn-primary" 
                    style={{ flex: 1, padding: '8px 16px', display: 'flex', gap: '4px' }}
                  >
                    <Check size={14} /> Setujui
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* 2. Listing Moderation */}
      {activeSubTab === 'listings' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {pendingListings.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 10px', color: 'hsl(var(--text-muted))', fontSize: '13px' }}>
              Tidak ada iklan baru yang butuh moderasi.
            </div>
          ) : (
            pendingListings.map(list => {
              const seller = users.find(u => u.id === list.sellerId);
              return (
                <div key={list.id} className="glass-card" style={{ padding: '12px', margin: '0', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <div style={{ display: 'flex', gap: '10px' }}>
                    <img src={list.image} alt={list.title} style={{ width: '70px', height: '70px', borderRadius: '8px', objectFit: 'cover' }} />
                    <div style={{ flex: 1 }}>
                      <span className="badge badge-pending" style={{ fontSize: '8px', padding: '2px 4px', marginBottom: '4px' }}>{list.category}</span>
                      <h4 style={{ fontSize: '13px', fontWeight: '700' }}>{list.title}</h4>
                      <div style={{ fontSize: '13px', fontWeight: '800', color: '#10b981', marginTop: '2px' }}>
                        Rp {list.price.toLocaleString('id-ID')}
                      </div>
                    </div>
                  </div>
                  
                  <div style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', backgroundColor: 'rgba(255,255,255,0.02)', padding: '8px', borderRadius: '6px' }}>
                    <div><strong>Penjual:</strong> {seller ? `${seller.shopName} (${seller.kelurahan})` : 'Unknown'}</div>
                    <div style={{ marginTop: '4px' }}><strong>Deskripsi:</strong> {list.description}</div>
                  </div>

                  <div style={{ display: 'flex', gap: '6px' }}>
                    <button 
                      onClick={() => handleRejectListing(list.id)}
                      className="btn btn-secondary" 
                      style={{ flex: 1, padding: '8px 12px', fontSize: '12px', display: 'flex', gap: '4px', color: 'hsl(var(--accent-red))' }}
                    >
                      <X size={14} /> Tolak
                    </button>
                    <button 
                      onClick={() => handleApproveListing(list.id)}
                      className="btn btn-primary" 
                      style={{ flex: 1, padding: '8px 12px', fontSize: '12px', display: 'flex', gap: '4px' }}
                    >
                      <Check size={14} /> Publikasikan
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}

      {/* 3. Category Manager */}
      {activeSubTab === 'categories' && (
        <div className="glass-card" style={{ padding: '16px', margin: '0' }}>
          <form onSubmit={handleAddCategory} style={{ display: 'flex', gap: '6px', marginBottom: '16px' }}>
            <input 
              className="form-input" 
              style={{ paddingLeft: '16px' }}
              type="text" 
              placeholder="Kategori Baru (misal: Mainan Anak)" 
              value={newCategory}
              onChange={e => setNewCategory(e.target.value)}
            />
            <button type="submit" className="btn btn-primary" style={{ width: 'auto', padding: '12px' }}>
              Tambah
            </button>
          </form>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {categories.map(cat => (
              <div 
                key={cat} 
                style={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center', 
                  padding: '10px 14px', 
                  backgroundColor: 'rgba(255,255,255,0.03)', 
                  border: '1px solid rgba(255,255,255,0.06)',
                  borderRadius: '10px' 
                }}
              >
                <span style={{ fontSize: '13px', fontWeight: '500' }}>{cat}</span>
                <button 
                  onClick={() => handleDeleteCategory(cat)}
                  style={{
                    background: 'transparent',
                    border: 'none',
                    color: 'hsl(var(--accent-red))',
                    cursor: 'pointer'
                  }}
                  title="Hapus Kategori"
                >
                  <Trash size={14} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 4. Report List */}
      {activeSubTab === 'reports' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {activeReports.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 10px', color: 'hsl(var(--text-muted))', fontSize: '13px' }}>
              Aman! Tidak ada laporan penyalahgunaan.
            </div>
          ) : (
            activeReports.map(rep => {
              const listing = listings.find(l => l.id === rep.listingId);
              const sellerId = listing ? listing.sellerId : null;
              const seller = sellerId ? users.find(u => u.id === sellerId) : null;
              const reporter = users.find(u => u.id === rep.reporterId);

              return (
                <div key={rep.id} className="glass-card" style={{ padding: '14px', margin: '0', border: '1px solid rgba(239,68,68,0.2)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span className="badge badge-danger" style={{ fontSize: '9px' }}>{rep.reason}</span>
                    <span style={{ fontSize: '9px', color: 'hsl(var(--text-muted))' }}>
                      {new Date(rep.createdAt).toLocaleDateString('id-ID')}
                    </span>
                  </div>

                  {listing ? (
                    <div style={{ backgroundColor: 'rgba(255,255,255,0.02)', padding: '10px', borderRadius: '8px', fontSize: '12px', marginBottom: '10px' }}>
                      <div><strong>Barang Terlapor:</strong> {listing.title}</div>
                      <div><strong>Toko Penjual:</strong> {seller ? `${seller.shopName} (${seller.kelurahan})` : 'Unknown'}</div>
                      <div style={{ marginTop: '4px', color: 'hsl(var(--text-muted))' }}>
                        <strong>Uraian Pelapor ({reporter?.name || 'User'}):</strong> "{rep.text}"
                      </div>
                    </div>
                  ) : (
                    <div style={{ color: 'hsl(var(--text-muted))', fontSize: '11px', marginBottom: '10px' }}>
                      Iklan yang dilaporkan sudah tidak tersedia (dihapus).
                    </div>
                  )}

                  <div style={{ display: 'flex', gap: '4px' }}>
                    <button 
                      onClick={() => handleDismissReport(rep.id)}
                      className="btn btn-secondary" 
                      style={{ flex: 1, padding: '6px', fontSize: '10px' }}
                    >
                      Abaikan
                    </button>
                    {listing && (
                      <>
                        <button 
                          onClick={() => handleBlockListing(rep.id, listing.id)}
                          className="btn btn-secondary" 
                          style={{ flex: 1, padding: '6px', fontSize: '10px', color: 'hsl(var(--accent-amber))', borderColor: 'rgba(245,158,11,0.2)' }}
                        >
                          <Trash size={10} /> Hapus Iklan
                        </button>
                        <button 
                          onClick={() => handleBanSeller(rep.id, sellerId)}
                          className="btn btn-danger" 
                          style={{ flex: 1, padding: '6px', fontSize: '10px', display: 'flex', gap: '2px', alignItems: 'center', justifyContent: 'center' }}
                        >
                          <Ban size={10} /> Ban Toko
                        </button>
                      </>
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}
    </div>
  );
}
