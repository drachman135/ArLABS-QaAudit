// App.jsx - Core Orchestrator for LocalStore App
import React, { useState, useEffect } from 'react';
import { Header, Navigation } from './components/Navigation';
import GPSSimulator from './components/GPSSimulator';
import HomeView from './views/HomeView';
import SearchView from './views/SearchView';
import ProductDetailView from './views/ProductDetailView';
import SellerDashboardView from './views/SellerDashboardView';
import SellerWizard from './components/SellerWizard';
import ProfileView from './views/ProfileView';
import AdminPanel from './components/AdminPanel';
import ListingCard from './components/ListingCard';
import { MockDB } from './db/MockDB';
import { Heart, MapPin, Bell } from 'lucide-react';

export default function App() {
  // 1. Initialize Mock Database
  useEffect(() => {
    MockDB.init();
  }, []);

  // 2. React States
  const [currentUser, setCurrentUser] = useState(() => MockDB.getLoggedInUser());
  const [listings, setListings] = useState(() => MockDB.getListings());
  const [categories, setCategories] = useState(() => MockDB.getCategories());
  const [activeTab, setActiveTab] = useState('home');
  const [selectedProduct, setSelectedProduct] = useState(null);
  
  // GPS Geolocation state
  const [userLocation, setUserLocation] = useState({
    lat: null,
    lng: null,
    name: '',
    isSimulated: false
  });

  // Category filter state carried over from Home feed click to Search feed
  const [searchCategoryFilter, setSearchCategoryFilter] = useState('Semua');

  // Notification Toasts
  const [toasts, setToasts] = useState([]);

  // 3. Notification Toast System
  const addToast = (message, type = 'success') => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, message, type }]);
    
    // Automatically dismiss after 4.5 seconds
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4500);
  };

  // Sync state modifications
  const handleUpdateListings = () => {
    setListings(MockDB.getListings());
    setCategories(MockDB.getCategories());
    
    // Refresh current user because their role/stats might change (e.g. followers)
    if (currentUser) {
      const freshUser = MockDB.getUsers().find(u => u.id === currentUser.id);
      setCurrentUser(freshUser);
    }
  };

  const handleUserChange = (newUser) => {
    MockDB.setLoggedInUser(newUser);
    setCurrentUser(newUser);
    setSelectedProduct(null);
    addToast(`Berhasil beralih profil ke: ${newUser.name}`, 'success');
  };

  const handleResetDB = () => {
    if (window.confirm('Setel ulang database ke pengaturan awal untuk pengujian?')) {
      MockDB.reset();
    }
  };

  // Retrieve user wishlist array
  const wishlistedIds = currentUser ? (MockDB.getWishlist()[currentUser.id] || []) : [];

  const handleWishlistToggle = (listingId) => {
    if (!currentUser) {
      addToast('Silakan login terlebih dahulu untuk menyimpan ke favorit.', 'error');
      return;
    }
    const updatedWishlist = MockDB.toggleWishlist(currentUser.id, listingId);
    setListings(MockDB.getListings()); // Force render cycle
    
    const isSaved = updatedWishlist.includes(listingId);
    addToast(isSaved ? 'Barang disimpan ke Favorit!' : 'Barang dihapus dari Favorit.', isSaved ? 'success' : 'warning');
  };

  const handleCategorySelectFromHome = (categoryName) => {
    setSearchCategoryFilter(categoryName);
    setActiveTab('search');
  };

  // 4. View Router Logic
  const renderActiveView = () => {
    // If a product is selected, display details screen regardless of tab (acting as sub-route)
    if (selectedProduct) {
      return (
        <ProductDetailView 
          product={selectedProduct}
          userLocation={userLocation}
          currentUser={currentUser}
          onBack={() => setSelectedProduct(null)}
          onWishlistToggle={handleWishlistToggle}
          isWishlisted={wishlistedIds.includes(selectedProduct.id)}
          addToast={addToast}
          onUpdateListings={handleUpdateListings}
        />
      );
    }

    switch (activeTab) {
      case 'home':
        return (
          <HomeView 
            listings={listings}
            userLocation={userLocation}
            currentUser={currentUser}
            categories={categories}
            onSelectProduct={setSelectedProduct}
            onWishlistToggle={handleWishlistToggle}
            wishlistedIds={wishlistedIds}
            onCategorySelect={handleCategorySelectFromHome}
            onNavigateToTab={setActiveTab}
          />
        );
      
      case 'search':
        return (
          <SearchView 
            listings={listings}
            userLocation={userLocation}
            currentUser={currentUser}
            categories={categories}
            initialCategory={searchCategoryFilter}
            onSelectProduct={setSelectedProduct}
            onWishlistToggle={handleWishlistToggle}
            wishlistedIds={wishlistedIds}
          />
        );

      case 'sell':
        if (currentUser && currentUser.sellerStatus === 'approved') {
          return (
            <SellerDashboardView 
              currentUser={currentUser}
              listings={listings}
              categories={categories}
              addToast={addToast}
              onUpdateListings={handleUpdateListings}
            />
          );
        } else {
          return (
            <SellerWizard 
              currentUser={currentUser}
              onOnboardingComplete={(updatedUser) => {
                setCurrentUser(updatedUser);
                handleUpdateListings();
              }}
              addToast={addToast}
            />
          );
        }

      case 'wishlist':
        const wishlistedItems = listings.filter(l => wishlistedIds.includes(l.id) && l.status === 'published');
        return (
          <div style={{ animation: 'fadeIn 0.25s' }}>
            <h2 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Heart size={20} fill="hsl(var(--accent-red))" color="hsl(var(--accent-red))" />
              <span>Barang Favorit Anda</span>
            </h2>
            
            {wishlistedItems.length === 0 ? (
              <div className="glass-card" style={{ padding: '60px 10px', textAlign: 'center', color: 'hsl(var(--text-muted))' }}>
                <p style={{ fontSize: '13px' }}>Belum ada barang terbit yang Anda simpan.</p>
                <button 
                  className="btn btn-primary" 
                  onClick={() => setActiveTab('search')}
                  style={{ width: 'auto', margin: '14px auto 0 auto', padding: '8px 16px', fontSize: '12px' }}
                >
                  Cari Barang Sekarang
                </button>
              </div>
            ) : (
              <div className="product-grid">
                {wishlistedItems.map(listing => (
                  <ListingCard 
                    key={listing.id}
                    listing={listing}
                    userLocation={userLocation}
                    currentUser={currentUser}
                    onSelect={setSelectedProduct}
                    onWishlistToggle={handleWishlistToggle}
                    isWishlisted={true}
                  />
                ))}
              </div>
            )}
          </div>
        );

      case 'profile':
        return (
          <ProfileView 
            currentUser={currentUser}
            listings={listings}
            wishlistedIds={wishlistedIds}
            onSelectProduct={setSelectedProduct}
            onWishlistToggle={handleWishlistToggle}
            onNavigateToTab={setActiveTab}
            onResetDB={handleResetDB}
          />
        );

      case 'admin':
        if (currentUser && currentUser.role === 'admin') {
          return (
            <AdminPanel 
              currentUser={currentUser}
              addToast={addToast}
              onUpdateListings={handleUpdateListings}
            />
          );
        }
        return <div style={{ padding: '20px', textAlign: 'center' }}>Akses Ditolak.</div>;

      default:
        return <div>Halaman tidak ditemukan.</div>;
    }
  };

  return (
    <div className="app-container">
      {/* App Header & Role Toggler */}
      <Header 
        currentUser={currentUser} 
        onUserChange={handleUserChange} 
        onResetDB={handleResetDB} 
      />

      {/* Floating System Notifications Overlay */}
      <div className="toast-container">
        {toasts.map(toast => (
          <div 
            key={toast.id} 
            className={`toast ${toast.type === 'error' ? 'toast-error' : toast.type === 'warning' ? 'toast-warning' : ''}`}
          >
            <Bell size={14} color={toast.type === 'error' ? '#ef4444' : toast.type === 'warning' ? '#f59e0b' : '#10b981'} />
            <span style={{ fontWeight: '500' }}>{toast.message}</span>
          </div>
        ))}
      </div>

      {/* App Content Body */}
      <main className="app-content">
        {/* GPS location simulation control widget */}
        <GPSSimulator 
          userLocation={userLocation} 
          onLocationUpdate={(loc) => {
            setUserLocation(loc);
            // Clear selected product view on GPS relocation to prevent layout mismatches
            setSelectedProduct(null);
          }}
        />

        {renderActiveView()}
      </main>

      {/* Footer Mobile Bottom Navbar */}
      <Navigation 
        activeTab={selectedProduct ? '' : activeTab} 
        onTabChange={(tab) => {
          setSelectedProduct(null); // Return to list view
          setSearchCategoryFilter('Semua'); // Clear temporary filters
          setActiveTab(tab);
        }}
        currentUser={currentUser}
      />
    </div>
  );
}
