"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function LandingPage() {
  const [claimUsername, setClaimUsername] = useState("");
  const router = useRouter();

  const handleClaim = (e: React.FormEvent) => {
    e.preventDefault();
    if (!claimUsername.trim()) return;
    const sanitized = claimUsername.toLowerCase().replace(/[^a-z0-9_-]/g, "");
    router.push(`/register?username=${sanitized}`);
  };

  return (
    <div className="relative min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between overflow-x-hidden selection:bg-purple-500/30 selection:text-white">
      {/* Dynamic Background Neon Glow */}
      <div className="absolute top-[-10%] left-[20%] w-[400px] sm:w-[600px] h-[400px] sm:h-[600px] bg-purple-600/10 blur-[120px] sm:blur-[160px] rounded-full pointer-events-none" />
      <div className="absolute bottom-[20%] right-[-10%] w-[300px] sm:w-[500px] h-[300px] sm:h-[500px] bg-blue-600/10 blur-[100px] sm:blur-[140px] rounded-full pointer-events-none" />

      {/* Navbar Header */}
      <header className="w-full max-w-7xl mx-auto px-6 py-6 flex justify-between items-center z-20 relative">
        <Link href="/" className="flex items-center gap-2">
          <span className="text-2xl font-black bg-gradient-to-r from-purple-400 via-pink-500 to-indigo-400 bg-clip-text text-transparent tracking-tight hover:opacity-90 transition-opacity">
            UltraLink.
          </span>
        </Link>
        <div className="flex items-center gap-4">
          <Link
            href="/login"
            className="text-sm font-semibold text-slate-300 hover:text-white transition-colors px-3 py-1.5"
          >
            Masuk
          </Link>
          <Link
            href="/register"
            className="text-sm font-semibold text-slate-950 bg-white hover:bg-slate-200 transition-all px-4 py-2 rounded-xl shadow-md font-bold"
          >
            Daftar Gratis
          </Link>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1 flex flex-col items-center justify-center px-6 py-12 relative z-10">
        <div className="max-w-4xl text-center space-y-8">
          <span className="inline-flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-semibold bg-purple-500/10 text-purple-400 rounded-full border border-purple-500/20">
            ⚡ Hubungkan Semua Audiens Anda Sekarang
          </span>

          <h1 className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight bg-clip-text text-transparent bg-gradient-to-b from-white via-slate-100 to-slate-400 leading-tight md:leading-[1.1]">
            Satukan Seluruh Link Anda <br />
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-purple-400 via-pink-400 to-indigo-400">
              Dalam Satu Baris URL
            </span>
          </h1>

          <p className="text-base sm:text-xl text-slate-400 max-w-2xl mx-auto leading-relaxed">
            Platform bio-link modern untuk para creator, developer, dan digital entrepreneur. 
            Kelola sosial media, portofolio, dan bisnis Anda dalam satu halaman kustom premium yang indah.
          </p>

          {/* Interactive Claim Username Form */}
          <form onSubmit={handleClaim} className="max-w-md mx-auto w-full pt-4">
            <div className="flex flex-col sm:flex-row gap-3 p-1.5 bg-slate-900/50 border border-slate-800 rounded-2xl backdrop-blur-md">
              <div className="flex items-center flex-1 px-3 py-2 bg-slate-950/60 rounded-xl border border-slate-800/40">
                <span className="text-slate-500 text-sm font-medium select-none">ultralink.com/</span>
                <input
                  type="text"
                  required
                  value={claimUsername}
                  onChange={(e) => setClaimUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_-]/g, ""))}
                  placeholder="username-anda"
                  className="bg-transparent border-none outline-none text-white text-sm w-full font-medium ml-0.5 focus:ring-0"
                />
              </div>
              <button
                type="submit"
                className="w-full sm:w-auto px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white font-bold text-sm rounded-xl transition-all shadow-lg shadow-purple-600/20 active:scale-95"
              >
                Klaim Sekarang
              </button>
            </div>
            <p className="text-[11px] text-slate-500 text-left px-2 mt-2">
              *Masukkan nama pengguna unik pilihan Anda untuk membuat URL bio instan.
            </p>
          </form>


        </div>

        {/* Features Grid Section */}
        <section className="w-full max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-6 pt-24 pb-12">
          {/* Card 1 */}
          <div className="p-6 rounded-2xl border border-slate-900 bg-slate-900/10 backdrop-blur-sm space-y-3 hover:border-slate-800 transition-all duration-300">
            <div className="text-2xl p-2 bg-purple-500/10 text-purple-400 rounded-xl w-fit border border-purple-500/20">🎨</div>
            <h3 className="text-lg font-bold text-white">Desain Premium & Kustom</h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Atur avatar profil, skema warna aksen, hingga pilihan tema gelap premium atau terang minimalis sesuai persona digital Anda.
            </p>
          </div>

          {/* Card 2 */}
          <div className="p-6 rounded-2xl border border-slate-900 bg-slate-900/10 backdrop-blur-sm space-y-3 hover:border-slate-800 transition-all duration-300">
            <div className="text-2xl p-2 bg-pink-500/10 text-pink-400 rounded-xl w-fit border border-pink-500/20">📊</div>
            <h3 className="text-lg font-bold text-white">Analitik Jumlah Klik</h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Pantau performa tautan Anda dengan sistem kalkulasi analitik klik total secara akurat dan real-time di dashboard utama.
            </p>
          </div>

          {/* Card 3 */}
          <div className="p-6 rounded-2xl border border-slate-900 bg-slate-900/10 backdrop-blur-sm space-y-3 hover:border-slate-800 transition-all duration-300">
            <div className="text-2xl p-2 bg-indigo-500/10 text-indigo-400 rounded-xl w-fit border border-indigo-500/20">⚡</div>
            <h3 className="text-lg font-bold text-white">Tautan Tanpa Batas</h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Tambahkan seluruh tautan aktif Anda ke media sosial, artikel, e-book, produk fisik, atau toko online tanpa limitasi jumlah.
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="w-full text-center py-8 border-t border-slate-900 z-10 relative">
        <p className="text-xs text-slate-600 tracking-wide">
          &copy; 2026 UltraLink SaaS Platform. Created by Ardev Labs.
        </p>
      </footer>
    </div>
  );
}