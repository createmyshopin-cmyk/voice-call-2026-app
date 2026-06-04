// components/CoinsView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Plus, Edit2, Trash2, Eye, EyeOff, Check, X } from 'lucide-react';
import { MockDatabase, CoinPackage } from '../lib/mockDb';

export default function CoinsView() {
  const [packages, setPackages] = useState<CoinPackage[]>([]);
  const [editingPkg, setEditingPkg] = useState<CoinPackage | null>(null);
  const [isAdding, setIsAdding] = useState(false);

  // Form inputs
  const [name, setName] = useState('');
  const [coins, setCoins] = useState<number>(100);
  const [bonusCoins, setBonusCoins] = useState<number>(0);
  const [price, setPrice] = useState<number>(99);

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const triggerToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const loadData = () => {
    setPackages(MockDatabase.getCoinPackages());
  };

  useEffect(() => {
    loadData();
  }, []);

  // 1. Toggle Status (Enable/Disable)
  const toggleStatus = (pkg: CoinPackage) => {
    const updated = packages.map(p => {
      if (p.id === pkg.id) {
        triggerToast(`${p.name} status updated`, 'success');
        return { ...p, enabled: !p.enabled };
      }
      return p;
    });
    MockDatabase.saveCoinPackages(updated);
    setPackages(updated);
  };

  // 2. Delete Package
  const deletePkg = (pkgId: string, pkgName: string) => {
    if (!window.confirm(`Delete coin package "${pkgName}"?`)) return;
    const updated = packages.filter(p => p.id !== pkgId);
    MockDatabase.saveCoinPackages(updated);
    setPackages(updated);
    triggerToast(`Package deleted`, 'error');
  };

  // 3. Add Package Submit
  const handleAddSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (coins <= 0 || price <= 0) {
      triggerToast('Values must be positive', 'error');
      return;
    }

    const newPkg: CoinPackage = {
      id: `PKG${Date.now().toString().slice(-4)}`,
      name,
      coins,
      bonusCoins,
      price,
      enabled: true
    };

    const updated = [...packages, newPkg];
    MockDatabase.saveCoinPackages(updated);
    setPackages(updated);
    setIsAdding(false);
    resetForm();
    triggerToast('Package created successfully', 'success');
  };

  // 4. Edit Package Submit
  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPkg) return;

    const updated = packages.map(p => {
      if (p.id === editingPkg.id) {
        return {
          ...p,
          name,
          coins,
          bonusCoins,
          price
        };
      }
      return p;
    });
    MockDatabase.saveCoinPackages(updated);
    setPackages(updated);
    setEditingPkg(null);
    resetForm();
    triggerToast('Package updated successfully', 'success');
  };

  const startEdit = (pkg: CoinPackage) => {
    setEditingPkg(pkg);
    setIsAdding(false);
    setName(pkg.name);
    setCoins(pkg.coins);
    setBonusCoins(pkg.bonusCoins);
    setPrice(pkg.price);
  };

  const startAdd = () => {
    setIsAdding(true);
    setEditingPkg(null);
    resetForm();
  };

  const resetForm = () => {
    setName('');
    setCoins(100);
    setBonusCoins(0);
    setPrice(99);
  };

  return (
    <div className="space-y-6 relative">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg border shadow-lg transition-all duration-300 ${
          toast.type === 'success' ? 'bg-emerald-950/90 border-emerald-500/50 text-emerald-300' :
          'bg-red-950/90 border-red-500/50 text-red-300'
        }`}>
          <span>{toast.message}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Coin Packages</h1>
          <p className="text-sm text-zinc-400">Configure purchasing packages, pricing plans, and credit packages.</p>
        </div>
        <button
          onClick={startAdd}
          className="flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-xs font-semibold shadow transition-colors self-start"
        >
          <Plus size={14} /> Create Package
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Packages Grid list */}
        <div className="lg:col-span-2 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {packages.map((pkg) => (
              <div 
                key={pkg.id} 
                className={`glass-card rounded-xl p-5 border flex flex-col justify-between ${
                  pkg.enabled ? 'border-zinc-900' : 'border-zinc-950 opacity-60'
                }`}
              >
                <div>
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="text-sm font-semibold text-white leading-none">{pkg.name}</h3>
                      <span className="text-[10px] text-zinc-500 font-mono block mt-1">{pkg.id}</span>
                    </div>
                    <span className={`inline-flex px-1.5 py-0.5 rounded text-[8px] font-extrabold capitalize ${
                      pkg.enabled ? 'bg-indigo-500/10 text-indigo-400' : 'bg-zinc-800 text-zinc-500'
                    }`}>
                      {pkg.enabled ? 'Enabled' : 'Disabled'}
                    </span>
                  </div>

                  <div className="mt-4 flex items-baseline gap-2">
                    <span className="text-2xl font-black text-amber-400 tracking-tight">{pkg.coins}</span>
                    <span className="text-xs text-zinc-400">Coins</span>
                    {pkg.bonusCoins > 0 && (
                      <span className="text-[10px] font-bold text-emerald-400 bg-emerald-500/10 px-1.5 py-0.5 rounded">
                        +{pkg.bonusCoins} Bonus
                      </span>
                    )}
                  </div>

                  <div className="mt-2 text-xs text-zinc-300 font-medium">
                    Price: <span className="text-white font-bold">₹{pkg.price}</span>
                  </div>
                </div>

                <div className="mt-5 flex gap-2 border-t border-zinc-900 pt-3">
                  <button
                    onClick={() => startEdit(pkg)}
                    className="flex-1 py-1.5 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-300 rounded text-xs font-semibold transition-colors flex items-center justify-center gap-1"
                  >
                    <Edit2 size={12} /> Edit Details
                  </button>
                  <button
                    onClick={() => toggleStatus(pkg)}
                    className="p-1.5 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-400 rounded transition-colors"
                    title={pkg.enabled ? 'Disable Package' : 'Enable Package'}
                  >
                    {pkg.enabled ? <EyeOff size={14} /> : <Eye size={14} />}
                  </button>
                  <button
                    onClick={() => deletePkg(pkg.id, pkg.name)}
                    className="p-1.5 bg-zinc-900 border border-zinc-800 hover:bg-red-950/20 hover:text-red-400 text-zinc-500 rounded transition-colors"
                    title="Delete Package"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Editor sidebar panel */}
        {(isAdding || editingPkg) ? (
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 h-fit space-y-4">
            <div>
              <h2 className="text-base font-semibold text-white">
                {isAdding ? 'Create Package' : `Edit: ${editingPkg?.name}`}
              </h2>
              <p className="text-xs text-zinc-400">Configure parameters for app-store purchase listing.</p>
            </div>

            <form onSubmit={isAdding ? handleAddSubmit : handleEditSubmit} className="space-y-4 text-xs">
              <div>
                <label className="block text-zinc-500 mb-1">Package Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Starter Pack"
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-zinc-500 mb-1">Base Coins</label>
                  <input
                    type="number"
                    min="10"
                    value={coins}
                    onChange={(e) => setCoins(parseInt(e.target.value) || 0)}
                    className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                    required
                  />
                </div>
                <div>
                  <label className="block text-zinc-500 mb-1">Bonus Coins</label>
                  <input
                    type="number"
                    min="0"
                    value={bonusCoins}
                    onChange={(e) => setBonusCoins(parseInt(e.target.value) || 0)}
                    className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Price (₹ INR)</label>
                <input
                  type="number"
                  min="1"
                  value={price}
                  onChange={(e) => setPrice(parseInt(e.target.value) || 0)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>

              <div className="flex gap-2 pt-2 border-t border-zinc-900">
                <button
                  type="submit"
                  className="flex-1 py-2 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold rounded-lg transition-colors"
                >
                  Save Package
                </button>
                <button
                  type="button"
                  onClick={() => { setIsAdding(false); setEditingPkg(null); }}
                  className="px-3 bg-zinc-900 hover:bg-zinc-800 text-zinc-400 font-semibold border border-zinc-800 rounded-lg transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        ) : (
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 h-fit text-center text-zinc-500 text-xs">
            Select a package to edit details, or create a new bundle structure.
          </div>
        )}

      </div>
    </div>
  );
}
