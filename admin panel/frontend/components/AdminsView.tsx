// components/AdminsView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Key, Shield, User, X } from 'lucide-react';
import { MockDatabase, Admin } from '../lib/mockDb';

export default function AdminsView() {
  const [admins, setAdmins] = useState<Admin[]>([]);
  const [editingAdmin, setEditingAdmin] = useState<Admin | null>(null);
  const [isAdding, setIsAdding] = useState(false);

  // Form Inputs
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<'super_admin' | 'finance_admin' | 'support_admin' | 'moderator'>('moderator');
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([]);

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const triggerToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ message: msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const loadData = () => {
    setAdmins(MockDatabase.getAdmins());
  };

  useEffect(() => {
    loadData();
  }, []);

  const availablePermissions = [
    { id: 'users', label: 'Manage Users & Wallets' },
    { id: 'wallet', label: 'Audit Transactions logs' },
    { id: 'payments', label: 'Verify Payments & Refunds' },
    { id: 'calls', label: 'Monitor Live active calls' },
    { id: 'notifications', label: 'Compose push messages' },
    { id: 'reports', label: 'Moderation Reports & bans' },
    { id: 'settings', label: 'Update System configurations' }
  ];

  // 1. Delete Admin Action
  const deleteAdmin = (adminId: string, adminName: string) => {
    if (adminId === 'ADM001') {
      triggerToast('Cannot delete default Super Admin', 'error');
      return;
    }
    if (!window.confirm(`Remove admin privileges for "${adminName}"?`)) return;

    const updated = admins.filter(a => a.id !== adminId);
    MockDatabase.saveAdmins(updated);
    setAdmins(updated);
    triggerToast('Administrator removed', 'error');
  };

  // 2. Permission Toggle helper
  const handlePermissionToggle = (permId: string) => {
    if (selectedPermissions.includes(permId)) {
      setSelectedPermissions(selectedPermissions.filter(p => p !== permId));
    } else {
      setSelectedPermissions([...selectedPermissions, permId]);
    }
  };

  // 3. Save Admin Action
  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !email) {
      triggerToast('Name and email are required', 'error');
      return;
    }

    if (isAdding) {
      const newAdmin: Admin = {
        id: `ADM${Date.now().toString().slice(-3)}`,
        name,
        email,
        role,
        permissions: selectedPermissions,
        joinedAt: new Date().toISOString().split('T')[0]
      };
      const updated = [...admins, newAdmin];
      MockDatabase.saveAdmins(updated);
      setAdmins(updated);
      setIsAdding(false);
      triggerToast('New Admin account initialized', 'success');
    } else if (editingAdmin) {
      const updated = admins.map(a => {
        if (a.id === editingAdmin.id) {
          return {
            ...a,
            name,
            email,
            role,
            permissions: selectedPermissions
          };
        }
        return a;
      });
      MockDatabase.saveAdmins(updated);
      setAdmins(updated);
      setEditingAdmin(null);
      triggerToast('Admin permissions updated', 'success');
    }
    resetForm();
  };

  const startEdit = (admin: Admin) => {
    setEditingAdmin(admin);
    setIsAdding(false);
    setName(admin.name);
    setEmail(admin.email);
    setRole(admin.role);
    setSelectedPermissions(admin.permissions);
  };

  const startAdd = () => {
    setIsAdding(true);
    setEditingAdmin(null);
    resetForm();
  };

  const resetForm = () => {
    setName('');
    setEmail('');
    setRole('moderator');
    setSelectedPermissions([]);
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
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Admin Management</h1>
          <p className="text-sm text-zinc-400">Configure administrative access scopes and granular role-based permissions.</p>
        </div>
        <button
          onClick={startAdd}
          className="flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-xs font-semibold shadow transition-colors self-start"
        >
          <Plus size={14} /> Add Administrator
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Table of Admins */}
        <div className="lg:col-span-2 glass-panel rounded-2xl overflow-hidden h-fit">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                  <th className="p-4 font-semibold">User details</th>
                  <th className="p-4 font-semibold">Role Name</th>
                  <th className="p-4 font-semibold">Active Scopes</th>
                  <th className="p-4 font-semibold text-right">Joined Date</th>
                  <th className="p-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-900">
                {admins.map((a) => (
                  <tr key={a.id} className="hover:bg-zinc-900/30 text-zinc-300">
                    <td className="p-4">
                      <span className="font-semibold text-white block">{a.name}</span>
                      <span className="text-[10px] text-zinc-500 block mt-0.5">{a.email}</span>
                    </td>
                    <td className="p-4">
                      <span className="inline-flex px-2 py-0.5 bg-indigo-500/10 text-indigo-400 font-bold rounded text-[9px] capitalize">
                        {a.role.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="p-4">
                      <div className="flex flex-wrap gap-1 max-w-xs">
                        {a.permissions.length > 0 ? (
                          a.permissions.map(p => (
                            <span key={p} className="px-1.5 py-0.5 bg-zinc-900 border border-zinc-800 text-zinc-400 text-[9px] rounded font-medium">
                              {p}
                            </span>
                          ))
                        ) : (
                          <span className="text-zinc-500 italic">No access scopes</span>
                        )}
                      </div>
                    </td>
                    <td className="p-4 text-right text-zinc-500">{a.joinedAt}</td>
                    <td className="p-4 text-right">
                      <div className="flex justify-end gap-1.5">
                        <button
                          onClick={() => startEdit(a)}
                          className="px-2 py-1 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 text-zinc-300 rounded text-[10px] font-semibold transition-colors"
                        >
                          Modify Scopes
                        </button>
                        {a.id !== 'ADM001' && (
                          <button
                            onClick={() => deleteAdmin(a.id, a.name)}
                            className="p-1.5 bg-zinc-900 border border-zinc-800 hover:bg-red-950/20 hover:text-red-400 text-zinc-500 rounded transition-colors"
                            title="Delete Admin"
                          >
                            <Trash2 size={12} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Editor Sidebar */}
        {(isAdding || editingAdmin) ? (
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 h-fit space-y-4">
            <div>
              <h2 className="text-base font-semibold text-white">
                {isAdding ? 'Initialize Admin' : `Modify: ${editingAdmin?.name}`}
              </h2>
              <p className="text-xs text-zinc-400">Configure administrative capabilities and login scopes.</p>
            </div>

            <form onSubmit={handleSave} className="space-y-4 text-xs">
              <div>
                <label className="block text-zinc-500 mb-1">Full Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. John Doe"
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none"
                  required
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Email Address</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@coincalling.com"
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none"
                  required
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1 font-medium">System Role Target</label>
                <select
                  value={role}
                  onChange={(e: any) => setRole(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none font-semibold"
                >
                  <option value="super_admin">Super Admin (All Access)</option>
                  <option value="finance_admin">Finance Admin</option>
                  <option value="support_admin">Support Admin</option>
                  <option value="moderator">Moderator</option>
                </select>
              </div>

              <div className="space-y-2 border-t border-zinc-900 pt-3">
                <label className="block text-zinc-500 font-medium mb-1">Granular Scopes Assigned</label>
                <div className="space-y-1.5">
                  {availablePermissions.map(p => (
                    <label key={p.id} className="flex items-center gap-2 p-2 rounded-lg bg-zinc-900/30 hover:bg-zinc-900/60 border border-zinc-900 cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={selectedPermissions.includes(p.id)}
                        onChange={() => handlePermissionToggle(p.id)}
                        className="rounded text-indigo-600 focus:ring-indigo-500 w-3.5 h-3.5"
                      />
                      <span className="text-[11px] font-medium text-zinc-300">{p.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div className="flex gap-2 pt-2 border-t border-zinc-900">
                <button
                  type="submit"
                  className="flex-1 py-2 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold rounded-lg transition-colors"
                >
                  Save Access Account
                </button>
                <button
                  type="button"
                  onClick={() => { setIsAdding(false); setEditingAdmin(null); }}
                  className="px-3 bg-zinc-900 hover:bg-zinc-800 text-zinc-400 font-semibold border border-zinc-800 rounded-lg transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        ) : (
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 h-fit text-center text-zinc-500 text-xs">
            Select an account to modify its access configurations, or initialize a new administrator credentials.
          </div>
        )}

      </div>
    </div>
  );
}
