<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabaseClient'
import { 
  TrendingUp, 
  Search, 
  Users, 
  AlertTriangle,
  RotateCw
} from 'lucide-vue-next'
import { Line, Bar } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

// Data states
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
const selectedPeriod = ref('30') // '7' | '30' | '90' | 'all'
const searchQuery = ref('')

// Load data from Supabase
const fetchData = async () => {
  loading.value = true
  errorMsg.value = ''
  try {
    const { data: villagesData, error: vError } = await supabase
      .from('villages')
      .select('*')
      .is('deleted_at', null)

    if (vError) throw vError
    villages.value = villagesData || []

    const { data: surveysData, error: sError } = await supabase
      .from('surveys')
      .select('*')
      .is('deleted_at', null)
      .order('created_at', { ascending: true })

    if (sError) throw sError
    surveys.value = surveysData || []
  } catch (err: any) {
    console.error('Error fetching data:', err)
    errorMsg.value = 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้ กรุณาตรวจสอบการตั้งค่า Supabase ของคุณ'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchData()
})

// Unique Tambons for filter dropdown
const tambonsList = computed(() => {
  const list = new Set(villages.value.map(v => v.sub_district))
  return ['ทั้งหมด', ...Array.from(list).sort()]
})

// Filtered surveys based on Tambon, Date Period
const filteredSurveys = computed(() => {
  let list = surveys.value

  // Period filter
  if (selectedPeriod.value !== 'all') {
    const cutoffDate = new Date()
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(selectedPeriod.value))
    list = list.filter(s => new Date(s.created_at) >= cutoffDate)
  }

  // Tambon filter
  if (selectedTambon.value !== 'ทั้งหมด') {
    const tambonVillageIds = villages.value
      .filter(v => v.sub_district === selectedTambon.value)
      .map(v => v.id)
    list = list.filter(s => tambonVillageIds.includes(s.village_id))
  }

  return list
})

// Core metrics computations
const metrics = computed(() => {
  const list = filteredSurveys.value
  if (list.length === 0) return { avgHI: 0, avgCI: 0, totalHouses: 0, totalPositiveHouses: 0, totalContainers: 0, totalPositiveContainers: 0 }

  const totalHouses = list.reduce((sum, s) => sum + s.households_surveyed, 0)
  const totalPositiveHouses = list.reduce((sum, s) => sum + s.households_positive, 0)
  const avgHI = totalHouses > 0 ? (totalPositiveHouses / totalHouses) * 100 : 0

  const totalContainers = list.reduce((sum, s) => sum + s.containers_surveyed, 0)
  const totalPositiveContainers = list.reduce((sum, s) => sum + s.containers_positive, 0)
  const avgCI = totalContainers > 0 ? (totalPositiveContainers / totalContainers) * 100 : 0

  return {
    avgHI: parseFloat(avgHI.toFixed(2)),
    avgCI: parseFloat(avgCI.toFixed(2)),
    totalHouses,
    totalPositiveHouses,
    totalContainers,
    totalPositiveContainers
  }
})

// Report coverage status computed property
const reportCoverage = computed(() => {
  const totalVillages = villages.value.length
  if (totalVillages === 0) return { count: 0, total: 0, percent: 0 }

  const surveyVillageIds = new Set(filteredSurveys.value.map(s => s.village_id))
  const count = surveyVillageIds.size
  const percent = parseFloat(((count / totalVillages) * 100).toFixed(2))

  return {
    count,
    total: totalVillages,
    percent
  }
})

// Village list with combined data for display table
const villageSummary = computed(() => {
  return villages.value
    .map(v => {
      // Find all surveys for this village in the selected period
      const villageSurveys = filteredSurveys.value.filter(s => s.village_id === v.id)
      
      if (villageSurveys.length === 0) {
        return {
          ...v,
          surveyCount: 0,
          hi: null,
          ci: null,
          housesSurveyed: 0,
          housesPositive: 0,
          containersSurveyed: 0,
          containersPositive: 0
        }
      }

      // Aggregate data
      const housesSurveyed = villageSurveys.reduce((sum, s) => sum + s.households_surveyed, 0)
      const housesPositive = villageSurveys.reduce((sum, s) => sum + s.households_positive, 0)
      const containersSurveyed = villageSurveys.reduce((sum, s) => sum + s.containers_surveyed, 0)
      const containersPositive = villageSurveys.reduce((sum, s) => sum + s.containers_positive, 0)

      return {
        ...v,
        surveyCount: villageSurveys.length,
        hi: housesSurveyed > 0 ? parseFloat(((housesPositive / housesSurveyed) * 100).toFixed(2)) : 0,
        ci: containersSurveyed > 0 ? parseFloat(((containersPositive / containersSurveyed) * 100).toFixed(2)) : 0,
        housesSurveyed,
        housesPositive,
        containersSurveyed,
        containersPositive
      }
    })
    .filter(v => {
      // Apply search query (search village name, moo, or sub-district)
      const query = searchQuery.value.trim().toLowerCase()
      if (!query) return true
      return (
        v.name.toLowerCase().includes(query) ||
        v.moo.toString().includes(query) ||
        v.sub_district.toLowerCase().includes(query)
      )
    })
    .sort((a, b) => {
      // Show villages with highest HI first (critical ones)
      return (b.hi || 0) - (a.hi || 0)
    })
})

