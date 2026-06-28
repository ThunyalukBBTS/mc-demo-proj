import json
import uuid
import os

def generate_seed():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(script_dir, 'khonkaen.json')
    seed_path = os.path.abspath(os.path.join(script_dir, '../../supabase/seeding/seed.sql'))
    
    print(f"Reading data from {json_path}...")
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Filter for Mancha Khiri
    mancha_records = [item for item in data if item.get('aname') == 'มัญจาคีรี']
    print(f"Found {len(mancha_records)} records for มัญจาคีรี.")
    
    sql_lines = [
        "-- Seed villages for Mancha Khiri district\n",
        "INSERT INTO public.villages (id, name, moo, sub_district, district, province, postcode) VALUES\n"
    ]
    
    values = []
    for item in mancha_records:
        name = item.get('mname', '').strip()
        sub_district = item.get('tname', '').strip()
        district = item.get('aname', '').strip()
        province = item.get('pname', '').strip()
        postcode = '40160' # Mancha Khiri postcode
        
        mcode = item.get('mcode', '')
        try:
            moo = int(mcode[-2:])
        except (ValueError, TypeError):
            moo = 0
            
        # Generate stable UUID
        dns_namespace = uuid.NAMESPACE_DNS
        name_string = f"{province}-{district}-{sub_district}-{moo}-{name}"
        stable_id = str(uuid.uuid5(dns_namespace, name_string))
        
        # Escape single quotes for SQL safety
        escaped_name = name.replace("'", "''")
        escaped_sub_district = sub_district.replace("'", "''")
        escaped_district = district.replace("'", "''")
        escaped_province = province.replace("'", "''")
        
        values.append(
            f"('{stable_id}', '{escaped_name}', {moo}, '{escaped_sub_district}', '{escaped_district}', '{escaped_province}', '{postcode}')"
        )
        
    # Join insert statements with comma and add on conflict ignore/update
    sql_lines.append(",\n".join(values))
    sql_lines.append("\nON CONFLICT (name, moo, sub_district, district, province) DO UPDATE SET\n")
    sql_lines.append("  postcode = EXCLUDED.postcode,\n")
    sql_lines.append("  updated_at = now();\n")
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(seed_path), exist_ok=True)
    
    print(f"Writing to {seed_path}...")
    with open(seed_path, 'w', encoding='utf-8') as f:
        f.writelines(sql_lines)
    print("Seeding script generated successfully.")

if __name__ == '__main__':
    generate_seed()
