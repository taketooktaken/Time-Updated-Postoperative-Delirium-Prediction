with
    extract_time_zero as (
      select icu_stay_id, start_time
      from `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours`
    ),
    extract_vital_measurements as (
        select
            icu_stay_id,
            time,
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
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),
    join_time_zero as (
        select
            vital.*,
            e.start_time,
            timestamp_diff(vital.time, e.start_time, DAY) as time_window_index
        from extract_vital_measurements vital
        left join extract_time_zero e using (icu_stay_id)
        where timestamp_diff(vital.time, e.start_time, DAY) = 0
    ),
    join_vital_measurements as (
        select
            time_windows.icu_stay_id,
            time_windows.time_window_index,
            time_windows.start_time,
            time_windows.end_time,
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
        from `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
        left join join_time_zero bg using (icu_stay_id, time_window_index)
        window icu_stay_hourly as (partition by time_windows.icu_stay_id, time_windows.time_window_index)
    )

select *
from join_vital_measurements
group by icu_stay_id, time_window_index, start_time, end_time, bt50, hr10, hr50, hr90, hr_sd, rr10, rr50, rr90, rr_sd, sbp10, sbp50, sbp90, sbp_sd, mbp10, mbp50, mbp90, mbp_sd, dbp10, dbp50, dbp90, dbp_sd, spo2_10, spo2_50, spo2_90, spo2_sd, bp_invasive