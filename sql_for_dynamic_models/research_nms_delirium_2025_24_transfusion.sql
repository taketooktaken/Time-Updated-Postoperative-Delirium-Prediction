with transfusion_records as (
  select
    b.icu_stay_id,
    b.start_time,
    b.end_time,
    b.ml_per_hour,
    case
     when t.blood_product_name in ('rbc', 'autologous_blood_map', 'autologous_blood_cpda', 'ftrc', 'wrc')
     then 'rbc'
     when t.blood_product_name in ('pc', 'pc_15_units', 'pc_20_units', 'pc_hla_10_units', 'pc_hla_15_units', 'pc_hla_20_units', 'wpc_10_units', 'wpc_hla_10_units')
     then 'platelet'
     when t.blood_product_name in ('ffp')
     then 'plasma'
     when t.blood_product_name in ('human_serum_albumin_5_percent', 'human_serum_albumin_20_percent', 'human_serum_albumin_25_percent')
     then 'albumin'
    end as blood_product_name
  from `medicu-beta.latest_one_icu.blood_transfusions` b
  left join `medicu-beta.latest_one_icu.blood_transfusion_components` t
    using (blood_transfusion_id)
  where blood_product_name in (
    -- rbc
    'rbc', 
    'autologous_blood_map',
    'autologous_blood_cpda',
    'ftrc',
    'wrc',
    -- platelet
    'pc', 
    'pc_15_units',
   	'pc_20_units',
    'pc_hla_10_units',
    'pc_hla_15_units',
    'pc_hla_20_units',
    'wpc_10_units',
    'wpc_hla_10_units',
    -- plasma
    'ffp', 
    -- albumin
    'human_serum_albumin_5_percent',
    'human_serum_albumin_20_percent',
    'human_serum_albumin_25_percent'
    )
    and icu_stay_id in (
      select icu_stay_id
      from `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
    )
),

match_transfusion_in_time_window as (
  select
    tw.icu_stay_id,
    tw.time_window_index,
    tw.start_time as time_window_start_time,
    tw.end_time as time_window_end_time,
    tr.start_time as transfusion_start_time,
    tr.end_time as transfusion_end_time,
    tr.blood_product_name,
    tr.ml_per_hour
  from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` tw
  left join transfusion_records tr
    on tw.icu_stay_id = tr.icu_stay_id
   and tw.end_time > tr.start_time
   and tw.start_time <= tr.end_time
),

calculate_transfusion_duration as (
  select
    icu_stay_id,
    time_window_index,
    time_window_start_time as start_time,
    time_window_end_time as end_time,
    greatest(time_window_start_time, transfusion_start_time) as duration_start_time,
    least(time_window_end_time, transfusion_end_time) as duration_end_time,
    blood_product_name,
    ml_per_hour
  from match_transfusion_in_time_window
),

calculate_transfusion as (
  select
    icu_stay_id,
    time_window_index,
    start_time,
    end_time,
    blood_product_name,
    ml_per_hour,
    ml_per_hour
      * cast(timestamp_diff(duration_end_time, duration_start_time, minute) as int64)
      / 60 as input_transfusion -- time window内でのinput
  from calculate_transfusion_duration
),

pivot_transfusion as (
  select *
  from (
    select
      icu_stay_id,
      time_window_index,
      start_time,
      end_time,
      blood_product_name,
      input_transfusion
    from calculate_transfusion
  )
  pivot (
    sum(input_transfusion) for blood_product_name in (
    'rbc',
    'platelet',
    'plasma',
    'albumin'
    )
  )
),

rename_columns as (
  select
    icu_stay_id,
    time_window_index,
    start_time,
    end_time,
    coalesce(rbc, 0) as transfusion_rbc,
    coalesce(platelet, 0) as transfusion_platelet,
    coalesce(plasma, 0) as transfusion_plasma,
    coalesce(albumin, 0) as transfusion_albumin
  from pivot_transfusion
)

select *
from rename_columns