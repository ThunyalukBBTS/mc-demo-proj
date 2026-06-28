<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabaseClient'
import { 
  Search, 
  Trash2, 
  Pencil,
  Calendar, 
  AlertTriangle,
  RotateCw,
  Clock,
  Home,
  Activity
} from 'lucide-vue-next'

const router = useRouter()

interface Village {
  id: string
  name: string
  moo: number
  sub_district: string
  district: string
  province: string
  postcode: string
}

interface Survey {
  id: string
  village_id: string
  households_surveyed: number
  households_positive: number
  hi: number
  containers_surveyed: number
  containers_positive: number
  ci: number
  school_containers_surveyed: number
  school_containers_positive: number
  hospital_containers_surveyed: number
  hospital_containers_positive: number
  factory_containers_surveyed: number
  factory_containers_positive: number
  public_office_containers_surveyed: number
  public_office_containers_positive: number
  created_at: string
}

const villages = ref<Village[]>([])
const surveys = ref<Survey[]>([])
const loading = ref(true)
const errorMsg = ref('')

// Filter states
const selectedTambon = ref('ทั้งหมด')
const selectedPeriod = ref('all') // '7' | '30' | 'all'
const searchQuery = ref('')

// Delete states
const showDeleteConfirm = ref<string | null>(null)
const deleting = ref(false)

const loadData = async () => {
  loading.value = true
  errorMsg.value = ''
  try {
    const { data: vData, error: vError } = await supabase
      .from('villages')
      .select('*')
      .is('deleted_at', null)
      
    if (vError) throw vError
    villages.value = vData || []
    
    const { data: sData, error: sError } = await supabase
      .from('surveys')
      .select('*')
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      
    if (sError) throw sError
    surveys.value = sData || []
  } catch (err: any) {
    console.error('Error loading history:', err)
    errorMsg.value = 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้ กรุณาตรวจสอบการตั้งค่า Supabase ของคุณ'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
})

// Unique Tambons list
const tambons = computed(() => {
  const list = new Set(villages.value.map(v => v.sub_district))
  return ['ทั้งหมด', ...Array.from(list).sort()]
})

// Helper mapping to get village name
const getVillageDetails = (villageId: string) => {
  const v = villages.value.find(x => x.id === villageId)
  if (!v) return { name: 'ไม่ทราบชื่อ', moo: 0, sub_district: 'ไม่ทราบตำบล' }
  return { name: v.name, moo: v.moo, sub_district: v.sub_district }
}

// Combined & Filtered Surveys for Table
const filteredSurveys = computed(() => {
  let list = surveys.value
  
  // Date period filter
  if (selectedPeriod.value !== 'all') {
    const cutoffDate = new Date()
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(selectedPeriod.value))
    list = list.filter(s => new Date(s.created_at) >= cutoffDate)
  }
  
  // Combine with village info for text search & tambon filter
  const items = list.map(s => {
    const v = getVillageDetails(s.village_id)
    return {
      ...s,
      villageName: v.name,
      moo: v.moo,
      subDistrict: v.sub_district
    }
  })
  
  // Apply Tambon Filter
  let filtered = items
  if (selectedTambon.value !== 'ทั้งหมด') {
    filtered = filtered.filter(item => item.subDistrict === selectedTambon.value)
  }
  
  // Apply text search
  const query = searchQuery.value.trim().toLowerCase()
  if (query) {
    filtered = filtered.filter(item => 
      item.villageName.toLowerCase().includes(query) ||
      item.moo.toString().includes(query) ||
      item.subDistrict.toLowerCase().includes(query)
    )
  }
  
  return filtered
})

// Trigger soft delete
const confirmDelete = (id: string) => {
  showDeleteConfirm.value = id
}

const editSurvey = (id: string) => {
  router.push({ path: '/survey', query: { id } })
}

const performSoftDelete = async (id: string) => {
  deleting.value = true
  try {
    const { error } = await supabase
      .from('surveys')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
      
    if (error) throw error
    
    // Remove from local list
    surveys.value = surveys.value.filter(s => s.id !== id)
    showDeleteConfirm.value = null
  } catch (err) {
    console.error('Error soft deleting survey:', err)
  } finally {
    deleting.value = false
  }
}

