with
    pivot_laboratory_tests as (
        select *
        from
            (
                select icu_stay_id, time, field_name, value
                from `medicu-beta.latest_one_icu.laboratory_tests_blood`
                where
                    field_name in (
                        'wbc',
                        'hemoglobin',
                        'platelet',
                        'sodium',
                        'creatinine',
                        'potassium',
                        'aspartate_aminotransferase',
                        'blood_urea_nitrogen',
                        'alanine_aminotransferase',
                        'total_bilirubin',
                        'crp',
                        'albumin'
                    )
                    and icu_stay_id in (
                        select icu_stay_id
                        from
                            `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
                    )
            ) pivot (
                max(value) for field_name in (
                    'wbc',
                    'hemoglobin',
                    'platelet',
                    'sodium',
                    'creatinine',
                    'potassium',
                    'aspartate_aminotransferase',
                    'blood_urea_nitrogen',
                    'alanine_aminotransferase',
                    'total_bilirubin',
                    'crp',
                    'albumin'
                )
            )
    ),
    calculate_start_time as (
        select
            pivot.icu_stay_id,
            time,
            time as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            wbc,
            hemoglobin,
            platelet,
            sodium,
            creatinine,
            potassium,
            aspartate_aminotransferase,
            blood_urea_nitrogen,
            alanine_aminotransferase,
            total_bilirubin,
            crp,
            albumin
        from pivot_laboratory_tests as pivot
    ),

    join_laboratory_tests as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            percentile_cont(lab.wbc, 0.5) over icu_stay_hourly as wbc,
            percentile_cont(lab.hemoglobin, 0.5) over icu_stay_hourly as hemoglobin,
            percentile_cont(lab.platelet, 0.5) over icu_stay_hourly as platelet,
            percentile_cont(lab.sodium, 0.5) over icu_stay_hourly as sodium,
            percentile_cont(lab.creatinine, 0.5) over icu_stay_hourly as creatinine,
            percentile_cont(lab.potassium, 0.5) over icu_stay_hourly as potassium,
            percentile_cont(lab.aspartate_aminotransferase, 0.5) over icu_stay_hourly
                as aspartate_aminotransferase,
            percentile_cont(lab.blood_urea_nitrogen, 0.5) over icu_stay_hourly
                as blood_urea_nitrogen,
            percentile_cont(lab.alanine_aminotransferase, 0.5) over icu_stay_hourly
                as alanine_aminotransferase,
            percentile_cont(lab.total_bilirubin, 0.5) over icu_stay_hourly
                as total_bilirubin,
            percentile_cont(lab.crp, 0.5) over icu_stay_hourly as crp,
            percentile_cont(lab.albumin, 0.5) over icu_stay_hourly as albumin
        from `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join calculate_start_time lab 
                on time_windows.icu_stay_id = lab.icu_stay_id
                    and time_windows.end_time > lab.start_time
                    and time_windows.start_time <= lab.start_time
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_windows.time_window_index)

    )

select *
from join_laboratory_tests
group by icu_stay_id, time_window_index, start_time, end_time, wbc, hemoglobin, platelet, sodium, creatinine, potassium, aspartate_aminotransferase, blood_urea_nitrogen, alanine_aminotransferase, total_bilirubin, crp, albumin