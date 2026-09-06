with
    input_amount_records as (
        select *
        from `medicu-beta.latest_one_icu_derived.input_amount_rate`
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    )

      ,join_input_amount as (
         with
             match_input_amount_in_time_window as (
                -- このクエリの時点では、time window内のinputの記録数だけtime windowごとにrecordが存在することに注意
                -- See:
                -- https://www.notion.so/medicu/time-window-join-b3fe7ece870b460c95496f994364bbe7?pvs=4
                select
                    time_windows.icu_stay_id,
                    time_window_index,
                    time_windows.start_time as time_window_start_time,
                    time_windows.end_time as time_window_end_time,
                    source,
                    source_id,
                    input_amount_records.start_time as input_start_time,
                    input_amount_records.end_time as input_end_time,
                    ml_per_hour
                from
                    `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` time_windows
                left join
                    input_amount_records
                    on time_windows.icu_stay_id = input_amount_records.icu_stay_id
                    and time_windows.end_time > input_amount_records.start_time
                    and time_windows.start_time <= input_amount_records.end_time
            )

             , calculate_duration as (
                select
                    icu_stay_id,
                    time_window_index,
                    time_window_start_time as start_time,
                    time_window_end_time as end_time,
                    source,
                    source_id,
                    greatest(
                        time_window_start_time, input_start_time) as duration_start_time,
                    least(time_window_end_time, input_end_time) as duration_end_time,
                    ml_per_hour
                from match_input_amount_in_time_window
            )

            , calculate_input_amount as (
                select
                    icu_stay_id,
                    time_window_index,
                    start_time,
                    end_time,
                    source,
                    source_id,
                    ml_per_hour * cast(
                        timestamp_diff(
                            duration_end_time, duration_start_time, minute
                        ) as int64
                    )
                    / 60 as input_amount,  -- time window内でのinput
                    ml_per_hour
                from calculate_duration
            )

        select *
        from calculate_input_amount
    ),

    aggregate_by_time_window as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            coalesce(sum(input_amount), 0) as input_amount  -- inputの記録が全くないtime windowはnullではなくinputが0だったと判断する
        from join_input_amount
        group by icu_stay_id, time_window_index, start_time, end_time
    )

select *
from aggregate_by_time_window