// Date formatter helper
const formatDate = (isoString: string) => {
  const date = new Date(isoString)
  return `${date.getDate()} ${date.toLocaleString('th-TH', { month: 'short' })} ${date.getFullYear() + 543}`
}

const getRiskTextClass = (val: number) => {
  if (val < 10) return 'text-emerald-600 font-bold'
  if (val < 20) return 'text-yellow-600 font-bold'
  return 'text-rose-600 font-bold'
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h2 class="text-xl font-extrabold text-slate-800">ประวัติรายงานและบันทึกข้อมูล</h2>
      <p class="text-xs text-slate-500">ตารางข้อมูลดิบสำหรับเจ้าหน้าที่สาธารณสุขในการตรวจสอบและบริหารจัดการ</p>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center min-h-[40vh] space-y-4">
      <div class="animate-spin rounded-full h-10 w-10 border-4 border-emerald-500 border-t-transparent"></div>
      <p class="text-slate-500 font-medium">กำลังดึงข้อมูลรายงาน...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMsg" class="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center space-y-4 max-w-lg mx-auto">
      <div class="flex justify-center text-rose-500">
        <AlertTriangle class="w-12 h-12" />
      </div>
      <h3 class="text-md font-bold text-slate-800">เกิดข้อผิดพลาดในการโหลดข้อมูล</h3>
      <p class="text-xs text-slate-600">{{ errorMsg }}</p>
      <button @click="loadData" class="bg-rose-600 hover:bg-rose-700 text-white font-semibold px-4 py-2 rounded-xl text-xs flex items-center space-x-1.5 mx-auto">
        <RotateCw class="w-3.5 h-3.5" />
        <span>ลองใหม่อีกครั้ง</span>
      </button>
    </div>

    <!-- Content -->
    <div v-else class="space-y-4">
      <!-- Filter Bar -->
      <div class="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        <div class="flex flex-wrap items-center gap-3">
          <!-- Filter Tambon -->
          <div class="flex flex-col">
            <span class="text-[10px] text-slate-400 font-bold mb-1">ตำบล</span>
            <select 
              v-model="selectedTambon"
              class="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer"
            >
              <option v-for="t in tambons" :key="t" :value="t">{{ t }}</option>
            </select>
          </div>

          <!-- Filter Period -->
          <div class="flex flex-col">
            <span class="text-[10px] text-slate-400 font-bold mb-1">ช่วงเวลา</span>
            <select 
              v-model="selectedPeriod"
              class="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer"
            >
              <option value="7">7 วันที่ผ่านมา</option>
              <option value="30">30 วันที่ผ่านมา</option>
              <option value="all">ทั้งหมด</option>
            </select>
          </div>
        </div>

        <!-- Search input -->
        <div class="relative max-w-xs w-full">
          <Search class="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="ค้นหาหมู่บ้าน/หมู่ที่/ตำบล..."
            class="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500 text-slate-700"
          />
        </div>

      </div>

      <!-- Delete Confirmation Modal overlay -->
      <div 
        v-if="showDeleteConfirm" 
        class="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in"
      >
        <div class="bg-white rounded-2xl border border-slate-200 max-w-sm w-full p-6 space-y-4 shadow-xl">
          <div class="flex justify-center text-rose-500">
            <AlertTriangle class="w-12 h-12 animate-bounce" />
          </div>
          <div class="text-center space-y-2">
            <h3 class="text-md font-bold text-slate-800">ยืนยันการลบรายงาน?</h3>
            <p class="text-xs text-slate-500">ข้อมูลรายงานการสำรวจนี้จะถูกลบออกจากระบบชั่วคราว คุณสามารถกู้คืนได้ภายหลังโดยติดต่อผู้ดูแลระบบ</p>
          </div>
          <div class="flex space-x-3">
            <button 
              @click="showDeleteConfirm = null" 
              :disabled="deleting"
              class="flex-1 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold py-2.5 rounded-xl text-xs transition-colors"
            >
              ยกเลิก
            </button>
            <button 
              @click="performSoftDelete(showDeleteConfirm!)" 
              :disabled="deleting"
              class="flex-1 bg-rose-600 hover:bg-rose-700 text-white font-semibold py-2.5 rounded-xl text-xs transition-colors flex items-center justify-center"
            >
              <span v-if="deleting" class="animate-spin rounded-full h-3 w-3 border-2 border-white border-t-transparent mr-1"></span>
              <span>ยืนยันการลบ</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Raw Table Data (Desktop view) -->
      <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden hidden md:block">
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold text-slate-500">
                <th class="py-3 px-4">วันที่สำรวจ</th>
                <th class="py-3 px-4">ชื่อหมู่บ้าน</th>
                <th class="py-3 px-4">หมู่ที่</th>
                <th class="py-3 px-4">ตำบล</th>
                <th class="py-3 px-4 text-center">หลังคาเรือน</th>
                <th class="py-3 px-4 text-center">ภาชนะ</th>
                <th class="py-3 px-4 text-center">สถานที่อื่นๆ (พบ/สำรวจ)</th>
                <th class="py-3 px-4 text-center">การจัดการ</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 text-xs font-semibold text-slate-700">
              <tr v-for="item in filteredSurveys" :key="item.id" class="hover:bg-slate-50/50 transition-colors">
                <td class="py-3.5 px-4 text-slate-500 flex items-center space-x-1.5">
                  <Clock class="w-3.5 h-3.5 text-slate-400" />
                  <span>{{ formatDate(item.created_at) }}</span>
                </td>
                <td class="py-3.5 px-4 font-bold text-slate-800">บ้าน{{ item.villageName }}</td>
                <td class="py-3.5 px-4">หมู่ {{ item.moo }}</td>
                <td class="py-3.5 px-4 text-slate-500">ต.{{ item.subDistrict }}</td>
                <td class="py-3.5 px-4 text-center">
                  <div class="flex flex-col items-center">
                    <div class="flex items-center gap-1">
                      <Home class="w-3.5 h-3.5 text-slate-400" />
                      <span class="text-[10px] text-slate-400 font-semibold">บ้าน:</span>
                      <span class="text-slate-900 font-extrabold text-base">{{ item.households_surveyed }}:{{ item.households_positive }}</span>
                    </div>
                    <span class="text-[10px] font-semibold mt-0.5" :class="getRiskTextClass(item.hi)">
                      {{ item.hi }}%
                    </span>
                  </div>
                </td>
                <td class="py-3.5 px-4 text-center">
                  <div class="flex flex-col items-center">
                    <div class="flex items-center gap-1">
                      <Activity class="w-3.5 h-3.5 text-slate-400" />
                      <span class="text-[10px] text-slate-400 font-semibold">ภาชนะ:</span>
                      <span class="text-slate-900 font-extrabold text-base">{{ item.containers_surveyed }}:{{ item.containers_positive }}</span>
                    </div>
                    <span class="text-[10px] font-semibold mt-0.5" :class="getRiskTextClass(item.ci)">
                      {{ item.ci }}%
                    </span>
                  </div>
                </td>
                <td class="py-3.5 px-4 text-center">
                  <div class="flex justify-center gap-1.5 flex-wrap max-w-xs mx-auto">
                    <!-- School indicators -->
                    <span v-if="item.school_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-violet-50 text-violet-700 text-[10px] font-bold border border-violet-100">
                      รร: {{ item.school_containers_positive }}/{{ item.school_containers_surveyed }}
                    </span>
                    <!-- Hosp indicators -->
                    <span v-if="item.hospital_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[10px] font-bold border border-emerald-100">
                      รพ: {{ item.hospital_containers_positive }}/{{ item.hospital_containers_surveyed }}
                    </span>
                    <!-- Factory indicators -->
                    <span v-if="item.factory_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-pink-50 text-pink-700 text-[10px] font-bold border border-pink-100">
                      รง: {{ item.factory_containers_positive }}/{{ item.factory_containers_surveyed }}
                    </span>
                    <!-- Gov indicators -->
                    <span v-if="item.public_office_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-sky-50 text-sky-700 text-[10px] font-bold border border-sky-100">
                      ราชการ: {{ item.public_office_containers_positive }}/{{ item.public_office_containers_surveyed }}
                    </span>
                  </div>
                </td>
                <td class="py-3.5 px-4 text-center">
                  <div class="flex justify-center items-center gap-1">
                    <button 
                      @click="editSurvey(item.id)" 
                      class="p-1.5 hover:bg-slate-100 text-slate-500 hover:text-slate-700 rounded-lg transition-colors cursor-pointer"
                      title="แก้ไขข้อมูล"
                    >
                      <Pencil class="w-4 h-4" />
                    </button>
                    <button 
                      @click="confirmDelete(item.id)" 
                      class="p-1.5 hover:bg-rose-50 text-rose-500 hover:text-rose-700 rounded-lg transition-colors cursor-pointer"
                      title="ลบข้อมูล"
                    >
                      <Trash2 class="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredSurveys.length === 0">
                <td colspan="8" class="text-center py-8 text-slate-400 font-medium">ไม่พบรายการข้อมูลประวัติการตรวจในระบุ</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Mobile List view (Card-based layout) -->
      <div class="grid grid-cols-1 gap-4 md:hidden">
        <div 
          v-for="item in filteredSurveys" 
          :key="item.id"
          class="bg-white border border-slate-200 p-4 rounded-2xl shadow-sm space-y-3"
        >
          <div class="flex justify-between items-start">
            <div>
              <h4 class="font-bold text-slate-800">บ้าน{{ item.villageName }} หมู่ที่ {{ item.moo }}</h4>
              <p class="text-[10px] text-slate-400 flex items-center space-x-1 mt-0.5">
                <Calendar class="w-3 h-3" />
                <span>{{ formatDate(item.created_at) }}</span>
                <span>•</span>
                <span>ต.{{ item.subDistrict }}</span>
              </p>
            </div>
            <div class="flex items-center gap-1">
              <button 
                @click="editSurvey(item.id)" 
                class="p-1.5 bg-slate-50 hover:bg-slate-100 text-slate-500 rounded-lg transition-colors"
                title="แก้ไขข้อมูล"
              >
                <Pencil class="w-4 h-4" />
              </button>
              <button 
                @click="confirmDelete(item.id)" 
                class="p-1.5 bg-rose-50 text-rose-500 rounded-lg hover:bg-rose-100 transition-colors"
                title="ลบข้อมูล"
              >
                <Trash2 class="w-4 h-4" />
              </button>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-2 text-center py-2 border-t border-b border-slate-100">
            <div class="flex flex-col items-center">
              <div class="flex items-center gap-1">
                <Home class="w-3.5 h-3.5 text-slate-400" />
                <span class="text-[10px] text-slate-400 font-semibold">บ้าน:</span>
                <span class="text-slate-900 font-extrabold text-base">{{ item.households_surveyed }}:{{ item.households_positive }}</span>
              </div>
              <span class="text-[10px] font-bold mt-0.5" :class="getRiskTextClass(item.hi)">
                {{ item.hi }}%
              </span>
            </div>
            <div class="flex flex-col items-center">
              <div class="flex items-center gap-1">
                <Activity class="w-3.5 h-3.5 text-slate-400" />
                <span class="text-[10px] text-slate-400 font-semibold">ภาชนะ:</span>
                <span class="text-slate-900 font-extrabold text-base">{{ item.containers_surveyed }}:{{ item.containers_positive }}</span>
              </div>
              <span class="text-[10px] font-bold mt-0.5" :class="getRiskTextClass(item.ci)">
                {{ item.ci }}%
              </span>
            </div>
          </div>

          <!-- Places badges -->
          <div class="flex flex-wrap gap-1.5">
            <span v-if="item.school_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-violet-50 text-violet-700 text-[9px] font-bold border border-violet-100">
              โรงเรียน: {{ item.school_containers_positive }}/{{ item.school_containers_surveyed }}
            </span>
            <span v-if="item.hospital_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[9px] font-bold border border-emerald-100">
              โรงพยาบาล: {{ item.hospital_containers_positive }}/{{ item.hospital_containers_surveyed }}
            </span>
            <span v-if="item.factory_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-pink-50 text-pink-700 text-[9px] font-bold border border-pink-100">
              โรงงาน: {{ item.factory_containers_positive }}/{{ item.factory_containers_surveyed }}
            </span>
            <span v-if="item.public_office_containers_surveyed > 0" class="px-1.5 py-0.5 rounded bg-sky-50 text-sky-700 text-[9px] font-bold border border-sky-100">
              ราชการ: {{ item.public_office_containers_positive }}/{{ item.public_office_containers_surveyed }}
            </span>
          </div>
        </div>
        
        <div v-if="filteredSurveys.length === 0" class="text-center py-8 text-slate-400 font-medium">
          ไม่พบรายการข้อมูลประวัติการตรวจในระบบ
        </div>
      </div>

    </div>
  </div>
</template>
