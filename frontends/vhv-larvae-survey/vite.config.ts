import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load env files from the project root (two levels up) and local directory
  const rootEnv = loadEnv(mode, path.resolve(__dirname, '../../'), '')
  const localEnv = loadEnv(mode, __dirname, '')
  
  // Set fallbacks for client env variables
  const supabaseUrl = localEnv.VITE_SUPABASE_URL || rootEnv.VITE_SUPABASE_URL || rootEnv.SUPABASE_URL || ''
  const supabasePublishableKey = localEnv.VITE_SUPABASE_PUBLISHABLE_KEY || localEnv.VITE_SUPABASE_SECRET_KEY || rootEnv.VITE_SUPABASE_PUBLISHABLE_KEY || rootEnv.VITE_SUPABASE_SECRET_KEY || rootEnv.SUPABASE_PUBLISHABLE_KEY || ''

  return {
    plugins: [
      vue(),
      tailwindcss(),
    ],
    server: {
      port: 5180,
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    base: './', // support nested deployment subdirectories (GitHub Pages, Cloudflare Pages)
    define: {
      'import.meta.env.VITE_SUPABASE_URL': JSON.stringify(supabaseUrl),
      'import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY': JSON.stringify(supabasePublishableKey),
      'import.meta.env.VITE_SUPABASE_SECRET_KEY': JSON.stringify(supabasePublishableKey),
    }
  }
})
