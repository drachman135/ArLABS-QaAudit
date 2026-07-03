// Navigation & Header Components with User Switcher for MVP Testing
import React from 'react';
import { Home, Search, PlusCircle, Heart, User, Shield, RotateCcw } from 'lucide-react';
import { MockDB } from '../db/MockDB';

export function Header({ currentUser, onUserChange, onResetDB }) {
  const users = MockDB.getUsers();

  return (
    <header className="app-header">
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }} onClick={onResetDB}>
        <span style={{ fontSize: '22px' }}>🏪</span>
        <h1 style={{ fontSize: '18px', fontWeight: '800', background: 'linear-gradient(45deg, #10b981, #3b82f6)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', cursor: 'pointer' }}>
          LocalStore
        </h1>
      </div>
      
      {/* Dev Switcher */}
      <div className="dev-switcher" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <button 
          onClick={onResetDB} 
          title="Reset Database" 
          style={{
            background: 'rgba(255,255,255,0.05)',
            border: 'none',
            color: 'hsl(var(--text-muted))',
            cursor: 'pointer',
            padding: '4px',
            borderRadius: '6px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          <RotateCcw size={14} />
        </button>
        <select 
          className="dev-select"
          value={currentUser ? currentUser.id : ''} 
          onChange={(e) => {
            const selected = users.find(u => u.id === e.target.value);
            onUserChange(selected);
          }}
        >
          {users.map(u => (
            <option key={u.id} value={u.id}>
              {u.role === 'admin' ? '🛡️ Admin' : u.sellerStatus === 'approved' ? `🏪 ${u.name}` : `👤 ${u.name}`}
            </option>
          ))}
        </select>
      </div>
    </header>
  );
}

export function Navigation({ activeTab, onTabChange, currentUser }) {
  // Determine text / icons for Sell tab based on user state
  const isSeller = currentUser && currentUser.sellerStatus === 'approved';
  const isAdmin = currentUser && currentUser.role === 'admin';

  return (
    <nav className="app-nav">
      <button 
        className={`nav-item ${activeTab === 'home' ? 'active' : ''}`}
        onClick={() => onTabChange('home')}
      >
        <Home size={20} />
        <span>Beranda</span>
      </button>

      <button 
        className={`nav-item ${activeTab === 'search' ? 'active' : ''}`}
        onClick={() => onTabChange('search')}
      >
        <Search size={20} />
        <span>Cari</span>
      </button>

      <button 
        className={`nav-item ${activeTab === 'sell' ? 'active' : ''}`}
        onClick={() => onTabChange('sell')}
      >
        <PlusCircle size={20} />
        <span>{isSeller ? 'Toko Saya' : 'Jual'}</span>
      </button>

      <button 
        className={`nav-item ${activeTab === 'wishlist' ? 'active' : ''}`}
        onClick={() => onTabChange('wishlist')}
      >
        <Heart size={20} />
        <span>Favorit</span>
      </button>

      <button 
        className={`nav-item ${activeTab === 'profile' ? 'active' : ''}`}
        onClick={() => onTabChange('profile')}
      >
        <User size={20} />
        <span>Profil</span>
      </button>

      {isAdmin && (
        <button 
          className={`nav-item ${activeTab === 'admin' ? 'active' : ''}`}
          onClick={() => onTabChange('admin')}
          style={{ color: activeTab === 'admin' ? 'hsl(var(--accent-amber))' : 'hsl(var(--text-muted))' }}
        >
          <Shield size={20} />
          <span>Moderasi</span>
        </button>
      )}
    </nav>
  );
}
