// GPS Geolocation Simulation Widget for Developer / Testing Mode
import React, { useState, useEffect } from 'react';
import { MapPin, Navigation, Info } from 'lucide-react';
import { getAreaName } from '../utils/geo';

const PRESETS = [
  { name: 'Petukangan Utara', lat: -6.2384, lng: 106.7456 },
  { name: 'Petukangan Selatan', lat: -6.2412, lng: 106.7421 },
  { name: 'Bintaro (Sektor 1)', lat: -6.2655, lng: 106.7389 },
  { name: 'Cipulir', lat: -6.2361, lng: 106.7725 },
  { name: 'Kebayoran Lama', lat: -6.2443, lng: 106.7825 }
];

export default function GPSSimulator({ userLocation, onLocationUpdate }) {
  const [isOpen, setIsOpen] = useState(false);
  const [customLat, setCustomLat] = useState('');
  const [customLng, setCustomLng] = useState('');
  const [loading, setLoading] = useState(false);

  // Set default simulator position on load if not set
  useEffect(() => {
    if (!userLocation.lat) {
      // Seed with Budi's shop location as a starting point (Petukangan Utara)
      const p = PRESETS[0];
      onLocationUpdate({
        lat: p.lat,
        lng: p.lng,
        name: p.name,
        isSimulated: true
      });
    }
  }, []);

  const handleSelectPreset = async (preset) => {
    setLoading(true);
    // Presets have names precalculated to avoid OSM Nominatim requests, complying with rules
    onLocationUpdate({
      lat: preset.lat,
      lng: preset.lng,
      name: preset.name,
      isSimulated: true
    });
    setLoading(false);
  };

  const handleCustomApply = async (e) => {
    e.preventDefault();
    const lat = parseFloat(customLat);
    const lng = parseFloat(customLng);
    if (isNaN(lat) || isNaN(lng)) return;

    setLoading(true);
    const areaName = await getAreaName(lat, lng);
    onLocationUpdate({
      lat,
      lng,
      name: areaName || 'Lokasi Kustom',
      isSimulated: true
    });
    setLoading(false);
  };

  return (
    <div className="gps-sim-widget" style={{ marginBottom: '16px' }}>
      <div 
        style={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          cursor: 'pointer' 
        }}
        onClick={() => setIsOpen(!isOpen)}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'hsl(var(--primary))' }}>
          <Navigation size={16} style={{ transform: 'rotate(45deg)' }} />
          <strong style={{ fontSize: '13px' }}>GPS Simulator (Dev Mode)</strong>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <span className="badge badge-verified" style={{ fontSize: '10px', padding: '2px 6px' }}>
            Simulasi Aktif
          </span>
          <span style={{ fontSize: '12px' }}>{isOpen ? '▲' : '▼'}</span>
        </div>
      </div>

      <div style={{ marginTop: '8px', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'hsl(var(--text-muted))' }}>
        <MapPin size={12} color="#10b981" />
        <span>Posisi saat ini: <strong>{userLocation.name || 'Mendeteksi...'}</strong></span>
        {userLocation.lat && (
          <span style={{ fontSize: '10px' }}>
            ({userLocation.lat.toFixed(4)}, {userLocation.lng.toFixed(4)})
          </span>
        )}
      </div>

      {isOpen && (
        <div style={{ marginTop: '14px', borderTop: '1px solid rgba(255,255,255,0.08)', paddingTop: '12px' }}>
          <p style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Info size={10} /> Pilih kelurahan di bawah untuk memindahkan posisi GPS Anda secara instan:
          </p>
          
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '12px' }}>
            {PRESETS.map((p) => {
              const isActive = userLocation.name === p.name;
              return (
                <button
                  key={p.name}
                  onClick={() => handleSelectPreset(p)}
                  disabled={loading}
                  style={{
                    backgroundColor: isActive ? 'hsl(var(--primary))' : 'rgba(255,255,255,0.05)',
                    color: isActive ? '#ffffff' : 'hsl(var(--text-primary))',
                    border: '1px solid rgba(255,255,255,0.08)',
                    borderRadius: '8px',
                    padding: '6px 10px',
                    fontSize: '11px',
                    fontWeight: isActive ? '600' : 'normal',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease'
                  }}
                >
                  {p.name}
                </button>
              );
            })}
          </div>

          <form onSubmit={handleCustomApply} style={{ display: 'flex', gap: '6px' }}>
            <input 
              type="text" 
              placeholder="Latitude" 
              value={customLat} 
              onChange={e => setCustomLat(e.target.value)}
              style={{
                flex: 1,
                padding: '6px 8px',
                fontSize: '11px',
                backgroundColor: 'rgba(255,255,255,0.05)',
                border: '1px solid rgba(255,255,255,0.1)',
                borderRadius: '6px',
                color: '#fff',
                outline: 'none'
              }}
            />
            <input 
              type="text" 
              placeholder="Longitude" 
              value={customLng} 
              onChange={e => setCustomLng(e.target.value)}
              style={{
                flex: 1,
                padding: '6px 8px',
                fontSize: '11px',
                backgroundColor: 'rgba(255,255,255,0.05)',
                border: '1px solid rgba(255,255,255,0.1)',
                borderRadius: '6px',
                color: '#fff',
                outline: 'none'
              }}
            />
            <button 
              type="submit" 
              style={{
                padding: '6px 12px',
                fontSize: '11px',
                fontWeight: '600',
                backgroundColor: 'hsl(var(--primary))',
                color: '#fff',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer'
              }}
            >
              Terapkan
            </button>
          </form>
        </div>
      )}
    </div>
  );
}
