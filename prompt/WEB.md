# VHV - Village mosquito larvae survey
This website use Thai language. Most users use Mobile first, and computer. Now, authentication not included (implement later).

## Pages
every page has nav bar
- `/` dashboard: has ui chart, trend graph, villages report table, filter (be in the Use case scenario section)
- daily village mosquito larvae survey report input (based-on surveys table)
    - select date (default today)
    - auto complete search หมู่บ้าน, หมู่ที่, ตำบล
    - fiels for หมู่บ้าน/ชุมชน number input (show CI,HI calculated percentage)
    - flels for โรงเรียน/โรงพยาบาล/โรงงาน/สภานที่ราชการ selection yes/no then show the fields input number
- table page (like legacy website that show records) for officer to view data old layout that has filter day,week, month, year and for sub-districts.

## Tools
- Vue.js
- Bun.js package manager
- Tailwindcss
- Typescript
- Shadcn
- Supabase client

## Roles
- district hospital officer/public health officer
- VHV sub-district
- VHV for each village

## Use case scenario
- VHV for each village can easily input Village mosquito larvae survey in that day.
- Everyone can view dashboard / page to view overview Village mosquito larvae survey report scope day,week,month and can filter (multiple select)