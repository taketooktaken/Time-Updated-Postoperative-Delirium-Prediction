with
    extract_gcs as (
        select
            icu_stay_id,
            time,
            timestamp_trunc(time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            gcs_e,
            gcs_v,
            gcs_m
        from `medicu-beta.latest_one_icu.gcs`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
            )
    ),

    join_gcs as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            {{ max_by_ignore_nulls("gcs.gcs_e", "gcs.time") }} as gcs_e,
            {{ max_by_ignore_nulls("gcs.gcs_v", "gcs.time") }} as gcs_v,
            {{ max_by_ignore_nulls("gcs.gcs_m", "gcs.time") }} as gcs_m
        from
            `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` time_windows
        left join extract_gcs as gcs using (icu_stay_id, start_time)
        group by icu_stay_id, time_window_index, start_time, end_time
    )

select *
from join_gcs
