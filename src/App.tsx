import { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './hooks/useAuth';
import Navbar from './components/layout/Navbar';
import ModalCenter from './components/layout/ModalCenter';
import ScrollToTop from './components/layout/ScrollToTop';
import { InstallPrompt } from './components/ui/InstallPrompt';
import NotificationManager from './components/notifications/NotificationManager';
import ToastContainer from './components/notifications/ToastContainer';
import { motion } from 'framer-motion';

// Import pages directly to prevent lazy loading context issues
import AuthPage from './pages/AuthPage';
import SettingsPage from './pages/SettingsPage';
import HomePage from './pages/HomePage';
import MessagesPage from './pages/MessagesPage';
import UserProfilePage from './pages/UserProfilePage';
import PostPage from './pages/PostPage';
import NotFoundPage from './pages/NotFoundPage';
import AdminPage from './pages/AdminPage';

const LoadingScreen = ({ message = "Cargando..." }) => (
  <div className="flex min-h-screen items-center justify-center bg-black">
    <div className="flex flex-col items-center space-y-6">
      <motion.div
        animate={{ 
          scale: [1, 1.05, 1],
          opacity: [0.9, 1, 0.9]
        }}
        transition={{ 
          duration: 3,
          repeat: Infinity,
          ease: "easeInOut"
        }}
        className="h-24 w-24 rounded-3xl bg-zinc-900 shadow-[0_0_50px_rgba(230,0,0,0.1)] border border-white/5 overflow-hidden ring-1 ring-passion-red/20"
      >
        <img src="/logo_real.jpg" alt="Privé Chat Logo" className="h-full w-full object-cover" referrerPolicy="no-referrer" />
      </motion.div>
      <div className="flex flex-col items-center space-y-3">
        <div className="h-1 w-40 bg-white/5 rounded-full overflow-hidden border border-white/5">
          <motion.div 
            initial={{ x: "-100%" }}
            animate={{ x: "100%" }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
            className="h-full w-1/2 bg-gradient-to-r from-transparent via-passion-red to-transparent"
          />
        </div>
        <p className="text-[10px] font-black uppercase tracking-[0.3em] passion-text opacity-80">{message}</p>
      </div>
    </div>
  </div>
);

export default function App() {
  const { user, profile, loading } = useAuth();

  if (loading) {
    return <LoadingScreen message="Cargando Privé Chat..." />;
  }

  return (
    <>
      <ScrollToTop />
      <InstallPrompt />
      <div className="min-h-screen">
        <ToastContainer />
        <Suspense fallback={<LoadingScreen />}>
          {user ? (
            <>
              <Navbar />
              <NotificationManager />
              <ModalCenter />
              <main>
                <Routes>
                  <Route path="/" element={<HomePage />} />
                  <Route path="/messages" element={<MessagesPage />} />
                  <Route path="/settings" element={<SettingsPage />} />
                  <Route path="/profile/:userId" element={<UserProfilePage />} />
                  <Route path="/post/:postId" element={<PostPage />} />
                  <Route path="/auth" element={<Navigate to="/" replace />} />
                  {profile?.role?.toLowerCase().trim() === 'super_admin' && (
                    <Route path="/admin" element={<AdminPage />} />
                  )}
                  <Route path="*" element={<NotFoundPage />} />
                </Routes>
              </main>
            </>
          ) : (
            <Routes>
              <Route path="/auth" element={<AuthPage />} />
              <Route path="*" element={<Navigate to="/auth" replace />} />
            </Routes>
          )}
        </Suspense>
      </div>
    </>
  );
}
