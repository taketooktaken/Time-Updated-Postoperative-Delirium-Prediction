with
    extract_rass as (
        select
            icu_stay_id,
            time,
            timestamp_trunc(time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            rass_score
        from `medicu-beta.latest_one_icu.rass`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
            )
    ),

    join_rass as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
            -- 1 time_windowに複数レコードある場合は中央値を取る
            {{ percentile("rass_score", 0.5) }} as rass_score
        from
            `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` time_windows
        left join extract_rass r using (icu_stay_id, start_time)
        group by icu_stay_id, time_window_index, start_time, end_time
    )

select *
from join_rass