// Trend Chart (HI vs CI)
const trendChartData = computed(() => {
  // Group surveys by date (formatted as DD/MM) and get average indices
  const list = filteredSurveys.value
  const groups: { [key: string]: { hiSum: number, ciSum: number, count: number } } = {}

  list.forEach(s => {
    const date = new Date(s.created_at)
    const label = `${date.getDate()} ${date.toLocaleString('th-TH', { month: 'short' })}`
    if (!groups[label]) {
      groups[label] = { hiSum: 0, ciSum: 0, count: 0 }
    }
    groups[label].hiSum += s.hi
    groups[label].ciSum += s.ci
    groups[label].count += 1
  })

  const labels = Object.keys(groups)
  const hiData = labels.map(l => parseFloat((groups[l].hiSum / groups[l].count).toFixed(2)))
  const ciData = labels.map(l => parseFloat((groups[l].ciSum / groups[l].count).toFixed(2)))

  return {
    labels,
    datasets: [
      {
        label: 'ดัชนีบ้าน (HI %)',
        borderColor: '#f43f5e', // rose-500
        backgroundColor: 'rgba(244, 63, 94, 0.1)',
        data: hiData,
        tension: 0.3,
        fill: true
      },
      {
        label: 'ดัชนีภาชนะ (CI %)',
        borderColor: '#0ea5e9', // sky-500
        backgroundColor: 'rgba(14, 165, 233, 0.1)',
        data: ciData,
        tension: 0.3,
        fill: true
      }
    ]
  }
})

// Place type positivity Rates Comparison Chart
const placeChartData = computed(() => {
  const list = filteredSurveys.value
  let commSurv = 0, commPos = 0
  let schoolSurv = 0, schoolPos = 0
  let hospSurv = 0, hospPos = 0
  let factSurv = 0, factPos = 0
  let govSurv = 0, govPos = 0

  list.forEach(s => {
    commSurv += s.containers_surveyed
    commPos += s.containers_positive
    schoolSurv += s.school_containers_surveyed
    schoolPos += s.school_containers_positive
    hospSurv += s.hospital_containers_surveyed
    hospPos += s.hospital_containers_positive
    factSurv += s.factory_containers_surveyed
    factPos += s.factory_containers_positive
    govSurv += s.public_office_containers_surveyed
    govPos += s.public_office_containers_positive
  })

  const data = [
    commSurv > 0 ? parseFloat(((commPos / commSurv) * 100).toFixed(2)) : 0,
    schoolSurv > 0 ? parseFloat(((schoolPos / schoolSurv) * 100).toFixed(2)) : 0,
    hospSurv > 0 ? parseFloat(((hospPos / hospSurv) * 100).toFixed(2)) : 0,
    factSurv > 0 ? parseFloat(((factPos / factSurv) * 100).toFixed(2)) : 0,
    govSurv > 0 ? parseFloat(((govPos / govSurv) * 100).toFixed(2)) : 0,
  ]

  return {
    labels: ['หมู่บ้าน/ชุมชน', 'โรงเรียน', 'โรงพยาบาล', 'โรงงาน', 'สถานที่ราชการ'],
    datasets: [
      {
        label: 'อัตราพบลูกน้ำ (CI %)',
        backgroundColor: [
          '#0ea5e9', // sky-500
          '#eab308', // yellow-500
          '#10b981', // emerald-500
          '#ec4899', // pink-500
          '#8b5cf6'  // purple-500
        ],
        borderRadius: 6,
        data: data
      }
    ]
  }
})

