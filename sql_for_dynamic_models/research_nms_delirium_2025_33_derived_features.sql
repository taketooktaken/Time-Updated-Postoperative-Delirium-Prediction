with
    create_current_value_flags as (
        select
            *,
            case
                when fio2_ordered is not null then 1 else 0
            end as fio2_ordered_is_current_value,
            case
                when peep_ordered is not null then 1 else 0
            end as peep_ordered_is_current_value,
            case when pao2 is not null then 1 else 0 end as pao2_is_current_value
        from `medicu-production.research_nms_delirium_2025.32_extract_before_delirium`
    ),

    calculate_standardized_out as (
        select
            * except (ideal_body_weight, window_urinary_output),
            round(
                cast((window_urinary_output / nullif(ideal_body_weight, 0)) as float64),
                4
            ) as standardized_urinary_output
        from create_current_value_flags
    ),

    calculate_cumsum_in_out as (
        select
            *,
            -- cumsum_in: 入室から現在までのinput総量
            sum(input_amount) over (
                partition by icu_stay_id
                order by time_window_index
                rows between unbounded preceding and current row
            ) as cumsum_in,
            -- cumsum_out: 入室から現在までの尿量総量
            sum(window_total_output) over (
                partition by icu_stay_id
                order by time_window_index
                rows between unbounded preceding and current row
            ) as cumsum_out,
            -- cumsum_balance: 入室から現在までの液体バランス
            sum(input_amount) over (
                partition by icu_stay_id
                order by time_window_index
                rows between unbounded preceding and current row
            ) - sum(window_total_output) over (
                partition by icu_stay_id
                order by time_window_index
                rows between unbounded preceding and current row
            ) as cumsum_balance
        from calculate_standardized_out
    ),

    create_lags as (
        select
            *,
            lag(whole, 1) over lag_calculation as lag1,
            lag(whole, 6) over lag_calculation as lag6,
            lag(whole, 12) over lag_calculation as lag12,
        from calculate_cumsum_in_out as whole
        window lag_calculation as (partition by icu_stay_id order by time_window_index)
    ),

    calculate_lag_features as (
        select
            * except (lag1, lag6, lag12),
            -- hr
            hr10 - lag1.hr10 as delta_hr10_lag1,
            hr10 - lag6.hr10 as delta_hr10_lag6,
            hr10 - lag12.hr10 as delta_hr10_lag12,

            hr50 - lag1.hr50 as delta_hr50_lag1,
            hr50 - lag6.hr50 as delta_hr50_lag6,
            hr50 - lag12.hr50 as delta_hr50_lag12,

            hr90 - lag1.hr90 as delta_hr90_lag1,
            hr90 - lag6.hr90 as delta_hr90_lag6,
            hr90 - lag12.hr90 as delta_hr90_lag12,

            hr_sd - lag1.hr_sd as delta_hr_sd_lag1,
            hr_sd - lag6.hr_sd as delta_hr_sd_lag6,
            hr_sd - lag12.hr_sd as delta_hr_sd_lag12,

            -- rr
            rr10 - lag1.rr10 as delta_rr10_lag1,
            rr10 - lag6.rr10 as delta_rr10_lag6,
            rr10 - lag12.rr10 as delta_rr10_lag12,

            rr50 - lag1.rr50 as delta_rr50_lag1,
            rr50 - lag6.rr50 as delta_rr50_lag6,
            rr50 - lag12.rr50 as delta_rr50_lag12,

            rr90 - lag1.rr90 as delta_rr90_lag1,
            rr90 - lag6.rr90 as delta_rr90_lag6,
            rr90 - lag12.rr90 as delta_rr90_lag12,

            rr_sd - lag1.rr_sd as delta_rr_sd_lag1,
            rr_sd - lag6.rr_sd as delta_rr_sd_lag6,
            rr_sd - lag12.rr_sd as delta_rr_sd_lag12,

            -- sbp
            sbp10 - lag1.sbp10 as delta_sbp10_lag1,
            sbp10 - lag6.sbp10 as delta_sbp10_lag6,
            sbp10 - lag12.sbp10 as delta_sbp10_lag12,

            sbp50 - lag1.sbp50 as delta_sbp50_lag1,
            sbp50 - lag6.sbp50 as delta_sbp50_lag6,
            sbp50 - lag12.sbp50 as delta_sbp50_lag12,

            sbp90 - lag1.sbp90 as delta_sbp90_lag1,
            sbp90 - lag6.sbp90 as delta_sbp90_lag6,
            sbp90 - lag12.sbp90 as delta_sbp90_lag12,

            sbp_sd - lag1.sbp_sd as delta_sbp_sd_lag1,
            sbp_sd - lag6.sbp_sd as delta_sbp_sd_lag6,
            sbp_sd - lag12.sbp_sd as delta_sbp_sd_lag12,

            -- mbp
            mbp10 - lag1.mbp10 as delta_mbp10_lag1,
            mbp10 - lag6.mbp10 as delta_mbp10_lag6,
            mbp10 - lag12.mbp10 as delta_mbp10_lag12,

            mbp50 - lag1.mbp50 as delta_mbp50_lag1,
            mbp50 - lag6.mbp50 as delta_mbp50_lag6,
            mbp50 - lag12.mbp50 as delta_mbp50_lag12,

            mbp90 - lag1.mbp90 as delta_mbp90_lag1,
            mbp90 - lag6.mbp90 as delta_mbp90_lag6,
            mbp90 - lag12.mbp90 as delta_mbp90_lag12,

            mbp_sd - lag1.mbp_sd as delta_mbp_sd_lag1,
            mbp_sd - lag6.mbp_sd as delta_mbp_sd_lag6,
            mbp_sd - lag12.mbp_sd as delta_mbp_sd_lag12,

            -- dbp
            dbp10 - lag1.dbp10 as delta_dbp10_lag1,
            dbp10 - lag6.dbp10 as delta_dbp10_lag6,
            dbp10 - lag12.dbp10 as delta_dbp10_lag12,

            dbp50 - lag1.dbp50 as delta_dbp50_lag1,
            dbp50 - lag6.dbp50 as delta_dbp50_lag6,
            dbp50 - lag12.dbp50 as delta_dbp50_lag12,

            dbp90 - lag1.dbp90 as delta_dbp90_lag1,
            dbp90 - lag6.dbp90 as delta_dbp90_lag6,
            dbp90 - lag12.dbp90 as delta_dbp90_lag12,

            dbp_sd - lag1.dbp_sd as delta_dbp_sd_lag1,
            dbp_sd - lag6.dbp_sd as delta_dbp_sd_lag6,
            dbp_sd - lag12.dbp_sd as delta_dbp_sd_lag12,

            -- spo2
            spo2_10 - lag1.spo2_10 as delta_spo2_10_lag1,
            spo2_10 - lag6.spo2_10 as delta_spo2_10_lag6,
            spo2_10 - lag12.spo2_10 as delta_spo2_10_lag12,

            spo2_50 - lag1.spo2_50 as delta_spo2_50_lag1,
            spo2_50 - lag6.spo2_50 as delta_spo2_50_lag6,
            spo2_50 - lag12.spo2_50 as delta_spo2_50_lag12,

            spo2_90 - lag1.spo2_90 as delta_spo2_90_lag1,
            spo2_90 - lag6.spo2_90 as delta_spo2_90_lag6,
            spo2_90 - lag12.spo2_90 as delta_spo2_90_lag12,

            spo2_sd - lag1.spo2_sd as delta_spo2_sd_lag1,
            spo2_sd - lag6.spo2_sd as delta_spo2_sd_lag6,
            spo2_sd - lag12.spo2_sd as delta_spo2_sd_lag12,

            -- fio2_ordered
            fio2_ordered - lag1.fio2_ordered as delta_fio2_ordered_lag1,
            fio2_ordered - lag6.fio2_ordered as delta_fio2_ordered_lag6,
            fio2_ordered - lag12.fio2_ordered as delta_fio2_ordered_lag12,

            -- peep_ordered
            peep_ordered - lag1.peep_ordered as delta_peep_ordered_lag1,
            peep_ordered - lag6.peep_ordered as delta_peep_ordered_lag6,
            peep_ordered - lag12.peep_ordered as delta_peep_ordered_lag12,
        from create_lags
    )

select *
from calculate_lag_features
