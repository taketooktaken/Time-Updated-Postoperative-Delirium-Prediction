with
    extract_gcs as (
        select
            icu_stay_id,
            time,
            time as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            gcs_e,
            gcs_v,
            gcs_m
        from `medicu-beta.latest_one_icu.gcs`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),

    join_gcs as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            percentile_cont(gcs.gcs_e, 0.5) over icu_stay_hourly as gcs_e,
            percentile_cont(gcs.gcs_v, 0.5) over icu_stay_hourly as gcs_v,
            percentile_cont(gcs.gcs_m, 0.5) over icu_stay_hourly as gcs_m,
        from
            `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join extract_gcs as gcs 
                on time_windows.icu_stay_id = gcs.icu_stay_id
                    and time_windows.end_time > gcs.start_time
                    and time_windows.start_time <= gcs.start_time
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_windows.time_window_index)
    )

select *
from join_gcs
group by icu_stay_id, time_window_index, start_time, end_time, gcs_e, gcs_v, gcs_m