// Utility styling functions for HI / CI risk levels
const getRiskBadgeClass = (val: number | null) => {
  if (val === null) return 'bg-slate-100 text-slate-400'
  if (val === 0) return 'bg-emerald-50 text-emerald-700 border-emerald-200'
  if (val < 10) return 'bg-emerald-50 text-emerald-700 border-emerald-200'
  if (val < 20) return 'bg-yellow-50 text-yellow-700 border-yellow-200'
  return 'bg-rose-50 text-rose-700 border-rose-200'
}
</script>

<template>
  <div class="space-y-6">
    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center min-h-[50vh] space-y-4">
      <div class="animate-spin rounded-full h-12 w-12 border-4 border-emerald-500 border-t-transparent"></div>
      <p class="text-slate-500 font-medium animate-pulse">กำลังโหลดข้อมูลระบบสำรวจ...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="errorMsg" class="bg-rose-50 border border-rose-200 rounded-2xl p-6 text-center space-y-4 max-w-lg mx-auto">
      <div class="flex justify-center text-rose-500">
        <AlertTriangle class="w-16 h-16" />
      </div>
      <h3 class="text-lg font-bold text-slate-800">เกิดข้อผิดพลาดในการโหลดข้อมูล</h3>
      <p class="text-sm text-slate-600 leading-relaxed">{{ errorMsg }}</p>
      <button 
        @click="fetchData" 
        class="inline-flex items-center space-x-2 bg-rose-600 hover:bg-rose-700 text-white font-medium px-4 py-2.5 rounded-xl transition-all duration-150"
      >
        <RotateCw class="w-4 h-4" />
        <span>ลองใหม่อีกครั้ง</span>
      </button>
    </div>

    <!-- Dashboard Content -->
    <div v-else class="space-y-6">
      <!-- Title & Filters Section -->
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h2 class="text-xl font-extrabold text-slate-800">ข้อมูลสรุปและสถานการณ์ลูกน้ำยุงลาย</h2>
          <p class="text-xs text-slate-500">อำเภอมัญจาคีรี จังหวัดขอนแก่น</p>
        </div>
        
        <!-- Filter Controls -->
        <div class="flex flex-wrap items-center gap-3">
          <!-- Tambon Filter -->
          <div class="flex flex-col">
            <span class="text-[10px] text-slate-400 font-bold mb-1">ตำบล</span>
            <select 
              v-model="selectedTambon"
              class="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer"
            >
              <option v-for="t in tambonsList" :key="t" :value="t">{{ t }}</option>
            </select>
          </div>

          <!-- Time Period Filter -->
          <div class="flex flex-col">
            <span class="text-[10px] text-slate-400 font-bold mb-1">ช่วงเวลา</span>
            <select 
              v-model="selectedPeriod"
              class="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 cursor-pointer"
            >
              <option value="7">7 วันที่ผ่านมา</option>
              <option value="30">30 วันที่ผ่านมา</option>
              <option value="90">3 เดือนที่ผ่านมา</option>
              <option value="all">ทั้งหมด</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Overview KPI Cards in Shadcn style -->
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
        <!-- Main Surveillance Targets Card (3 cols) -->
        <div class="lg:col-span-3 bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-6">
          <div>
            <h3 class="text-base font-extrabold text-slate-900">เป้าหมายการเฝ้าระวังลูกน้ำยุงลาย (Surveillance Targets)</h3>
            <p class="text-xs text-slate-500 mt-1">สรุปสถานการณ์ดัชนีบ้าน (HI), ดัชนีภาชนะ (CI) และสัดส่วนพื้นที่การรายงานข้อมูล</p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <!-- House Index (HI) Sub-Card -->
            <div class="bg-slate-50/80 border border-slate-100 p-5 rounded-2xl space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-[10px] font-bold tracking-wider text-slate-400 uppercase">HOUSE INDEX (HI)</span>
                <span class="text-[10px] px-2 py-0.5 rounded-full font-bold border bg-white" :class="getRiskBadgeClass(metrics.avgHI)">
                  {{ metrics.avgHI < 10 ? 'ปลอดภัย' : metrics.avgHI < 20 ? 'ปานกลาง' : 'อันตราย' }}
                </span>
              </div>
              <h4 class="text-3xl font-extrabold text-slate-900 mt-2">{{ metrics.avgHI }}%</h4>
              <!-- Progress Bar -->
              <div class="h-2 w-full bg-slate-200/60 rounded-full mt-3 overflow-hidden">
                <div 
                  class="h-full rounded-full transition-all duration-300 animate-pulse"
                  :class="metrics.avgHI < 10 ? 'bg-emerald-500' : metrics.avgHI < 20 ? 'bg-yellow-500' : 'bg-rose-500'"
                  :style="{ width: Math.min(metrics.avgHI, 100) + '%' }"
                ></div>
              </div>
              <!-- Bottom Row -->
              <div class="flex justify-between items-center text-xs pt-1.5 text-slate-500">
                <span>พบลูกน้ำ: <strong class="text-slate-800 font-bold">{{ metrics.totalPositiveHouses }} หลัง</strong></span>
                <span>สำรวจทั้งหมด: <strong class="text-slate-800 font-bold">{{ metrics.totalHouses }} หลัง</strong></span>
              </div>
            </div>

            <!-- Container Index (CI) Sub-Card -->
            <div class="bg-slate-50/80 border border-slate-100 p-5 rounded-2xl space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-[10px] font-bold tracking-wider text-slate-400 uppercase">CONTAINER INDEX (CI)</span>
                <span class="text-[10px] px-2 py-0.5 rounded-full font-bold border bg-white" :class="getRiskBadgeClass(metrics.avgCI)">
                  {{ metrics.avgCI < 10 ? 'ปลอดภัย' : metrics.avgCI < 20 ? 'ปานกลาง' : 'อันตราย' }}
                </span>
              </div>
              <h4 class="text-3xl font-extrabold text-slate-900 mt-2">{{ metrics.avgCI }}%</h4>
              <!-- Progress Bar -->
              <div class="h-2 w-full bg-slate-200/60 rounded-full mt-3 overflow-hidden">
                <div 
                  class="h-full rounded-full transition-all duration-300 animate-pulse"
                  :class="metrics.avgCI < 10 ? 'bg-emerald-500' : metrics.avgCI < 20 ? 'bg-yellow-500' : 'bg-rose-500'"
                  :style="{ width: Math.min(metrics.avgCI, 100) + '%' }"
                ></div>
              </div>
              <!-- Bottom Row -->
              <div class="flex justify-between items-center text-xs pt-1.5 text-slate-500">
                <span>พบลูกน้ำ: <strong class="text-slate-800 font-bold">{{ metrics.totalPositiveContainers }} ใบ</strong></span>
                <span>สำรวจทั้งหมด: <strong class="text-slate-800 font-bold">{{ metrics.totalContainers }} ใบ</strong></span>
              </div>
            </div>

            <!-- Village Coverage (Report Coverage) Sub-Card -->
            <div class="bg-slate-50/80 border border-slate-100 p-5 rounded-2xl space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-[10px] font-bold tracking-wider text-slate-400 uppercase">REPORT COVERAGE</span>
                <span class="text-[10px] px-2 py-0.5 rounded-full font-bold border bg-white" 
                  :class="reportCoverage.percent >= 80 ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : reportCoverage.percent >= 50 ? 'bg-yellow-50 text-yellow-700 border-yellow-200' : 'bg-rose-50 text-rose-700 border-rose-200'"
                >
                  {{ reportCoverage.percent >= 80 ? 'ดีเยี่ยม' : reportCoverage.percent >= 50 ? 'ปานกลาง' : 'ปรับปรุง' }}
                </span>
              </div>
              <h4 class="text-3xl font-extrabold text-slate-900 mt-2">{{ reportCoverage.percent }}%</h4>
              <!-- Progress Bar -->
              <div class="h-2 w-full bg-slate-200/60 rounded-full mt-3 overflow-hidden">
                <div 
                  class="h-full rounded-full transition-all duration-300 animate-pulse"
                  :class="reportCoverage.percent >= 80 ? 'bg-emerald-500' : reportCoverage.percent >= 50 ? 'bg-yellow-500' : 'bg-rose-500'"
                  :style="{ width: Math.min(reportCoverage.percent, 100) + '%' }"
                ></div>
              </div>
              <!-- Bottom Row -->
              <div class="flex justify-between items-center text-xs pt-1.5 text-slate-500">
                <span>รายงานแล้ว: <strong class="text-slate-800 font-bold">{{ reportCoverage.count }} หมู่บ้าน</strong></span>
                <span>ทั้งหมด: <strong class="text-slate-800 font-bold">{{ reportCoverage.total }} หมู่บ้าน</strong></span>
              </div>
            </div>
          </div>
        </div>

        <!-- Secondary Info Cards (1 col) -->
        <div class="flex flex-col gap-4">
          <!-- Total Surveyed Card -->
          <div class="bg-white p-5 rounded-3xl border border-slate-200 shadow-sm flex flex-col justify-center flex-1">
            <div class="flex items-center space-x-3.5">
              <div class="p-3 rounded-2xl bg-emerald-50 text-emerald-500 flex items-center justify-center">
                <Users class="w-6 h-6" />
              </div>
              <div>
                <p class="text-xs text-slate-400 font-bold">จำนวนบ้านที่สำรวจแล้ว</p>
                <h3 class="text-2xl font-extrabold text-slate-800 mt-1">{{ metrics.totalHouses }} หลัง</h3>
                <p class="text-[10px] text-slate-400 mt-1">พบลูกน้ำสะสม: {{ metrics.totalPositiveHouses }} หลัง</p>
              </div>
            </div>
          </div>

          <!-- Total Reports Card -->
          <div class="bg-white p-5 rounded-3xl border border-slate-200 shadow-sm flex flex-col justify-center flex-1">
            <div class="flex items-center space-x-3.5">
              <div class="p-3 rounded-2xl bg-violet-50 text-violet-500 flex items-center justify-center">
                <TrendingUp class="w-6 h-6" />
              </div>
              <div>
                <p class="text-xs text-slate-400 font-bold">รายงานส่งแล้วทั้งหมด</p>
                <h3 class="text-2xl font-extrabold text-slate-800 mt-1">{{ filteredSurveys.length }} ฉบับ</h3>
                <p class="text-[10px] text-slate-400 mt-1">จากข้อมูลที่คัดกรองตามตัวเลือก</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Charts Section -->
      <div v-if="filteredSurveys.length > 0" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Line Chart: HI vs CI Trend -->
        <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div>
            <h3 class="text-sm font-bold text-slate-800">แนวโน้มค่าดัชนี HI และ CI</h3>
            <p class="text-xs text-slate-400 font-medium">เปรียบเทียบดัชนีบ้านและดัชนีภาชนะตามช่วงเวลา</p>
          </div>
          <div class="h-64 flex items-center justify-center">
            <Line 
              :data="trendChartData" 
              :options="{ 
                responsive: true, 
                maintainAspectRatio: false,
                scales: { y: { min: 0, max: 100 } }
              }" 
            />
          </div>
        </div>

        <!-- Bar Chart: Place Types Comparison -->
        <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div>
            <h3 class="text-sm font-bold text-slate-800">อัตราการพบลูกน้ำจำแนกตามประเภทสถานที่</h3>
            <p class="text-xs text-slate-400 font-medium">ร้อยละของภาชนะที่พบลูกน้ำยุงลาย (CI %)</p>
          </div>
          <div class="h-64 flex items-center justify-center">
            <Bar 
              :data="placeChartData" 
              :options="{ 
                responsive: true, 
                maintainAspectRatio: false,
                scales: { y: { min: 0 } }
              }" 
            />
          </div>
        </div>
      </div>

      <div v-else class="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm text-center">
        <p class="text-slate-400 text-sm font-medium">ไม่พบข้อมูลการสำรวจในเงื่อนไขการกรองนี้</p>
      </div>

      <!-- Table Summary Section -->
      <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden space-y-4 p-5">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h3 class="text-sm font-bold text-slate-800">สรุปรายงานดัชนีลูกน้ำยุงลายรายหมู่บ้าน</h3>
            <p class="text-xs text-slate-400 font-medium">แสดงสถานการณ์ความเสี่ยง (เรียงตามลำดับดัชนี HI สูงสุด)</p>
          </div>
          <!-- Search box -->
          <div class="relative max-w-xs w-full">
            <Search class="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input 
              v-model="searchQuery"
              type="text" 
              placeholder="ค้นหาหมู่บ้าน/หมู่ที่/ตำบล..."
              class="w-full bg-slate-50 border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </div>
        </div>

        <!-- Table view (Desktop) -->
        <div class="overflow-x-auto border border-slate-100 rounded-xl hidden md:block">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-slate-50 border-b border-slate-100 text-xs font-bold text-slate-500">
                <th class="py-3 px-4">หมู่บ้าน/ชุมชน</th>
                <th class="py-3 px-4">หมู่ที่</th>
                <th class="py-3 px-4">ตำบล</th>
                <th class="py-3 px-4 text-center">จำนวนการสำรวจ</th>
                <th class="py-3 px-4 text-center">ดัชนีบ้าน (HI %)</th>
                <th class="py-3 px-4 text-center">ดัชนีภาชนะ (CI %)</th>
                <th class="py-3 px-4 text-center">หลังคาเรือน</th>
                <th class="py-3 px-4 text-center">ภาชนะ</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 text-xs font-semibold text-slate-700">
              <tr v-for="item in villageSummary" :key="item.id" class="hover:bg-slate-50 transition-colors">
                <td class="py-3.5 px-4 font-bold text-slate-800">บ้าน{{ item.name }}</td>
                <td class="py-3.5 px-4">หมู่ {{ item.moo }}</td>
                <td class="py-3.5 px-4 text-slate-500">ต.{{ item.sub_district }}</td>
                <td class="py-3.5 px-4 text-center">{{ item.surveyCount }} ครั้ง</td>
                <td class="py-3.5 px-4 text-center">
                  <span 
                    class="px-2.5 py-1 rounded-full border text-[11px] font-bold"
                    :class="getRiskBadgeClass(item.hi)"
                  >
                    {{ item.hi !== null ? item.hi + '%' : 'ไม่มีข้อมูล' }}
                  </span>
                </td>
                <td class="py-3.5 px-4 text-center">
                  <span 
                    class="px-2.5 py-1 rounded-full border text-[11px] font-bold"
                    :class="getRiskBadgeClass(item.ci)"
                  >
                    {{ item.ci !== null ? item.ci + '%' : 'ไม่มีข้อมูล' }}
                  </span>
                </td>
                <td class="py-3.5 px-4 text-center text-slate-500 text-[11px]">
                  สำรวจ:พบ <span class="text-slate-900 font-bold text-sm ml-1">{{ item.housesSurveyed }}:{{ item.housesPositive }}</span>
                </td>
                <td class="py-3.5 px-4 text-center text-slate-500 text-[11px]">
                  สำรวจ:พบ <span class="text-slate-900 font-bold text-sm ml-1">{{ item.containersSurveyed }}:{{ item.containersPositive }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Cards view (Mobile-friendly) -->
        <div class="grid grid-cols-1 gap-4 md:hidden">
          <div 
            v-for="item in villageSummary" 
            :key="item.id" 
            class="bg-slate-50 border border-slate-100 p-4 rounded-xl space-y-3"
          >
            <div class="flex justify-between items-start">
              <div>
                <h4 class="font-bold text-slate-800 text-sm">บ้าน{{ item.name }}</h4>
                <p class="text-[10px] text-slate-500">หมู่ที่ {{ item.moo }} ต.{{ item.sub_district }}</p>
              </div>
              <span class="text-[10px] bg-slate-200 text-slate-600 px-2 py-0.5 rounded font-bold">
                สำรวจ {{ item.surveyCount }} ครั้ง
              </span>
            </div>
            
            <div class="grid grid-cols-2 gap-2 text-center pt-1">
              <div class="bg-white border border-slate-100 p-2 rounded-lg">
                <span class="text-[9px] text-slate-400 block mb-1">ดัชนีบ้าน (HI)</span>
                <span class="text-xs font-bold px-2 py-0.5 rounded-full border inline-block" :class="getRiskBadgeClass(item.hi)">
                  {{ item.hi !== null ? item.hi + '%' : '-' }}
                </span>
                <span v-if="item.housesSurveyed > 0" class="text-[10px] text-slate-500 block mt-1">
                  สำรวจ:พบ <span class="text-slate-900 font-bold text-xs ml-0.5">{{ item.housesSurveyed }}:{{ item.housesPositive }}</span>
                </span>
              </div>
              <div class="bg-white border border-slate-100 p-2 rounded-lg">
                <span class="text-[9px] text-slate-400 block mb-1">ดัชนีภาชนะ (CI)</span>
                <span class="text-xs font-bold px-2 py-0.5 rounded-full border inline-block" :class="getRiskBadgeClass(item.ci)">
                  {{ item.ci !== null ? item.ci + '%' : '-' }}
                </span>
                <span v-if="item.containersSurveyed > 0" class="text-[10px] text-slate-500 block mt-1">
                  สำรวจ:พบ <span class="text-slate-900 font-bold text-xs ml-0.5">{{ item.containersSurveyed }}:{{ item.containersPositive }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
