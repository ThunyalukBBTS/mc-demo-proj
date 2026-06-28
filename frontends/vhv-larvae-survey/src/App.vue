<script setup lang="ts">
import { useRouter, useRoute } from 'vue-router'
import { LayoutDashboard, FileSpreadsheet, History, ShieldAlert } from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()

const navItems = [
  { name: 'แดชบอร์ด', path: '/', icon: LayoutDashboard },
  { name: 'บันทึกสำรวจ', path: '/survey', icon: FileSpreadsheet },
  { name: 'ประวัติและรายงาน', path: '/history', icon: History }
]

const isActive = (path: string) => {
  return route.path === path
}
</script>

<template>
  <div class="min-h-screen bg-slate-50 flex flex-col pb-16 md:pb-0">
    <!-- Header (Desktop Navbar) -->
    <header class="bg-white border-b border-slate-200 sticky top-0 z-40">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16 items-center">
          <!-- Logo / Title -->
          <div class="flex items-center space-x-3 cursor-pointer" @click="router.push('/')">
            <div class="bg-emerald-500 text-white p-2 rounded-lg shadow-sm flex items-center justify-center">
              <ShieldAlert class="w-5 h-5" />
            </div>
            <div>
              <h1 class="text-lg font-bold text-slate-800 tracking-tight leading-none">สำรวจลูกน้ำยุงลาย</h1>
              <p class="text-xs text-slate-500 font-medium">ระบบติดตามและกำจัดลูกน้ำ (อสม. มัญจาคีรี)</p>
            </div>
          </div>

          <!-- Desktop Navigation Menu -->
          <nav class="hidden md:flex space-x-1">
            <router-link
              v-for="item in navItems"
              :key="item.path"
              :to="item.path"
              class="px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center space-x-2"
              :class="isActive(item.path) 
                ? 'bg-emerald-50 text-emerald-700 shadow-sm' 
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'"
            >
              <component :is="item.icon" class="w-4 h-4" />
              <span>{{ item.name }}</span>
            </router-link>
          </nav>
        </div>
      </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-grow max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>

    <!-- Mobile Bottom Navigation Bar -->
    <nav class="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 shadow-lg px-6 py-2 flex justify-between z-40">
      <router-link
        v-for="item in navItems"
        :key="item.path"
        :to="item.path"
        class="flex flex-col items-center justify-center flex-1 py-1 px-2 rounded-lg transition-all duration-150"
        :class="isActive(item.path) ? 'text-emerald-600' : 'text-slate-400 hover:text-slate-600'"
      >
        <component :is="item.icon" class="w-5 h-5 mb-0.5" />
        <span class="text-[10px] font-medium leading-none">{{ item.name }}</span>
      </router-link>
    </nav>
  </div>
</template>

<style scoped>
/* Fade view transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
