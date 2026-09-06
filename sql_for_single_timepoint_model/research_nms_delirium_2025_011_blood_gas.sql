with
    extract_blood_gas as (
        -- arterial_blood_gas
        select
            pivot.icu_stay_id,
            pivot.time,
            pivot.time as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            pivot.ph,
            pivot.po2 as pao2,
            null as pvo2,
            pivot.pco2 as paco2,
            null as pvco2,
            pivot.lactate,
            pivot.glucose
        from
            (
                select icu_stay_id, time, field_name, value
                from `medicu-beta.latest_one_icu.blood_gas`
                where
                    field_name in (
                        'ph',
                        'po2',
                        'pco2',
                        'lactate',
                        'glucose'
                    )
                    and sample_type = 'arterial_blood_gas'
                    and icu_stay_id in (
                        select icu_stay_id
                        from
                            `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
                    )
            ) pivot (
                any_value(value) for field_name in (
                        'ph',
                        'po2',
                        'pco2',
                        'lactate',
                        'glucose'
                )
            ) as pivot

        union all
        -- venous_blood_gas
        select
            pivot.icu_stay_id,
            pivot.time,
            pivot.time as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            pivot.ph,
            null as pao2,
            pivot.po2 as pvo2,
            null as paco2,
            pivot.pco2 as pvco2,
            pivot.lactate,
            pivot.glucose,
        from
            (
                select icu_stay_id, time, field_name, value
                from `medicu-beta.latest_one_icu.blood_gas`
                where
                    field_name in (
                        'ph',
                        'po2',
                        'pco2',
                        'lactate',
                        'glucose'
                    )
                    and sample_type = 'venous_blood_gas'
                    and icu_stay_id in (
                        select icu_stay_id
                        from
                            `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
                    )
            ) pivot (
                any_value(value) for field_name in (
                    'ph',
                    'po2',
                    'pco2',
                    'lactate',
                    'glucose'
                )
            ) as pivot
    ),

    join_blood_gas as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            percentile_cont(bg.ph, 0.5) over icu_stay_hourly as ph,
            percentile_cont(bg.pao2, 0.5) over icu_stay_hourly as pao2,
            percentile_cont(bg.pvo2, 0.5) over icu_stay_hourly as pvo2,
            percentile_cont(bg.paco2, 0.5) over icu_stay_hourly as paco2,
            percentile_cont(bg.pvco2, 0.5) over icu_stay_hourly as pvco2,
            percentile_cont(bg.lactate, 0.5) over icu_stay_hourly as bg_lactate,
            percentile_cont(bg.glucose, 0.5) over icu_stay_hourly as bg_glucose,
        from
            -- 入室後24hのデータを用いて、アウトカムを予測するモデルの場合↓
            `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join extract_blood_gas as bg
                on time_windows.icu_stay_id = bg.icu_stay_id
                    and time_windows.end_time > bg.start_time
                    and time_windows.start_time <= bg.start_time
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_window_index)
    )

select *
from join_blood_gas
group by icu_stay_id, time_window_index, start_time, end_time, ph, pao2, pvo2, paco2, pvco2, bg_lactate, bg_glucose
