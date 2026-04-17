import { useEffect } from 'react';
import { Ad } from '@/src/types';
import { publicAdService } from '@/src/services/publicAdService';
import { ExternalLink, Megaphone } from 'lucide-react';
import { motion } from 'framer-motion';
import { cn } from '@/src/lib/utils';

interface AdCardProps {
  ad: Ad;
}

export function AdCard({ ad }: AdCardProps) {
  useEffect(() => {
    // Track impression when component mounts
    publicAdService.trackImpression(ad.id);
  }, [ad.id]);

  const handleClick = () => {
    if (!ad.link_url) return;
    publicAdService.trackClick(ad.id);
    window.open(ad.link_url, '_blank', 'noopener,noreferrer');
  };

  const hasLink = !!ad.link_url;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className={cn(
        "relative group overflow-hidden rounded-3xl bg-white/5 border border-white/10 transition-all duration-500",
        hasLink ? "cursor-pointer hover:border-primary-600/50" : "cursor-default"
      )}
      onClick={handleClick}
    >
      {/* Ad Badge */}
      <div className="absolute top-4 left-4 z-10 flex items-center gap-1.5 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md border border-white/10">
        <Megaphone size={10} className="text-primary-400" />
        <span className="text-[10px] font-black uppercase tracking-widest text-white/80">Patrocinado</span>
      </div>

      {/* Image/Video Container */}
      <div className="relative overflow-hidden bg-black/20">
        {ad.image_url && (
          ad.type === 'video' ? (
            <video 
              src={ad.image_url} 
              className="w-full h-auto max-h-[500px] object-contain transition-transform duration-700 group-hover:scale-105"
              autoPlay
              muted
              loop
              playsInline
            />
          ) : (
            <img 
              src={ad.image_url} 
              alt={ad.title}
              className="w-full h-auto max-h-[500px] object-contain transition-transform duration-700 group-hover:scale-110"
              referrerPolicy="no-referrer"
            />
          )
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
      </div>

      {/* Content */}
      <div className="p-6">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h4 className={cn(
              "text-lg font-black text-white uppercase italic leading-tight transition-colors",
              hasLink && "group-hover:text-primary-400"
            )}>
              {ad.title}
            </h4>
            {ad.description && (
              <p className="text-sm text-white/60 mt-2 line-clamp-2 leading-relaxed">
                {ad.description}
              </p>
            )}
          </div>
          {hasLink && (
            <div className="h-10 w-10 rounded-full bg-primary-600/20 flex items-center justify-center text-primary-400 group-hover:bg-primary-600 group-hover:text-white transition-all duration-300">
              <ExternalLink size={18} />
            </div>
          )}
        </div>
        
        <div className="mt-4 pt-4 border-t border-white/5 flex items-center justify-between">
          <span className="text-[10px] font-bold text-white/40 uppercase tracking-widest">
            {hasLink ? 'Visitar sitio oficial' : 'Contenido Patrocinado'}
          </span>
          <div className="flex gap-1">
            {[1, 2, 3].map((i) => (
              <div key={i} className={cn(
                "h-1 w-4 rounded-full bg-primary-600/20 transition-colors",
                hasLink && "group-hover:bg-primary-600/40"
              )} />
            ))}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
