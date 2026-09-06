with
    extract_body_weight as (
        select
            icu_stay_id,
            time,
            timestamp_trunc(time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            body_weight
        from `medicu-beta.latest_one_icu.body_weight_measurements`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
            )
    ),

    join_body_weight as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            {{ max_by_ignore_nulls("wei.body_weight", "wei.time") }} as body_weight
        from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly`
        left join extract_body_weight wei using (icu_stay_id, start_time)
        group by icu_stay_id, time_window_index, start_time, end_time
    )

select *
from join_body_weight
