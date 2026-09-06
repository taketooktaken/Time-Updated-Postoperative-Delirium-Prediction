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
        from `medicu-production.research_nms_delirium_2025.031_join_all_features`
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
    )

select *
from calculate_cumsum_in_out
