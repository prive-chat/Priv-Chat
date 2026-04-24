import { useState, useEffect } from 'react';
import { Ad } from '@/src/types';
import { publicAdService } from '@/src/services/publicAdService';
import { ExternalLink, Megaphone, X, Maximize2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { cn } from '@/src/lib/utils';
import { Button } from './Button';

interface AdCardProps {
  ad: Ad;
}

export function AdCard({ ad }: AdCardProps) {
  const [isFullscreen, setIsFullscreen] = useState(false);

  useEffect(() => {
    // Track impression when component mounts
    publicAdService.trackImpression(ad.id);
  }, [ad.id]);

  useEffect(() => {
    if (isFullscreen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isFullscreen]);

  const handleLinkClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!ad.link_url) return;
    publicAdService.trackClick(ad.id);
    window.open(ad.link_url, '_blank', 'noopener,noreferrer');
  };

  const handleCardClick = () => {
    setIsFullscreen(true);
  };

  const hasLink = !!ad.link_url;

  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className={cn(
          "relative group overflow-hidden rounded-3xl bg-white/5 border border-white/10 transition-all duration-500",
          "cursor-pointer hover:border-primary-600/50 shadow-2xl shadow-black/50"
        )}
        onClick={handleCardClick}
      >
        {/* Ad Badge */}
        <div className="absolute top-4 left-4 z-10 flex items-center gap-1.5 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md border border-white/10">
          <Megaphone size={10} className="text-primary-400" />
          <span className="text-[10px] font-black uppercase tracking-widest text-white/80">Patrocinado</span>
        </div>

        {/* Image/Video Container */}
        <div className="relative overflow-hidden bg-black/20 aspect-video">
          {ad.image_url && (
            ad.type === 'video' ? (
              <video 
                src={ad.image_url} 
                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                autoPlay
                muted
                loop
                playsInline
              />
            ) : (
              <img 
                src={ad.image_url} 
                alt={ad.title}
                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                referrerPolicy="no-referrer"
              />
            )
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
          
          {/* Fullscreen Hint */}
          <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
             <div className="p-3 rounded-full bg-white/10 backdrop-blur-md border border-white/20">
               <Maximize2 size={24} className="text-white" />
             </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          <div className="flex flex-col gap-4">
            <div>
              <h4 className="text-lg font-black text-white uppercase italic leading-tight group-hover:text-primary-400 transition-colors">
                {ad.title}
              </h4>
              {ad.description && (
                <p className="text-sm text-white/60 mt-2 line-clamp-2 leading-relaxed">
                  {ad.description}
                </p>
              )}
            </div>
            
            {hasLink && (
              <Button
                onClick={handleLinkClick}
                variant="primary"
                size="sm"
                className="w-full font-black uppercase tracking-widest italic h-10"
              >
                {ad.cta_text || 'Saber más'}
                <ExternalLink size={14} className="ml-2" />
              </Button>
            )}
          </div>
          
          <div className="mt-4 pt-4 border-t border-white/5 flex items-center justify-between">
            <span className="text-[10px] font-bold text-white/40 uppercase tracking-widest">
              Contenido Patrocinado
            </span>
            <div className="flex gap-1">
              {[1, 2, 3].map((i) => (
                <div key={i} className={cn(
                  "h-1 w-4 rounded-full bg-primary-600/20 transition-colors group-hover:bg-primary-600/40"
                )} />
              ))}
            </div>
          </div>
        </div>
      </motion.div>

      {/* Fullscreen Overlay */}
      <AnimatePresence>
        {isFullscreen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-black/95 backdrop-blur-xl flex flex-col items-center justify-center p-4 lg:p-12 overflow-y-auto"
            onClick={() => setIsFullscreen(false)}
          >
            {/* Close Button */}
            <button 
              className="absolute top-6 right-6 lg:top-12 lg:right-12 p-3 rounded-full bg-white/5 hover:bg-white/10 border border-white/10 text-white transition-all z-[110]"
              onClick={(e) => {
                e.stopPropagation();
                setIsFullscreen(false);
              }}
            >
              <X size={24} />
            </button>

            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              className="w-full max-w-6xl flex flex-col lg:flex-row items-center gap-8 lg:gap-16 my-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Media Container */}
              <div className="w-full lg:w-3/5 aspect-video lg:aspect-[4/3] rounded-3xl overflow-hidden shadow-2xl shadow-primary-600/10 border border-white/10 bg-black flex items-center justify-center shrink-0">
                {ad.image_url && (
                  ad.type === 'video' ? (
                    <video 
                      src={ad.image_url} 
                      className="w-full h-full object-contain"
                      autoPlay
                      controls
                      loop
                      playsInline
                    />
                  ) : (
                    <img 
                      src={ad.image_url} 
                      alt={ad.title}
                      className="w-full h-full object-contain"
                      referrerPolicy="no-referrer"
                    />
                  )
                )}
              </div>

              {/* Text Container */}
              <div className="w-full lg:w-2/5 space-y-8 flex flex-col items-center lg:items-start text-center lg:text-left">
                <div className="space-y-4">
                  <div className="flex items-center justify-center lg:justify-start gap-2 text-primary-400">
                    <Megaphone size={18} />
                    <span className="text-xs font-black uppercase tracking-[0.2em]">Destacado</span>
                  </div>
                  <h2 className="text-4xl lg:text-6xl font-black text-white italic uppercase tracking-tighter leading-[0.9]">
                    {ad.title}
                  </h2>
                  {ad.description && (
                    <p className="text-base lg:text-lg text-white/60 leading-relaxed max-w-lg font-medium">
                      {ad.description}
                    </p>
                  )}
                </div>

                {hasLink && (
                  <Button
                    onClick={handleLinkClick}
                    variant="primary"
                    size="lg"
                    className="w-full sm:w-auto px-12 h-16 text-xl font-black uppercase tracking-widest italic shadow-[0_0_30px_rgba(230,0,0,0.3)] transition-all hover:scale-105"
                  >
                    {ad.cta_text || 'Saber más'}
                    <ExternalLink size={24} className="ml-3" />
                  </Button>
                )}

                <div className="pt-8 border-t border-white/5 w-full flex items-center justify-center lg:justify-start gap-4">
                   <div className="h-2 w-2 rounded-full bg-primary-600" />
                   <span className="text-[10px] font-bold text-white/40 uppercase tracking-[0.3em]">Privé Chat Platinum Partner</span>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
