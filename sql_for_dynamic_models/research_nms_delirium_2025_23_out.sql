with
    ceil_time as (
        select
            icu_stay_id,
            -- 60分間隔でtimeを切り上げ
            {{ round_up_hourly("time") }} as time_ceiled,
            sum(blood) as blood,
            sum(urine) as urine,
            sum(fluid_removal_during_dialysis) as fluid_removal_during_dialysis,
            sum(pleural) as pleural,
            sum(ascites) as ascites,
            sum(gastrointestinal_fluid) as gastrointestinal_fluid,
            sum(pericardial_fluid) as pericardial_fluid,
            sum(cerebrospinal_fluid) as cerebrospinal_fluid,
            sum(other_body_fluid) as other_body_fluid,
            sum(stool_ml) as stool_ml
        from `medicu-beta.latest_one_icu.out`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
            )
        group by icu_stay_id, time_ceiled
    ),

    calculate_last_out_time as (
        -- 直近のoutputまでの時間（time window単位）を計算する
        select
            stays.icu_stay_id,
            in_time,
            timestamp_trunc(in_time, hour) as in_time_floored,
            ct.time_ceiled,
            blood,
            last_value(if(blood is null, null, ct.time_ceiled) ignore nulls) over w
            as last_blood_time,
            urine,
            last_value(if(urine is null, null, ct.time_ceiled) ignore nulls) over w
            as last_urine_time,
            fluid_removal_during_dialysis,
            last_value(
                if(
                    fluid_removal_during_dialysis is null, null, ct.time_ceiled
                ) ignore nulls
            ) over w as last_fluid_removal_during_dialysis_time,
            pleural,
            last_value(if(pleural is null, null, ct.time_ceiled) ignore nulls) over w
            as last_pleural_time,
            ascites,
            last_value(if(ascites is null, null, ct.time_ceiled) ignore nulls) over w
            as last_ascites_time,
            gastrointestinal_fluid,
            last_value(
                if(gastrointestinal_fluid is null, null, ct.time_ceiled) ignore nulls
            ) over w as last_gastrointestinal_fluid_time,
            pericardial_fluid,
            last_value(
                if(pericardial_fluid is null, null, ct.time_ceiled) ignore nulls
            ) over w as last_pericardial_fluid_time,
            cerebrospinal_fluid,
            last_value(
                if(cerebrospinal_fluid is null, null, ct.time_ceiled) ignore nulls
            ) over w as last_cerebrospinal_fluid_time,
            other_body_fluid,
            last_value(
                if(other_body_fluid is null, null, ct.time_ceiled) ignore nulls
            ) over w as last_other_body_fluid_time,
            stool_ml,
            last_value(if(stool_ml is null, null, ct.time_ceiled) ignore nulls) over w
            as last_stool_ml_time
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays` stays
        inner join ceil_time ct on stays.icu_stay_id = ct.icu_stay_id
        window
            w as (
                partition by stays.icu_stay_id
                order by ct.time_ceiled
                rows between unbounded preceding and 1 preceding
            )
    ),

    calculate_time_diff_from_last_out as (
        select
            icu_stay_id,
            in_time,
            in_time_floored,
            time_ceiled,
            blood,
            timestamp_diff(
                time_ceiled, coalesce(last_blood_time, in_time_floored), minute
            ) as time_since_last_blood,
            urine,
            timestamp_diff(
                time_ceiled, coalesce(last_urine_time, in_time_floored), minute
            ) as time_since_last_urine,
            fluid_removal_during_dialysis,
            timestamp_diff(
                time_ceiled,
                coalesce(last_fluid_removal_during_dialysis_time, in_time_floored),
                minute
            ) as time_since_last_fluid_removal_during_dialysis,
            pleural,
            timestamp_diff(
                time_ceiled, coalesce(last_pleural_time, in_time_floored), minute
            ) as time_since_last_pleural,
            ascites,
            timestamp_diff(
                time_ceiled, coalesce(last_ascites_time, in_time_floored), minute
            ) as time_since_last_ascites,
            gastrointestinal_fluid,
            timestamp_diff(
                time_ceiled,
                coalesce(last_gastrointestinal_fluid_time, in_time_floored),
                minute
            ) as time_since_last_gastrointestinal_fluid,
            pericardial_fluid,
            timestamp_diff(
                time_ceiled,
                coalesce(last_pericardial_fluid_time, in_time_floored),
                minute
            ) as time_since_last_pericardial_fluid,
            cerebrospinal_fluid,
            timestamp_diff(
                time_ceiled,
                coalesce(last_cerebrospinal_fluid_time, in_time_floored),
                minute
            ) as time_since_last_cerebrospinal_fluid,
            other_body_fluid,
            timestamp_diff(
                time_ceiled,
                coalesce(last_other_body_fluid_time, in_time_floored),
                minute
            ) as time_since_last_other_body_fluid,
            stool_ml,
            timestamp_diff(
                time_ceiled, coalesce(last_stool_ml_time, in_time_floored), minute
            ) as time_since_last_stool_ml
        from calculate_last_out_time
    ),

    calculate_window_diff_from_last_out as (
        select
            icu_stay_id,
            in_time,
            in_time_floored,
            time_ceiled,
            blood,
            cast(time_since_last_blood / 60 as int64) as windows_since_last_blood,
            urine,
            cast(time_since_last_urine / 60 as int64) as windows_since_last_urine,
            fluid_removal_during_dialysis,
            cast(
                time_since_last_fluid_removal_during_dialysis / 60 as int64
            ) as windows_since_last_fluid_removal_during_dialysis,
            pleural,
            cast(time_since_last_pleural / 60 as int64) as windows_since_last_pleural,
            ascites,
            cast(time_since_last_ascites / 60 as int64) as windows_since_last_ascites,
            gastrointestinal_fluid,
            cast(
                time_since_last_gastrointestinal_fluid / 60 as int64
            ) as windows_since_last_gastrointestinal_fluid,
            pericardial_fluid,
            cast(
                time_since_last_pericardial_fluid / 60 as int64
            ) as windows_since_last_pericardial_fluid,
            cerebrospinal_fluid,
            cast(
                time_since_last_cerebrospinal_fluid / 60 as int64
            ) as windows_since_last_cerebrospinal_fluid,
            other_body_fluid,
            cast(
                time_since_last_other_body_fluid / 60 as int64
            ) as windows_since_last_other_body_fluid,
            stool_ml,
            cast(time_since_last_stool_ml / 60 as int64) as windows_since_last_stool_ml
        from calculate_time_diff_from_last_out
    ),

    calculate_out_per_window as (
        select
            icu_stay_id,
            time_ceiled as end_time,
            blood,
            windows_since_last_blood,
            round(
                blood / if(windows_since_last_blood <= 0, 1, windows_since_last_blood),
                3
            ) as window_blood,
            urine,
            windows_since_last_urine,
            round(
                urine / if(windows_since_last_urine <= 0, 1, windows_since_last_urine),
                3
            ) as window_urine,
            fluid_removal_during_dialysis,
            windows_since_last_fluid_removal_during_dialysis,
            round(
                fluid_removal_during_dialysis / if(
                    windows_since_last_fluid_removal_during_dialysis <= 0,
                    1,
                    windows_since_last_fluid_removal_during_dialysis
                ),
                3
            ) as window_fluid_removal_during_dialysis,
            pleural,
            windows_since_last_pleural,
            round(
                pleural
                / if(windows_since_last_pleural <= 0, 1, windows_since_last_pleural),
                3
            ) as window_pleural,
            ascites,
            windows_since_last_ascites,
            round(
                ascites
                / if(windows_since_last_ascites <= 0, 1, windows_since_last_ascites),
                3
            ) as window_ascites,
            gastrointestinal_fluid,
            windows_since_last_gastrointestinal_fluid,
            round(
                gastrointestinal_fluid / if(
                    windows_since_last_gastrointestinal_fluid <= 0,
                    1,
                    windows_since_last_gastrointestinal_fluid
                ),
                3
            ) as window_gastrointestinal_fluid,
            pericardial_fluid,
            windows_since_last_pericardial_fluid,
            round(
                pericardial_fluid / if(
                    windows_since_last_pericardial_fluid <= 0,
                    1,
                    windows_since_last_pericardial_fluid
                ),
                3
            ) as window_pericardial_fluid,
            cerebrospinal_fluid,
            windows_since_last_cerebrospinal_fluid,
            round(
                cerebrospinal_fluid / if(
                    windows_since_last_cerebrospinal_fluid <= 0,
                    1,
                    windows_since_last_cerebrospinal_fluid
                ),
                3
            ) as window_cerebrospinal_fluid,
            other_body_fluid,
            windows_since_last_other_body_fluid,
            round(
                other_body_fluid / if(
                    windows_since_last_other_body_fluid <= 0,
                    1,
                    windows_since_last_other_body_fluid
                ),
                3
            ) as window_other_body_fluid,
            stool_ml,
            windows_since_last_stool_ml,
            round(
                stool_ml
                / if(windows_since_last_stool_ml <= 0, 1, windows_since_last_stool_ml),
                3
            ) as window_stool_ml
        from calculate_window_diff_from_last_out
    ),

    join_to_time_windows as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            calculate_out_per_window.* except (icu_stay_id, end_time)
        from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly`
        left join calculate_out_per_window using (icu_stay_id, end_time)
    ),

    get_time_window_output as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            first_value(window_blood ignore nulls) over w as window_blood,
            first_value(window_urine ignore nulls) over w as window_urine,
            first_value(window_fluid_removal_during_dialysis ignore nulls) over w
            as window_fluid_removal_during_dialysis,
            first_value(window_pleural ignore nulls) over w as window_pleural,
            first_value(window_ascites ignore nulls) over w as window_ascites,
            first_value(window_gastrointestinal_fluid ignore nulls) over w
            as window_gastrointestinal_fluid,
            first_value(window_pericardial_fluid ignore nulls) over w
            as window_pericardial_fluid,
            first_value(window_cerebrospinal_fluid ignore nulls) over w
            as window_cerebrospinal_fluid,
            first_value(window_other_body_fluid ignore nulls) over w
            as window_other_body_fluid,
            first_value(window_stool_ml ignore nulls) over w as window_stool_ml
        from join_to_time_windows
        window
            w as (
                partition by icu_stay_id
                order by time_window_index
                rows between current row and unbounded following
            )
    ),

    sum_all_out as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            window_urine as window_urinary_output,
            ifnull(window_blood, 0)
            + ifnull(window_urine, 0)
            + ifnull(window_fluid_removal_during_dialysis, 0)
            + ifnull(window_pleural, 0)
            + ifnull(window_ascites, 0)
            + ifnull(window_gastrointestinal_fluid, 0)
            + ifnull(window_pericardial_fluid, 0)
            + ifnull(window_cerebrospinal_fluid, 0)
            + ifnull(window_other_body_fluid, 0)
            + ifnull(window_stool_ml, 0) as window_total_output
        from get_time_window_output
    )

select *
from sum_all_out