// Geolocation & Reverse Geocoding Utility using OpenStreetMap Nominatim
import { MockDB } from '../db/MockDB';

// Haversine Formula to calculate distance between two coordinates in Kilometers
export function calculateDistance(lat1, lon1, lat2, lon2) {
  if (lat1 === null || lon1 === null || lat2 === null || lon2 === null) return null;
  if (lat1 === undefined || lon1 === undefined || lat2 === undefined || lon2 === undefined) return null;

  const R = 6371; // Radius of the Earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in km
  return distance;
}

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

// Wrapper for HTML5 Geolocation API
export function getCurrentCoordinates() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Browser Anda tidak mendukung deteksi lokasi (GPS).'));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
      },
      (error) => {
        let msg = 'Gagal mendeteksi lokasi GPS.';
        if (error.code === 1) msg = 'Izin akses lokasi ditolak. Aktifkan GPS di browser Anda.';
        else if (error.code === 2) msg = 'Sinyal GPS tidak ditemukan.';
        else if (error.code === 3) msg = 'Waktu tunggu deteksi lokasi habis.';
        reject(new Error(msg));
      },
      { enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }
    );
  });
}

// Reverse Geocoding using Nominatim API (OpenStreetMap) with local caching
export async function getAreaName(lat, lng) {
  if (!lat || !lng) return '';

  // 1. Check local cache first
  const cachedName = MockDB.getCachedGeocode(lat, lng);
  if (cachedName) {
    console.log(`[GeoCache] Hit: ${lat},${lng} -> ${cachedName}`);
    return cachedName;
  }

  // 2. Fetch from Nominatim API if not cached
  console.log(`[GeoAPI] Fetching: ${lat},${lng}`);
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`,
      {
        headers: {
          // Identify app as per Nominatim usage guidelines
          'Accept-Language': 'id-ID,id;q=0.9',
          'User-Agent': 'LocalStoreHyperlocalApp/1.0'
        }
      }
    );

    if (!response.ok) {
      throw new Error('OSM Server error');
    }

    const data = await response.json();
    if (!data || !data.address) {
      throw new Error('Alamat tidak ditemukan');
    }

    const address = data.address;
    
    // Parse Indonesian neighborhood components
    // Nominatim returns suburb/village/neighbourhood/municipality depending on the area type
    let area = 
      address.suburb || 
      address.village || 
      address.neighbourhood || 
      address.quarter || 
      address.hamlet || 
      address.city_district;

    // Fallbacks
    if (!area) {
      area = address.municipality || address.town || address.city || 'Area Teridentifikasi';
    }

    // Clean up typical Indonesian prefixes for neatness
    area = area
      .replace(/^Kelurahan\s+/i, '')
      .replace(/^Kecamatan\s+/i, '')
      .replace(/^Desa\s+/i, '');

    // 3. Save to local cache
    MockDB.saveCachedGeocode(lat, lng, area);
    return area;
  } catch (error) {
    console.error('Reverse Geocoding error:', error);
    // If rate limited or offline, return a fallback text or coordinates
    return `Wilayah (${parseFloat(lat).toFixed(4)}, ${parseFloat(lng).toFixed(4)})`;
  }
}
