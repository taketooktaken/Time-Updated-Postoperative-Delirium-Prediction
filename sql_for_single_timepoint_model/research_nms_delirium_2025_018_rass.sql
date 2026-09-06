with
    extract_rass as (
        select
            icu_stay_id,
            time,
            time as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            rass_score
        from `medicu-beta.latest_one_icu.rass`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),

    join_rass as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            -- 1 time_windowに複数レコードある場合は中央値を取る
            percentile_cont(rass_score, 0.5) over icu_stay_hourly as rass_score
        from
            `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join extract_rass r 
                on time_windows.icu_stay_id = r.icu_stay_id
                    and time_windows.end_time > r.start_time
                    and time_windows.start_time <= r.start_time
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_windows.time_window_index)
    )

select *
from join_rass
group by icu_stay_id, time_window_index, start_time, end_time, rass_score