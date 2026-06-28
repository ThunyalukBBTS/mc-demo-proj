<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabaseClient'
import { 
  MapPin, 
  Calendar, 
  CheckCircle, 
  AlertCircle, 
  School, 
  Plus, 
  Activity, 
  Building2, 
  ArrowLeft,
  Trash2,
  Home
} from 'lucide-vue-next'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()
const editId = ref<string | null>(null)

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

const villages = ref<Village[]>([])
const loading = ref(true)
const submitting = ref(false)
const statusMsg = ref({ type: '', text: '' })

// Form fields
const surveyDate = ref(new Date().toISOString().substring(0, 10))

// Village Search & Autocomplete
const searchInput = ref('')
const selectedVillage = ref<Village | null>(null)
const showDropdown = ref(false)

// Households/Community
const householdsSurveyed = ref<number | null>(null)
const householdsPositive = ref<number | null>(null)
const containersSurveyed = ref<number | null>(null)
const containersPositive = ref<number | null>(null)

// Extra locations toggles and fields
const hasSchool = ref(false)
const schoolContainersSurveyed = ref<number | null>(null)
const schoolContainersPositive = ref<number | null>(null)

const hasHospital = ref(false)
const hospitalContainersSurveyed = ref<number | null>(null)
const hospitalContainersPositive = ref<number | null>(null)

const hasFactory = ref(false)
const factoryContainersSurveyed = ref<number | null>(null)
const factoryContainersPositive = ref<number | null>(null)

const hasPublicOffice = ref(false)
const publicOfficeContainersSurveyed = ref<number | null>(null)
const publicOfficeContainersPositive = ref<number | null>(null)

// Load villages for autocomplete
onMounted(async () => {
  try {
    const { data, error } = await supabase
      .from('villages')
      .select('*')
      .is('deleted_at', null)
      .order('sub_district')
      .order('moo')
      
    if (error) throw error
    villages.value = data || []

    if (route.query.id) {
      editId.value = route.query.id as string
      const { data: surveyData, error: sError } = await supabase
        .from('surveys')
        .select('*')
        .eq('id', editId.value)
        .single()
        
      if (sError) throw sError
      if (surveyData) {
        surveyDate.value = new Date(surveyData.created_at).toISOString().substring(0, 10)
        
        const v = villages.value.find(x => x.id === surveyData.village_id)
        if (v) {
          selectVillage(v)
        }

        householdsSurveyed.value = surveyData.households_surveyed
        householdsPositive.value = surveyData.households_positive
        containersSurveyed.value = surveyData.containers_surveyed
        containersPositive.value = surveyData.containers_positive

        hasSchool.value = surveyData.school_containers_surveyed > 0
        schoolContainersSurveyed.value = surveyData.school_containers_surveyed || null
        schoolContainersPositive.value = surveyData.school_containers_positive || null

        hasHospital.value = surveyData.hospital_containers_surveyed > 0
        hospitalContainersSurveyed.value = surveyData.hospital_containers_surveyed || null
        hospitalContainersPositive.value = surveyData.hospital_containers_positive || null

        hasFactory.value = surveyData.factory_containers_surveyed > 0
        factoryContainersSurveyed.value = surveyData.factory_containers_surveyed || null
        factoryContainersPositive.value = surveyData.factory_containers_positive || null

        hasPublicOffice.value = surveyData.public_office_containers_surveyed > 0
        publicOfficeContainersSurveyed.value = surveyData.public_office_containers_surveyed || null
        publicOfficeContainersPositive.value = surveyData.public_office_containers_positive || null
      }
    }
  } catch (err) {
    console.error('Error loading villages:', err)
  } finally {
    loading.value = false
  }
})

