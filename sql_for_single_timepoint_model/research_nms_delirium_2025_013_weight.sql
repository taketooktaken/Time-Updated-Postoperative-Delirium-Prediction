with
    extract_body_weight as (
        select
            icu_stay_id,
            time,
            time as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            body_weight
        from `medicu-beta.latest_one_icu.body_weight_measurements`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),

    join_body_weight as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            percentile_cont(wei.body_weight, 0.5) over icu_stay_hourly as body_weight,
        from `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join extract_body_weight wei 
                on time_windows.icu_stay_id = wei.icu_stay_id
                    and time_windows.end_time > wei.start_time
                    and time_windows.start_time <= wei.start_time
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_windows.time_window_index)
    )

select *
from join_body_weight
group by icu_stay_id, time_window_index, start_time, end_time, body_weight

