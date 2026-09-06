with
    extract_vital_measurements as (
        select
            icu_stay_id,
            time,
            timestamp_trunc(time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
            coalesce(vs.bt_core, vs.bt_surface) as bt,
            hr,
            rr,
            coalesce(invasive_sbp, non_invasive_sbp) as sbp,
            coalesce(invasive_mbp, non_invasive_mbp) as mbp,
            coalesce(invasive_dbp, non_invasive_dbp) as dbp,
            spo2,
            case when invasive_sbp is not null then 1 else 0 end as bp_invasive,  -- invasiveな測定があったかどうかのインジケータ
        from `medicu-beta.latest_one_icu.vital_measurements` as vs
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
            )
    ),

    join_vital_measurements as (
        select distinct
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            -- bt medianのみ
            -- btは測定回数が少ないので中央値のみを使用することになった
            percentile_cont(bt, 0.5) over icu_stay_hourly as bt50,
            -- hr
            percentile_cont(hr, 0.1) over icu_stay_hourly as hr10,
            percentile_cont(hr, 0.5) over icu_stay_hourly as hr50,
            percentile_cont(hr, 0.9) over icu_stay_hourly as hr90,
            stddev(hr) over icu_stay_hourly as hr_sd,
            -- rr
            percentile_cont(rr, 0.1) over icu_stay_hourly as rr10,
            percentile_cont(rr, 0.5) over icu_stay_hourly as rr50,
            percentile_cont(rr, 0.9) over icu_stay_hourly as rr90,
            stddev(rr) over icu_stay_hourly as rr_sd,
            -- sbp
            percentile_cont(sbp, 0.1) over icu_stay_hourly as sbp10,
            percentile_cont(sbp, 0.5) over icu_stay_hourly as sbp50,
            percentile_cont(sbp, 0.9) over icu_stay_hourly as sbp90,
            stddev(sbp) over icu_stay_hourly as sbp_sd,
            -- mbp
            percentile_cont(mbp, 0.1) over icu_stay_hourly as mbp10,
            percentile_cont(mbp, 0.5) over icu_stay_hourly as mbp50,
            percentile_cont(mbp, 0.9) over icu_stay_hourly as mbp90,
            stddev(mbp) over icu_stay_hourly as mbp_sd,
            -- dbp
            percentile_cont(dbp, 0.1) over icu_stay_hourly as dbp10,
            percentile_cont(dbp, 0.5) over icu_stay_hourly as dbp50,
            percentile_cont(dbp, 0.9) over icu_stay_hourly as dbp90,
            stddev(dbp) over icu_stay_hourly as dbp_sd,
            -- spo2
            percentile_cont(spo2, 0.1) over icu_stay_hourly as spo2_10,
            percentile_cont(spo2, 0.5) over icu_stay_hourly as spo2_50,
            percentile_cont(spo2, 0.9) over icu_stay_hourly as spo2_90,
            stddev(spo2) over icu_stay_hourly as spo2_sd,
            -- bp_invasive
            max(bp_invasive) over icu_stay_hourly as bp_invasive
        from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly`
        left join extract_vital_measurements using (icu_stay_id, start_time)
        window icu_stay_hourly as (partition by icu_stay_id, time_window_index)
    )

select *
from join_vital_measurements
