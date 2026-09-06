with
    extract_blood_gas as (
        -- arterial_blood_gas
        select
            pivot.icu_stay_id,
            pivot.time,
            timestamp_trunc(pivot.time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
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
                            `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
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
            timestamp_trunc(pivot.time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
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
                            `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
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
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            {{ max_by_ignore_nulls("bg.ph", "bg.time") }} as ph,
            {{ max_by_ignore_nulls("bg.pao2", "bg.time") }} as pao2,
            {{ max_by_ignore_nulls("bg.pvo2", "bg.time") }} as pvo2,
            {{ max_by_ignore_nulls("bg.paco2", "bg.time") }} as paco2,
            {{ max_by_ignore_nulls("bg.pvco2", "bg.time") }} as pvco2,
            {{ max_by_ignore_nulls("bg.lactate", "bg.time") }} as bg_lactate,
            {{ max_by_ignore_nulls("bg.glucose", "bg.time") }} as bg_glucose,
        from
            `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` time_windows
        left join extract_blood_gas as bg using (icu_stay_id, start_time)
        group by icu_stay_id, time_window_index, start_time, end_time
    )

select *
from join_blood_gas
