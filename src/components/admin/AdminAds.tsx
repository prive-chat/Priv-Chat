import React from 'react';
import { Card } from '@/src/components/ui/Card';
import { Button } from '@/src/components/ui/Button';
import { Plus, Eye, MousePointer2, Calendar, Trash2, Edit2 } from 'lucide-react';
import { Ad } from '@/src/types';
import { cn } from '@/src/lib/utils';
import { useUIStore } from '@/src/store/uiStore';

interface AdminAdsProps {
  ads: Ad[];
  onDeleteAd: (id: string) => void;
  onRefresh: () => void;
}

export function AdminAds({ ads, onDeleteAd, onRefresh }: AdminAdsProps) {
  const setActiveModal = useUIStore((state) => state.setActiveModal);

  const handleEdit = (ad: Ad) => {
    setActiveModal('ad', { ...ad, onSuccess: onRefresh });
  };

  const handleCreate = () => {
    setActiveModal('ad', { onSuccess: onRefresh });
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h3 className="text-xl font-black text-white uppercase italic">Gestión de Publicidad</h3>
        <Button variant="primary" size="sm" onClick={handleCreate}>
          <Plus size={18} className="mr-2" /> Nuevo Anuncio
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {ads.map((ad) => (
          <Card key={ad.id} className="glass-card border-none overflow-hidden flex flex-col sm:flex-row">
            <div className="w-full sm:w-48 h-48 sm:h-auto relative">
              {ad.image_url && (
                ad.type === 'video' ? (
                  <video src={ad.image_url} className="h-full w-full object-cover" />
                ) : (
                  <img src={ad.image_url} className="h-full w-full object-cover" />
                )
              )}
              <div className="absolute top-2 left-2">
                <span className={cn(
                  "text-[8px] font-black px-2 py-1 rounded uppercase tracking-widest",
                  ad.status === 'active' ? "bg-green-500 text-white" : 
                  ad.status === 'paused' ? "bg-yellow-500 text-black" : "bg-blue-500 text-white"
                )}>
                  {ad.status}
                </span>
              </div>
            </div>
            
            <div className="flex-1 p-6 flex flex-col">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h4 className="text-white font-bold">{ad.title}</h4>
                  <p className="text-[10px] text-white/40 uppercase font-black tracking-widest">{ad.placement}</p>
                </div>
                <div className="flex gap-1">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-8 w-8 p-0 text-white/20 hover:text-primary-400"
                    onClick={() => handleEdit(ad)}
                  >
                    <Edit2 size={14} />
                  </Button>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-8 w-8 p-0 text-white/20 hover:text-red-400"
                    onClick={() => onDeleteAd(ad.id)}
                  >
                    <Trash2 size={16} />
                  </Button>
                </div>
              </div>
              
              <div className="grid grid-cols-3 gap-4 my-4">
                <div className="text-center p-2 bg-white/5 rounded-lg">
                  <div className="flex items-center justify-center gap-1 text-blue-400 mb-1">
                    <Eye size={12} />
                    <span className="text-[10px] font-black">{ad.impressions}</span>
                  </div>
                  <p className="text-[8px] text-white/20 uppercase font-bold">Vistas</p>
                </div>
                <div className="text-center p-2 bg-white/5 rounded-lg">
                  <div className="flex items-center justify-center gap-1 text-green-400 mb-1">
                    <MousePointer2 size={12} />
                    <span className="text-[10px] font-black">{ad.clicks}</span>
                  </div>
                  <p className="text-[8px] text-white/20 uppercase font-bold">Clicks</p>
                </div>
                <div className="text-center p-2 bg-white/5 rounded-lg">
                  <div className="flex items-center justify-center gap-1 text-primary-400 mb-1">
                    <Calendar size={12} />
                    <span className="text-[10px] font-black">
                      {ad.impressions > 0 ? ((ad.clicks / ad.impressions) * 100).toFixed(1) : 0}%
                    </span>
                  </div>
                  <p className="text-[8px] text-white/20 uppercase font-bold">CTR</p>
                </div>
              </div>
              
              <p className="text-xs text-white/40 mb-4 line-clamp-2">{ad.description}</p>
              
              <div className="mt-auto flex gap-2">
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="flex-1 text-[10px] font-black uppercase tracking-widest"
                  onClick={() => handleEdit(ad)}
                >
                  Configurar
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
