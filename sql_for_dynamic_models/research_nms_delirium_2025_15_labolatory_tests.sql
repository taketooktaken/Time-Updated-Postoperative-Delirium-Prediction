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
                            `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
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
            timestamp_trunc(time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
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
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            {{ max_by_ignore_nulls("lab.wbc", "lab.time") }} as wbc,
            {{ max_by_ignore_nulls("lab.hemoglobin", "lab.time") }} as hemoglobin,
            {{ max_by_ignore_nulls("lab.platelet", "lab.time") }} as platelet,
            {{ max_by_ignore_nulls("lab.sodium", "lab.time") }} as sodium,
            {{ max_by_ignore_nulls("lab.creatinine", "lab.time") }} as creatinine,
            {{ max_by_ignore_nulls("lab.potassium", "lab.time") }} as potassium,
            {{ max_by_ignore_nulls("lab.aspartate_aminotransferase", "lab.time") }}
            as aspartate_aminotransferase,
            {{ max_by_ignore_nulls("lab.blood_urea_nitrogen", "lab.time") }}
            as blood_urea_nitrogen,
            {{ max_by_ignore_nulls("lab.alanine_aminotransferase", "lab.time") }}
            as alanine_aminotransferase,
            {{ max_by_ignore_nulls("lab.total_bilirubin", "lab.time") }}
            as total_bilirubin,
            {{ max_by_ignore_nulls("lab.crp", "lab.time") }} as crp,
            {{ max_by_ignore_nulls("lab.albumin", "lab.time") }} as albumin
        from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly`
        left join calculate_start_time lab using (icu_stay_id, start_time)
        group by icu_stay_id, time_window_index, start_time, end_time
    )

select *
from join_laboratory_tests
