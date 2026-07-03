// SellerWizard Component - Multistep Seller Onboarding Flow
import React, { useState } from 'react';
import { Phone, MapPin, CheckCircle, ShieldAlert, Store, ArrowRight, Loader } from 'lucide-react';
import { getCurrentCoordinates, getAreaName } from '../utils/geo';
import { MockDB } from '../db/MockDB';

export default function SellerWizard({ currentUser, onOnboardingComplete, addToast }) {
  const [step, setStep] = useState(1);
  const [phone, setPhone] = useState('');
  const [sentOtp, setSentOtp] = useState('');
  const [inputOtp, setInputOtp] = useState('');
  const [isVerifyingOtp, setIsVerifyingOtp] = useState(false);
  const [phoneVerified, setPhoneVerified] = useState(false);

  // GPS States
  const [gpsLoading, setGpsLoading] = useState(false);
  const [coordinates, setCoordinates] = useState({ lat: null, lng: null });
  const [detectedArea, setDetectedArea] = useState('');

  // Shop Profile States
  const [shopName, setShopName] = useState('');
  const [shopDescription, setShopDescription] = useState('');

  // 1. Send OTP Simulator
  const handleSendOtp = () => {
    if (!phone || phone.length < 10) {
      addToast('Nomor HP tidak valid. Masukkan minimal 10 digit.', 'error');
      return;
    }
    
    // Generate simulated 6 digit OTP
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    setSentOtp(code);
    setIsVerifyingOtp(true);
    
    // Simulate SMS delivery via notification Toast
    addToast(`[SMS Gateway] Kode OTP Anda adalah: ${code}`, 'warning');
    console.log(`[OTP Simulated SMS]: ${code}`);
  };

  // 2. Verify OTP
  const handleVerifyOtp = () => {
    if (inputOtp === sentOtp && sentOtp !== '') {
      setPhoneVerified(true);
      setIsVerifyingOtp(false);
      setStep(2);
      addToast('Nomor HP berhasil diverifikasi!', 'success');
    } else {
      addToast('Kode OTP salah. Silakan coba lagi.', 'error');
    }
  };

  // 3. Capture GPS
  const handleCaptureGps = async () => {
    setGpsLoading(true);
    try {
      // Get browser coordinates
      const coords = await getCurrentCoordinates();
      setCoordinates(coords);

      // Perform Nominatim reverse geocode
      const area = await getAreaName(coords.lat, coords.lng);
      setDetectedArea(area);
      
      addToast(`Lokasi terdeteksi di Kelurahan ${area}`, 'success');
    } catch (error) {
      console.error(error);
      addToast(error.message || 'Gagal mendeteksi lokasi GPS.', 'error');
    } finally {
      setGpsLoading(false);
    }
  };

  // 4. Submit Registration
  const handleSubmit = (e) => {
    e.preventDefault();
    if (!shopName) {
      addToast('Nama Toko wajib diisi.', 'error');
      return;
    }

    if (!coordinates.lat || !coordinates.lng || !detectedArea) {
      addToast('Data lokasi wajib diverifikasi menggunakan GPS.', 'error');
      return;
    }

    // Update user profile in local storage to pending status
    const updated = MockDB.updateUserProfile(currentUser.id, {
      phone,
      shopName,
      shopDescription,
      lat: coordinates.lat,
      lng: coordinates.lng,
      kelurahan: detectedArea,
      sellerStatus: 'pending' // Transition to pending admin moderation
    });

    onOnboardingComplete(updated);
    addToast('Pendaftaran seller berhasil dikirim untuk review admin!', 'success');
  };

  // Render pending page if user's status is already pending review
  if (currentUser && currentUser.sellerStatus === 'pending') {
    return (
      <div className="glass-card" style={{ padding: '30px 20px', textAlign: 'center', margin: '20px 0' }}>
        <div style={{ color: '#f59e0b', marginBottom: '20px' }}>
          <Store size={64} style={{ animation: 'pulse 2s infinite' }} />
        </div>
        <h2 style={{ fontSize: '20px', fontWeight: '800', marginBottom: '10px' }}>Pendaftaran Sedang Ditinjau</h2>
        <p style={{ fontSize: '13px', color: 'hsl(var(--text-muted))', lineHeight: '1.6', marginBottom: '20px' }}>
          Halo <strong>{currentUser.name}</strong>, formulir pengajuan toko <strong>"{currentUser.shopName}"</strong> di wilayah <strong>{currentUser.kelurahan}</strong> sedang dalam proses kurasi oleh tim Admin.
        </p>
        <div style={{ backgroundColor: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.2)', borderRadius: '12px', padding: '15px', fontSize: '12px', color: '#f59e0b', textAlign: 'left', marginBottom: '20px' }}>
          <strong>📝 Detail Pengajuan:</strong>
          <ul style={{ paddingLeft: '20px', marginTop: '6px', listStyleType: 'circle' }}>
            <li>Nomor HP: {currentUser.phone}</li>
            <li>Wilayah: {currentUser.kelurahan}</li>
            <li>Koordinat GPS: {currentUser.lat?.toFixed(4)}, {currentUser.lng?.toFixed(4)}</li>
          </ul>
        </div>
        <div style={{ fontSize: '11px', color: 'hsl(var(--text-muted))' }}>
          💡 <em>Tip Pengujian: Gunakan menu dropdown di bagian atas layar untuk beralih ke <strong>🛡️ Admin</strong> dan menyetujui pengajuan toko ini.</em>
        </div>
      </div>
    );
  }

  return (
    <div className="glass-card" style={{ padding: '24px', margin: '20px 0' }}>
      {/* Wizard Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '24px' }}>
        <Store size={24} color="#10b981" />
        <h2 style={{ fontSize: '18px', fontWeight: '800' }}>Wizard Onboarding Seller</h2>
      </div>

      {/* Step Indicators */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px' }}>
        {[1, 2, 3].map(s => (
          <div 
            key={s} 
            style={{ 
              flex: 1, 
              height: '4px', 
              borderRadius: '2px', 
              backgroundColor: s <= step ? 'hsl(var(--primary))' : 'rgba(255,255,255,0.1)',
              transition: 'background-color 0.3s ease'
            }} 
          />
        ))}
      </div>

      {/* Step 1: HP Verification */}
      {step === 1 && (
        <div>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '8px' }}>Langkah 1: Verifikasi WhatsApp Penjual</h3>
          <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))', marginBottom: '16px' }}>
            LocalStore menggunakan WhatsApp untuk proses COD. Masukkan nomor WhatsApp aktif Anda untuk menerima kode OTP simulasi.
          </p>

          <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
            <div className="input-group" style={{ flex: 1 }}>
              <Phone size={16} />
              <input 
                className="form-input" 
                type="tel" 
                placeholder="Contoh: 08123456789"
                value={phone}
                onChange={e => setPhone(e.target.value)}
                disabled={isVerifyingOtp}
              />
            </div>
            {!isVerifyingOtp && (
              <button 
                className="btn btn-primary" 
                onClick={handleSendOtp}
                style={{ width: 'auto', padding: '12px 16px' }}
              >
                Kirim OTP
              </button>
            )}
          </div>

          {isVerifyingOtp && (
            <div style={{ animation: 'fadeIn 0.3s' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '16px' }}>
                <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>
                  Masukkan Kode OTP yang dikirim ke layar Anda:
                </label>
                <input 
                  className="form-input" 
                  style={{ letterSpacing: '4px', textAlign: 'center', paddingLeft: '16px', fontSize: '16px', fontWeight: '700' }}
                  type="text" 
                  maxLength={6}
                  placeholder="------"
                  value={inputOtp}
                  onChange={e => setInputOtp(e.target.value)}
                />
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button 
                  className="btn btn-secondary" 
                  onClick={() => setIsVerifyingOtp(false)}
                  style={{ flex: 1 }}
                >
                  Batal
                </button>
                <button 
                  className="btn btn-primary" 
                  onClick={handleVerifyOtp}
                  style={{ flex: 1 }}
                >
                  Verifikasi OTP
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Step 2: GPS Verification */}
      {step === 2 && (
        <div style={{ animation: 'fadeIn 0.3s' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '8px' }}>Langkah 2: Verifikasi GPS & Area Lokasi</h3>
          <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))', marginBottom: '16px' }}>
            Untuk menjamin keaslian lokasi, Anda wajib membagikan koordinat GPS perangkat Anda. Sistem akan memetakan wilayah secara otomatis.
          </p>

          {!coordinates.lat ? (
            <button 
              className="btn btn-primary" 
              onClick={handleCaptureGps}
              disabled={gpsLoading}
            >
              {gpsLoading ? (
                <>
                  <Loader size={16} className="shimmer" style={{ animation: 'spin 1s infinite linear' }} />
                  Mendeteksi Koordinat GPS...
                </>
              ) : (
                <>
                  <MapPin size={16} />
                  Ambil Lokasi GPS Saya
                </>
              )}
            </button>
          ) : (
            <div style={{ padding: '16px', backgroundColor: 'rgba(16,185,129,0.08)', border: '1px dashed #10b981', borderRadius: '12px', marginBottom: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#10b981', fontWeight: '700', marginBottom: '8px', fontSize: '13px' }}>
                <CheckCircle size={16} />
                <span>GPS Berhasil Diverifikasi!</span>
              </div>
              <div style={{ fontSize: '12px', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <div>📍 <strong>Wilayah Kelurahan:</strong> {detectedArea}</div>
                <div style={{ color: 'hsl(var(--text-muted))', fontSize: '10px' }}>
                  Koordinat: {coordinates.lat.toFixed(6)}, {coordinates.lng.toFixed(6)}
                </div>
              </div>
            </div>
          )}

          {coordinates.lat && (
            <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
              <button 
                className="btn btn-secondary" 
                onClick={() => setCoordinates({ lat: null, lng: null })}
                disabled={gpsLoading}
                style={{ flex: 1 }}
              >
                Ulangi GPS
              </button>
              <button 
                className="btn btn-primary" 
                onClick={() => setStep(3)}
                style={{ flex: 1 }}
              >
                Lanjut
                <ArrowRight size={16} />
              </button>
            </div>
          )}
        </div>
      )}

      {/* Step 3: Shop Profile Details */}
      {step === 3 && (
        <form onSubmit={handleSubmit} style={{ animation: 'fadeIn 0.3s' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '8px' }}>Langkah 3: Atur Profil Toko</h3>
          <p style={{ fontSize: '12px', color: 'hsl(var(--text-muted))', marginBottom: '16px' }}>
            Lengkapi nama toko dan deskripsi singkat barang-barang yang akan Anda jual di wilayah <strong>{detectedArea}</strong>.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '20px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Nama Toko / Nama Profil</label>
              <input 
                className="form-input"
                style={{ paddingLeft: '16px' }}
                placeholder="Contoh: Thrift Shop Budi" 
                value={shopName}
                onChange={e => setShopName(e.target.value)}
                required
              />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <label style={{ fontSize: '11px', fontWeight: '600', color: 'hsl(var(--text-muted))' }}>Deskripsi Singkat (Opsional)</label>
              <textarea 
                className="form-input"
                style={{ padding: '12px 16px', height: '80px', resize: 'none' }}
                placeholder="Jual pakaian bekas berkualitas, kipas, perlengkapan rumah murah..."
                value={shopDescription}
                onChange={e => setShopDescription(e.target.value)}
              />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '8px' }}>
            <button 
              type="button"
              className="btn btn-secondary" 
              onClick={() => setStep(2)}
              style={{ flex: 1 }}
            >
              Kembali
            </button>
            <button 
              type="submit" 
              className="btn btn-primary"
              style={{ flex: 1 }}
            >
              Kirim Pengajuan
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
