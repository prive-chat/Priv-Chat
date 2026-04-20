import React from 'react';
import { motion } from 'framer-motion';

interface LogoProps {
  className?: string;
  size?: number;
  glow?: boolean;
}

/**
 * Privé Chat - "Enclave Privé" Logo
 * Symbolizes secure communication through interlocking chat bubbles 
 * that form a lock in negative space.
 */
export const Logo: React.FC<LogoProps> = ({ className = "", size = 64, glow = true }) => {
  return (
    <div className={`relative flex items-center justify-center ${className}`}>
      {glow && (
        <motion.div
          animate={{ opacity: [0.3, 0.5, 0.3], scale: [1, 1.05, 1] }}
          transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
          className="absolute inset-0 bg-passion-red/20 blur-[40px] rounded-full text-passion-red"
        />
      )}
      <svg
        width={size}
        height={size}
        viewBox="0 0 512 512"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="relative z-10 drop-shadow-[0_0_15px_rgba(198,40,40,0.5)]"
      >
        <defs>
          {/* Crimson Crystal Gradient */}
          <linearGradient id="logo_red_grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FF4D4D" />
            <stop offset="50%" stopColor="#C62828" />
            <stop offset="100%" stopColor="#8B0000" />
          </linearGradient>
          
          {/* Subtle Shine Overlay */}
          <linearGradient id="logo_shine" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="white" stopOpacity="0.4" />
            <stop offset="40%" stopColor="white" stopOpacity="0" />
            <stop offset="100%" stopColor="white" stopOpacity="0.1" />
          </linearGradient>
        </defs>

        {/* Refined Message Bubble Frame - Precision Rounded & Optically Balanced */}
        <path
          d="M90 120C90 103.431 103.431 90 120 90H392C408.569 90 422 103.431 422 120V320C422 336.569 408.569 350 392 350H230L130 422V350H120C103.431 350 90 336.569 90 320V120Z"
          stroke="url(#logo_red_grad)"
          strokeWidth="24"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* The "PC" Monogram - Geometrically Aligned */}
        {/* Optimized P */}
        <path
          d="M185 300V180H235C255 180 270 195 270 215C270 235 255 250 235 250H185"
          stroke="url(#logo_red_grad)"
          strokeWidth="28"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        
        {/* Optimized C - Matching P's geometry exactly */}
        <path
          d="M340 180C340 170 330 160 310 160H290C265 160 265 190 265 240V240C265 290 265 320 290 320H310C330 320 340 310 340 300"
          stroke="url(#logo_red_grad)"
          strokeWidth="28"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Refined Detail: Crystal Shine Overlay */}
        <path
          d="M110 110C110 104.477 114.477 100 120 100H392C397.523 100 402 104.477 402 110V110C402 115.523 397.523 120 392 120H120C114.477 120 110 115.523 110 110V110Z"
          fill="url(#logo_shine)"
          className="opacity-30 pointer-events-none"
        />
      </svg>
    </div>
  );
};
