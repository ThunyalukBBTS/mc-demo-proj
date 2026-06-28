# Data object design

## Villages table

The village information of the Khon Kaen Province be in the `./khonkaen.json` file that it from [DOPA](https://catalog.dopa.go.th/dataset/gis-01/resource/6111a95f-a947-48a6-97fa-70019fdd45b0) please focus on **Mancha Khiri** district only. Have fields:

- ID UUID
- village name
- moo (village no.)
- sub-district
- district
- province
- postcode

## (VHV) Village Health Volunteers table/ users table

- UUID
- name
- email
- role

## VHV at village table

- VHV UUID
- Village table

## การสำรวจและกำจัดลูกน้ำยุงลาย รายหมู่บ้าน

- UUID
- ข้อมูลหมู่บ้าน (link to Village list ID)
- หมู่บ้าน/ชุมชน
    - จำนวนหลังคาเรือน: จำนวนที่สำรวจ, จำนวนที่พบ
    - HI: จำนวนหลังคาเรือน: จำนวนที่พบ/จำนวนที่สำรวจ\*100
    - จำนวนภาชนะ: จำนวนที่สำรวจ, จำนวนที่พบ
    - CI: จำนวนภาชนะ: จำนวนที่พบ/จำนวนที่สำรวจ\*100
- โรงเรียน
    - จำนวนภาชนะ: จำนวนที่สำรวจ, จำนวนที่พบ
- โรงพยาบาล
    - จำนวนภาชนะ: จำนวนที่สำรวจ, จำนวนที่พบ
- โรงงาน
    - จำนวนภาชนะ: จำนวนที่สำรวจ, จำนวนที่พบ
- สภานที่ราชการ
    - จำนวนภาชนะ: จำนวนที่สำรวจ, จำนวนที่พบ
- created_by (link VHV)
- created_date
- updated_by (link VHV)
- updated_date
