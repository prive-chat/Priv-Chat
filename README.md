# 🍷 Privé Chat

![Privé Chat Banner](https://picsum.photos/seed/privechat/1200/400?blur=2)

**Privé Chat** es una plataforma modular y escalable de grado empresarial diseñada para la gestión de medios y mensajería segura. Construida con un enfoque en la privacidad, el rendimiento y una experiencia de usuario inmersiva.

## ✨ Características

- 🛡️ **Seguridad de Grado Empresarial:** Integración robusta con Supabase para autenticación y base de datos.
- 📱 **Mensajería en Tiempo Real:** Chat fluido con soporte para medios y confirmaciones de lectura.
- 🖼️ **Gestión de Medios:** Feed dinámico con carga y visualización optimizada.
- 🔔 **Notificaciones Push:** Mantente al día con notificaciones nativas del navegador (Web Push API).
- 🎨 **Diseño Glassmorphism:** Interfaz moderna, oscura y elegante inspirada en la estética de lujo.
- ⚡ **Rendimiento:** Carga diferida (lazy loading), optimización de imágenes y consultas con TanStack Query.
- 👤 **Perfiles de Usuario:** Gestión de perfiles, seguidores y verificación de cuentas.

## 🚀 Tecnologías

- **Frontend:** [React 19](https://react.dev/), [Vite](https://vitejs.dev/), [TypeScript](https://www.typescriptlang.org/).
- **Estilos:** [Tailwind CSS 4](https://tailwindcss.com/).
- **Backend:** [Supabase](https://supabase.com/) (Auth, Database, Storage, Realtime).
- **Estado:** [Zustand](https://docs.pmnd.rs/zustand/) & [TanStack Query](https://tanstack.com/query/latest).
- **Animaciones:** [Motion](https://motion.dev/).
- **Iconos:** [Lucide React](https://lucide.dev/).

## 🛠️ Instalación

### Requisitos Previos

- Node.js 20 o superior.
- Una cuenta en [Supabase](https://supabase.com/).

### Pasos

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/nexonetworkec-arch/prive-chat.git
   cd prive-chat
   ```

2. **Instalar dependencias:**
   ```bash
   npm install
   ```

3. **Configurar variables de entorno:**
   Copia el archivo `.env.example` a `.env` y completa tus credenciales de Supabase:
   ```bash
   cp .env.example .env
   ```
   *Nota: Necesitarás `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` de tu proyecto Supabase.*

4. **Configurar la base de datos:**
   - Ve al SQL Editor de tu proyecto en Supabase.
   - Copia y ejecuta el contenido del archivo `supabase_schema.sql`.
   - Asegúrate de habilitar el **Storage** creando un bucket público llamado `media`.

5. **Iniciar en desarrollo:**
   ```bash
   npm run dev
   ```

## 📦 Despliegue

Para generar la versión de producción:
```bash
npm run build
```
El contenido de la carpeta `dist` está listo para ser servido en cualquier hosting estático (Vercel, Netlify, GitHub Pages).

## 🛡️ Seguridad

Para reportar vulnerabilidades, consulta nuestra [Política de Seguridad](SECURITY.md).

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para empezar.

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta [LICENSE](LICENSE) para más información.

---
Desarrollado con ❤️ por el equipo de Privé Chat.
