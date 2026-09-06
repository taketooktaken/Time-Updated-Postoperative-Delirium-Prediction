with
    extract_sofa as (
        select
            icu_stay_id,
            start_time,  
            respiration_24hours,
            coagulation_24hours,
            liver_24hours,
            cardiovascular_24hours,
            cns_24hours,
            renal_24hours,
            sofa_24hours
        from `medicu-beta.latest_one_icu_derived.sofa_hourly`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
            )
    ),

    join_sofa as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            s.respiration_24hours,
            s.coagulation_24hours,
            s.liver_24hours,
            s.cardiovascular_24hours,
            s.cns_24hours,
            s.renal_24hours,
            s.sofa_24hours
        from
            `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` time_windows
        left join extract_sofa s using (icu_stay_id, start_time)
    )

select *
from join_sofa
