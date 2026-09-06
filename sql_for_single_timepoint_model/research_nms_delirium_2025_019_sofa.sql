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
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),

    join_sofa as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            percentile_cont(s.respiration_24hours, 0.5) over icu_stay_hourly as respiration_24hours,
            percentile_cont(s.coagulation_24hours, 0.5) over icu_stay_hourly as coagulation_24hours,
            percentile_cont(s.liver_24hours, 0.5) over icu_stay_hourly as liver_24hours,
            percentile_cont(s.cardiovascular_24hours, 0.5) over icu_stay_hourly as cardiovascular_24hours,
            percentile_cont(s.cns_24hours, 0.5) over icu_stay_hourly as cns_24hours,
            percentile_cont(s.renal_24hours, 0.5) over icu_stay_hourly as renal_24hours,
            percentile_cont(s.sofa_24hours, 0.5) over icu_stay_hourly as sofa_24hours
        from
            `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join extract_sofa s
                on time_windows.icu_stay_id = s.icu_stay_id
                    and time_windows.end_time > s.start_time
                    and time_windows.start_time <= s.start_time
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_windows.time_window_index)
    )

select *
from join_sofa
group by icu_stay_id, time_window_index, start_time, end_time, respiration_24hours, coagulation_24hours,liver_24hours,cardiovascular_24hours,cns_24hours,renal_24hours,sofa_24hours