// Autocomplete suggestions
const suggestions = computed(() => {
  const query = searchInput.value.trim().toLowerCase()
  if (!query || selectedVillage.value) return []
  
  // Split query by comma to allow searching by parts, e.g. "ป่า, 5" or "ป่า, 5, เมือง"
  const queryParts = query.split(',').map(part => part.trim()).filter(Boolean)
  if (queryParts.length === 0) return []
  
  return villages.value.filter(v => {
    // Every query part must match at least one of name, moo, or sub_district
    return queryParts.every(part => 
      v.name.toLowerCase().includes(part) ||
      v.moo.toString().includes(part) ||
      v.sub_district.toLowerCase().includes(part)
    )
  }).slice(0, 30)
})

const selectVillage = (v: Village) => {
  selectedVillage.value = v
  searchInput.value = `บ้าน${v.name}, หมู่ที่ ${v.moo}, ต.${v.sub_district}`
  showDropdown.value = false
}

const clearVillage = () => {
  selectedVillage.value = null
  searchInput.value = ''
}

// Live HI & CI computations
const calculatedHI = computed(() => {
  const surv = householdsSurveyed.value || 0
  const pos = householdsPositive.value || 0
  if (surv <= 0) return 0
  return parseFloat(((pos / surv) * 100).toFixed(2))
})

const calculatedCI = computed(() => {
  const surv = containersSurveyed.value || 0
  const pos = containersPositive.value || 0
  if (surv <= 0) return 0
  return parseFloat(((pos / surv) * 100).toFixed(2))
})

const calculatedSchoolCI = computed(() => {
  const surv = schoolContainersSurveyed.value || 0
  const pos = schoolContainersPositive.value || 0
  if (surv <= 0) return 0
  return parseFloat(((pos / surv) * 100).toFixed(2))
})

const calculatedHospitalCI = computed(() => {
  const surv = hospitalContainersSurveyed.value || 0
  const pos = hospitalContainersPositive.value || 0
  if (surv <= 0) return 0
  return parseFloat(((pos / surv) * 100).toFixed(2))
})

const calculatedFactoryCI = computed(() => {
  const surv = factoryContainersSurveyed.value || 0
  const pos = factoryContainersPositive.value || 0
  if (surv <= 0) return 0
  return parseFloat(((pos / surv) * 100).toFixed(2))
})

const calculatedPublicOfficeCI = computed(() => {
  const surv = publicOfficeContainersSurveyed.value || 0
  const pos = publicOfficeContainersPositive.value || 0
  if (surv <= 0) return 0
  return parseFloat(((pos / surv) * 100).toFixed(2))
})

// Validation
const isFormValid = computed(() => {
  if (!selectedVillage.value) return false
  if (!surveyDate.value) return false
  
  // Community fields validation
  const hhSurv = householdsSurveyed.value ?? 0
  const hhPos = householdsPositive.value ?? 0
  const contSurv = containersSurveyed.value ?? 0
  const contPos = containersPositive.value ?? 0
  
  if (hhSurv <= 0 || hhPos < 0 || hhPos > hhSurv) return false
  if (contSurv <= 0 || contPos < 0 || contPos > contSurv) return false
  
  // Additional place validation
  if (hasSchool.value) {
    const scSurv = schoolContainersSurveyed.value ?? 0
    const scPos = schoolContainersPositive.value ?? 0
    if (scSurv <= 0 || scPos < 0 || scPos > scSurv) return false
  }
  if (hasHospital.value) {
    const hsSurv = hospitalContainersSurveyed.value ?? 0
    const hsPos = hospitalContainersPositive.value ?? 0
    if (hsSurv <= 0 || hsPos < 0 || hsPos > hsSurv) return false
  }
  if (hasFactory.value) {
    const fcSurv = factoryContainersSurveyed.value ?? 0
    const fcPos = factoryContainersPositive.value ?? 0
    if (fcSurv <= 0 || fcPos < 0 || fcPos > fcSurv) return false
  }
  if (hasPublicOffice.value) {
    const pbSurv = publicOfficeContainersSurveyed.value ?? 0
    const pbPos = publicOfficeContainersPositive.value ?? 0
    if (pbSurv <= 0 || pbPos < 0 || pbPos > pbSurv) return false
  }
  
  return true
})

