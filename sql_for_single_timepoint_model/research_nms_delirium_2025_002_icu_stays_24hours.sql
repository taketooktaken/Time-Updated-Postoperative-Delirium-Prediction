-- time_zero: 最初のCAMICU記録時間
-- 入室時点でのデータを用いてせん妄発症を予測するモデルを作るため作成
-- 入室後から24hのデータのみを使用する
with
    define_first_time_window_start_time as (
        select
            icu_stay_id,
            in_time,
            out_time,
            in_time as time_zero,
            in_time as first_time_window_start_time
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays` 
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),

    generate_time_window_indices as (
        select
            icu_stay_id,
            in_time,
            out_time,
            time_zero,
            first_time_window_start_time,
            generate_array(
                0,
                cast(
                    floor(
                        timestamp_diff(out_time, first_time_window_start_time, hour)
                    ) as int64
                )
            ) as time_window_indices
        -- time_window_start_number > 
        -- cast(timestamp_diff(timestamp_trunc(it.out_time,
        -- hour),timestamp_trunc(it.in_time, hour),hour) as int64)
        -- の時、time_window_indicesが空になるので、time windowが生成されない
        from define_first_time_window_start_time
    ),

    generate_time_windows as (
        select
            icu_stay_id,
            time_window_index,
            timestamp_add(
                first_time_window_start_time, interval (time_window_index) * 24 hour
            ) as start_time,
            timestamp_add(
                first_time_window_start_time, interval (time_window_index + 1) * 24 hour
            ) as end_time,
            -- 正しくtime windowが生成されているか確認するために使うcolumns
            -- time_zeroは最初のtime windowに、out_timeは最後のtime windowに含まれているはず
            time_zero,
            out_time
        from generate_time_window_indices twi
        cross join unnest(twi.time_window_indices) as time_window_index
    )

select *
from generate_time_windows
where time_window_index = 0