// Submit form
const submitSurvey = async () => {
  if (!isFormValid.value || !selectedVillage.value) return
  
  submitting.value = true
  statusMsg.value = { type: '', text: '' }
  
  try {
    const payload = {
      village_id: selectedVillage.value.id,
      households_surveyed: householdsSurveyed.value,
      households_positive: householdsPositive.value,
      containers_surveyed: containersSurveyed.value,
      containers_positive: containersPositive.value,
      
      school_containers_surveyed: hasSchool.value ? schoolContainersSurveyed.value : 0,
      school_containers_positive: hasSchool.value ? schoolContainersPositive.value : 0,
      
      hospital_containers_surveyed: hasHospital.value ? hospitalContainersSurveyed.value : 0,
      hospital_containers_positive: hasHospital.value ? hospitalContainersPositive.value : 0,
      
      factory_containers_surveyed: hasFactory.value ? factoryContainersSurveyed.value : 0,
      factory_containers_positive: hasFactory.value ? factoryContainersPositive.value : 0,
      
      public_office_containers_surveyed: hasPublicOffice.value ? publicOfficeContainersSurveyed.value : 0,
      public_office_containers_positive: hasPublicOffice.value ? publicOfficeContainersPositive.value : 0,
      
      created_at: new Date(surveyDate.value).toISOString(),
      updated_at: new Date().toISOString()
    }
    
    let error = null
    if (editId.value) {
      const { error: updateError } = await supabase
        .from('surveys')
        .update(payload)
        .eq('id', editId.value)
      error = updateError
    } else {
      const { error: insertError } = await supabase
        .from('surveys')
        .insert(payload)
      error = insertError
    }
      
    if (error) throw error
    
    statusMsg.value = { 
      type: 'success', 
      text: editId.value ? 'แก้ไขข้อมูลการสำรวจสำเร็จ!' : 'บันทึกข้อมูลการสำรวจสำเร็จ!' 
    }
    
    // Clear form after 2 seconds and redirect
    setTimeout(() => {
      resetForm()
      if (editId.value) {
        router.push('/history')
      } else {
        router.push('/')
      }
    }, 2000)
    
  } catch (err: any) {
    console.error('Error saving survey:', err)
    statusMsg.value = { type: 'error', text: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล กรุณาลองใหม่อีกครั้ง' }
  } finally {
    submitting.value = false
  }
}
const preventNonDigit = (event: KeyboardEvent) => {
  // Allow only digits 0-9
  if (!/[0-9]/.test(event.key)) {
    event.preventDefault()
  }
}

const resetForm = () => {
  clearVillage()
  householdsSurveyed.value = null
  householdsPositive.value = null
  containersSurveyed.value = null
  containersPositive.value = null
  
  hasSchool.value = false
  schoolContainersSurveyed.value = null
  schoolContainersPositive.value = null
  
  hasHospital.value = false
  hospitalContainersSurveyed.value = null
  hospitalContainersPositive.value = null
  
  hasFactory.value = false
  factoryContainersSurveyed.value = null
  factoryContainersPositive.value = null
  
  hasPublicOffice.value = false
  publicOfficeContainersSurveyed.value = null
  publicOfficeContainersPositive.value = null
  
  statusMsg.value = { type: '', text: '' }
}
</script>

<template>
  <div class="max-w-2xl mx-auto space-y-6">
    <!-- Back Button & Header -->
    <div class="flex items-center space-x-3">
      <button 
        @click="editId ? router.push('/history') : router.push('/')" 
        class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-600"
      >
        <ArrowLeft class="w-5 h-5" />
      </button>
      <div>
        <h2 class="text-xl font-extrabold text-slate-800">{{ editId ? 'แก้ไขรายงานสำรวจลูกน้ำยุงลาย' : 'บันทึกผลสำรวจลูกน้ำยุงลายรายวัน' }}</h2>
        <p class="text-xs text-slate-500">{{ editId ? 'แก้ไขข้อมูลการตรวจผลสำรวจในระบบ' : 'กรอกข้อมูลการตรวจผลสำรวจเพื่อวิเคราะห์ดัชนีความเสี่ยง' }}</p>
      </div>
    </div>

    <!-- Main Card -->
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-6">
      
      <!-- Status Toast -->
      <div 
        v-if="statusMsg.text" 
        class="p-4 rounded-xl border flex items-center space-x-3 text-sm font-semibold transition-all"
        :class="statusMsg.type === 'success' 
          ? 'bg-emerald-50 text-emerald-800 border-emerald-200' 
          : 'bg-rose-50 text-rose-800 border-rose-200'"
      >
        <CheckCircle v-if="statusMsg.type === 'success'" class="w-5 h-5 flex-shrink-0 text-emerald-600" />
        <AlertCircle v-else class="w-5 h-5 flex-shrink-0 text-rose-600" />
        <span>{{ statusMsg.text }}</span>
      </div>

      <!-- Date & Village Section -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Date Selection -->
        <div class="space-y-1.5">
          <label class="text-xs font-bold text-slate-600 flex items-center space-x-1">
            <Calendar class="w-3.5 h-3.5 text-slate-400" />
            <span>วันที่ทำการสำรวจ</span>
          </label>
          <input 
            v-model="surveyDate"
            type="date"
            class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500 text-slate-700"
          />
        </div>

        <!-- Village Search -->
        <div class="space-y-1.5 relative">
          <label class="text-xs font-bold text-slate-600 flex items-center space-x-1">
            <MapPin class="w-3.5 h-3.5 text-slate-400" />
            <span>เลือกหมู่บ้าน / ชุมชน</span>
          </label>
          <div class="relative">
            <input 
              v-model="searchInput"
              @focus="showDropdown = true"
              @input="showDropdown = true"
              type="text"
              placeholder="ค้นหาชื่อหมู่บ้านหรือตำบล..."
              :readonly="selectedVillage !== null"
              class="w-full border border-slate-200 rounded-xl pl-4 pr-10 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500 text-slate-700"
              :class="selectedVillage ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-slate-50'"
            />
            <!-- Clear button -->
            <button 
              v-if="selectedVillage" 
              @click="clearVillage" 
              class="absolute right-3 top-2 text-rose-500 hover:text-rose-700 p-1 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
              title="ล้างการเลือก"
            >
              <Trash2 class="w-4 h-4" />
            </button>
          </div>

          <!-- Suggestions Dropdown -->
          <div 
            v-if="showDropdown && suggestions.length > 0" 
            class="absolute top-[70px] left-0 right-0 bg-white border border-slate-200 rounded-xl shadow-lg z-50 max-h-60 overflow-y-auto divide-y divide-slate-100"
          >
            <div 
              v-for="v in suggestions" 
              :key="v.id"
              @click="selectVillage(v)"
              class="px-4 py-2.5 hover:bg-slate-50 cursor-pointer text-xs font-semibold text-slate-700 flex items-center space-x-1.5"
            >
              <span>บ้าน{{ v.name }}, หมู่ที่ {{ v.moo }}, ต.{{ v.sub_district }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Divider -->
      <hr class="border-slate-100" />

      <!-- Section: Households / Community -->
      <div class="space-y-4">
        <h3 class="text-sm font-bold text-slate-800 flex items-center space-x-2">
          <span class="w-1.5 h-4 bg-emerald-500 rounded-full"></span>
          <span>ข้อมูลบ้านเรือนและชุมชน (หลัก)</span>
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 bg-slate-50 p-4 rounded-2xl border border-slate-100">
          <!-- Houses Card -->
          <div class="space-y-3">
            <h4 class="text-xs font-bold text-slate-700 flex items-center space-x-1.5">
              <Home class="w-4 h-4 text-emerald-500" />
              <span>หลังคาเรือน</span>
            </h4>
            <div class="grid grid-cols-2 gap-3">
              <div class="space-y-1">
                <span class="text-[10px] text-slate-400 font-bold">สำรวจแล้ว (หลัง)</span>
                <input 
                  v-model.number="householdsSurveyed"
                  type="number"
                  min="0"
                  step="1"
                  @keypress="preventNonDigit"
                  placeholder="0"
                  class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
              <div class="space-y-1">
                <span class="text-[10px] text-slate-400 font-bold">พบลูกน้ำ (หลัง)</span>
                <input 
                  v-model.number="householdsPositive"
                  type="number"
                  min="0"
                  step="1"
                  @keypress="preventNonDigit"
                  placeholder="0"
                  class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            </div>
            <!-- Display calculated HI -->
            <div class="flex justify-between items-center bg-transparent py-1 text-xs">
              <span class="text-slate-500 font-medium">สัดส่วน (%) :</span>
              <span class="font-bold text-emerald-600 text-sm">{{ calculatedHI }}%</span>
            </div>
          </div>

          <!-- Containers Card -->
          <div class="space-y-3">
            <h4 class="text-xs font-bold text-slate-700 flex items-center space-x-1.5">
              <Activity class="w-4 h-4 text-sky-500" />
              <span>ภาชนะในชุมชน</span>
            </h4>
            <div class="grid grid-cols-2 gap-3">
              <div class="space-y-1">
                <span class="text-[10px] text-slate-400 font-bold">สำรวจแล้ว (ชิ้น)</span>
                <input 
                  v-model.number="containersSurveyed"
                  type="number"
                  min="0"
                  step="1"
                  @keypress="preventNonDigit"
                  placeholder="0"
                  class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
              <div class="space-y-1">
                <span class="text-[10px] text-slate-400 font-bold">พบลูกน้ำ (ชิ้น)</span>
                <input 
                  v-model.number="containersPositive"
                  type="number"
                  min="0"
                  step="1"
                  @keypress="preventNonDigit"
                  placeholder="0"
                  class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            </div>
            <!-- Display calculated CI -->
            <div class="flex justify-between items-center bg-transparent py-1 text-xs">
              <span class="text-slate-500 font-medium">สัดส่วน (%) :</span>
              <span class="font-bold text-sky-600 text-sm">{{ calculatedCI }}%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Divider -->
      <hr class="border-slate-100" />

      <!-- Section: Extra Locations -->
      <div class="space-y-4">
        <h3 class="text-sm font-bold text-slate-800 flex items-center space-x-2">
          <span class="w-1.5 h-4 bg-violet-500 rounded-full"></span>
          <span>ข้อมูลสถานที่สำคัญเพิ่มเติม</span>
        </h3>

        <!-- Toggle Grid -->
        <div class="grid grid-cols-2 gap-4">
          <!-- Toggle School -->
          <div 
            @click="hasSchool = !hasSchool"
            class="p-4 rounded-xl border cursor-pointer select-none transition-all flex items-center justify-between"
            :class="hasSchool ? 'bg-violet-50 border-violet-200 text-violet-700' : 'bg-slate-50 border-slate-100 text-slate-500'"
          >
            <div class="flex items-center space-x-2.5">
              <School class="w-4 h-4" />
              <span class="text-xs font-bold">โรงเรียน</span>
            </div>
            <div class="w-4 h-4 rounded-full border flex items-center justify-center bg-white border-slate-300">
              <span v-if="hasSchool" class="w-2.5 h-2.5 rounded-full bg-violet-600"></span>
            </div>
          </div>

          <!-- Toggle Hospital -->
          <div 
            @click="hasHospital = !hasHospital"
            class="p-4 rounded-xl border cursor-pointer select-none transition-all flex items-center justify-between"
            :class="hasHospital ? 'bg-emerald-50 border-emerald-200 text-emerald-700' : 'bg-slate-50 border-slate-100 text-slate-500'"
          >
            <div class="flex items-center space-x-2.5">
              <Activity class="w-4 h-4" />
              <span class="text-xs font-bold">โรงพยาบาล</span>
            </div>
            <div class="w-4 h-4 rounded-full border flex items-center justify-center bg-white border-slate-300">
              <span v-if="hasHospital" class="w-2.5 h-2.5 rounded-full bg-emerald-600"></span>
            </div>
          </div>

          <!-- Toggle Factory -->
          <div 
            @click="hasFactory = !hasFactory"
            class="p-4 rounded-xl border cursor-pointer select-none transition-all flex items-center justify-between"
            :class="hasFactory ? 'bg-pink-50 border-pink-200 text-pink-700' : 'bg-slate-50 border-slate-100 text-slate-500'"
          >
            <div class="flex items-center space-x-2.5">
              <Building2 class="w-4 h-4" />
              <span class="text-xs font-bold">โรงงาน</span>
            </div>
            <div class="w-4 h-4 rounded-full border flex items-center justify-center bg-white border-slate-300">
              <span v-if="hasFactory" class="w-2.5 h-2.5 rounded-full bg-pink-600"></span>
            </div>
          </div>

          <!-- Toggle Public Office -->
          <div 
            @click="hasPublicOffice = !hasPublicOffice"
            class="p-4 rounded-xl border cursor-pointer select-none transition-all flex items-center justify-between"
            :class="hasPublicOffice ? 'bg-sky-50 border-sky-200 text-sky-700' : 'bg-slate-50 border-slate-100 text-slate-500'"
          >
            <div class="flex items-center space-x-2.5">
              <Plus class="w-4 h-4" />
              <span class="text-xs font-bold">สถานที่ราชการ</span>
            </div>
            <div class="w-4 h-4 rounded-full border flex items-center justify-center bg-white border-slate-300">
              <span v-if="hasPublicOffice" class="w-2.5 h-2.5 rounded-full bg-sky-600"></span>
            </div>
          </div>
        </div>

        <!-- Conditional Fields Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- School Inputs -->
          <div v-if="hasSchool" class="p-4 rounded-2xl border border-violet-100 bg-violet-50/30 grid grid-cols-2 gap-3">
            <h4 class="col-span-2 text-xs font-bold text-violet-800 flex items-center space-x-2">
              <School class="w-4 h-4" />
              <span>สำรวจโรงเรียน</span>
            </h4>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">ภาชนะสำรวจ (ชิ้น)</span>
              <input 
                v-model.number="schoolContainersSurveyed"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-violet-500"
              />
            </div>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">พบลูกน้ำ (ชิ้น)</span>
              <input 
                v-model.number="schoolContainersPositive"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-violet-500"
              />
            </div>
            <!-- Display calculated CI -->
            <div class="col-span-2 flex justify-between items-center bg-transparent py-1 text-xs">
              <span class="text-slate-500 font-medium">สัดส่วน (%) :</span>
              <span class="font-bold text-violet-600 text-sm">{{ calculatedSchoolCI }}%</span>
            </div>
          </div>

          <!-- Hospital Inputs -->
          <div v-if="hasHospital" class="p-4 rounded-2xl border border-emerald-100 bg-emerald-50/30 grid grid-cols-2 gap-3">
            <h4 class="col-span-2 text-xs font-bold text-emerald-800 flex items-center space-x-2">
              <Activity class="w-4 h-4" />
              <span>สำรวจโรงพยาบาล / รพ.สต.</span>
            </h4>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">ภาชนะสำรวจ (ชิ้น)</span>
              <input 
                v-model.number="hospitalContainersSurveyed"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            </div>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">พบลูกน้ำ (ชิ้น)</span>
              <input 
                v-model.number="hospitalContainersPositive"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            </div>
            <!-- Display calculated CI -->
            <div class="col-span-2 flex justify-between items-center bg-transparent py-1 text-xs">
              <span class="text-slate-500 font-medium">สัดส่วน (%) :</span>
              <span class="font-bold text-emerald-600 text-sm">{{ calculatedHospitalCI }}%</span>
            </div>
          </div>

          <!-- Factory Inputs -->
          <div v-if="hasFactory" class="p-4 rounded-2xl border border-pink-100 bg-pink-50/30 grid grid-cols-2 gap-3">
            <h4 class="col-span-2 text-xs font-bold text-pink-800 flex items-center space-x-2">
              <Building2 class="w-4 h-4" />
              <span>สำรวจโรงงาน</span>
            </h4>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">ภาชนะสำรวจ (ชิ้น)</span>
              <input 
                v-model.number="factoryContainersSurveyed"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-pink-500"
              />
            </div>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">พบลูกน้ำ (ชิ้น)</span>
              <input 
                v-model.number="factoryContainersPositive"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-pink-500"
              />
            </div>
            <!-- Display calculated CI -->
            <div class="col-span-2 flex justify-between items-center bg-transparent py-1 text-xs">
              <span class="text-slate-500 font-medium">สัดส่วน (%) :</span>
              <span class="font-bold text-pink-600 text-sm">{{ calculatedFactoryCI }}%</span>
            </div>
          </div>

          <!-- Public Office Inputs -->
          <div v-if="hasPublicOffice" class="p-4 rounded-2xl border border-sky-100 bg-sky-50/30 grid grid-cols-2 gap-3">
            <h4 class="col-span-2 text-xs font-bold text-sky-800 flex items-center space-x-2">
              <Plus class="w-4 h-4" />
              <span>สำรวจสถานที่ราชการ</span>
            </h4>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">ภาชนะสำรวจ (ชิ้น)</span>
              <input 
                v-model.number="publicOfficeContainersSurveyed"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-sky-500"
              />
            </div>
            <div class="space-y-1">
              <span class="text-[10px] text-slate-400 font-bold">พบลูกน้ำ (ชิ้น)</span>
              <input 
                v-model.number="publicOfficeContainersPositive"
                type="number"
                min="0"
                step="1"
                @keypress="preventNonDigit"
                placeholder="0"
                class="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-sky-500"
              />
            </div>
            <!-- Display calculated CI -->
            <div class="col-span-2 flex justify-between items-center bg-transparent py-1 text-xs">
              <span class="text-slate-500 font-medium">สัดส่วน (%) :</span>
              <span class="font-bold text-sky-600 text-sm">{{ calculatedPublicOfficeCI }}%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex space-x-3 pt-4 border-t border-slate-100">
        <button 
          type="button" 
          @click="resetForm"
          class="flex-1 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold py-3 px-4 rounded-xl transition-all duration-150 text-xs"
        >
          ล้างฟอร์ม
        </button>
        <button 
          type="submit" 
          @click="submitSurvey"
          :disabled="!isFormValid || submitting"
          class="flex-[2] text-white font-semibold py-3 px-4 rounded-xl transition-all duration-150 text-xs shadow-md shadow-emerald-200 flex items-center justify-center space-x-2"
          :class="isFormValid && !submitting 
            ? 'bg-emerald-600 hover:bg-emerald-700 cursor-pointer' 
            : 'bg-slate-300 cursor-not-allowed'"
        >
          <span v-if="submitting" class="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2"></span>
          <span>{{ submitting ? 'กำลังบันทึกข้อมูล...' : (editId ? 'บันทึกการแก้ไข' : 'บันทึกรายงานสำรวจ') }}</span>
        </button>
      </div>

    </div>
  </div>
</template>
