with
  label_control_ventilation as (
    select
      mechanical_ventilation_id,
      inspiratory_pressure,
      1 as is_control_ventilation
    from `medicu-beta.latest_one_icu.control_ventilations`
  ),

  join_control_and_support_ventilations as (
    select
      mechanical_ventilation_id,
      icu_stay_id,
      start_time,
      end_time,
      fio2_ordered,
      peep,
      coalesce(inspiratory_pressure, pressure_support) as inspiratory_pressure,
      coalesce(is_control_ventilation, 0) as is_control_ventilation
    from `medicu-beta.latest_one_icu.mechanical_ventilations`
    left join `medicu-beta.latest_one_icu.support_ventilations`
      using (mechanical_ventilation_id)
    left join label_control_ventilation
      using (mechanical_ventilation_id)
  ),

  join_mechanical_ventilations as (
    select
      co.icu_stay_id,
      co.time_window_index,
      co.start_time,
      co.end_time,
      -- 複数の人工呼吸器設定がある場合は、end_timeが遅い方の記録を取得する
      {{ max_by_ignore_nulls("mv.fio2_ordered", "mv.end_time") }} as fio2_ordered,
      {{ max_by_ignore_nulls("mv.peep", "mv.end_time") }} as peep_ordered,
      {{ max_by_ignore_nulls("mv.inspiratory_pressure", "mv.end_time") }} as inspiratory_pressure,
      {{ max_by_ignore_nulls("mv.is_control_ventilation", "mv.end_time") }} as is_control_ventilation,
      max(case when mv.mechanical_ventilation_id is not null then 1 else 0 end) as mv_present
    from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` co
    left join join_control_and_support_ventilations mv
      on mv.icu_stay_id = co.icu_stay_id
     and co.end_time > mv.start_time
     and co.start_time <= mv.end_time
    -- ref:
    -- https://www.notion.so/medicu/time-window-join-b3fe7ece870b460c95496f994364bbe7?pvs=4
    group by
      icu_stay_id,
      time_window_index,
      start_time,
      end_time
  ),

  create_control_ventilation_time_window_index_label as (
    select
      *,
      case when is_control_ventilation = 1 then time_window_index end as control_time_window_index
    from join_mechanical_ventilations
  ),

  -- 0/1 切り替えフラグ → 累積で group_id（セグメント）
  seg as (
    select
      *,
      time_window_index - last_value(control_time_window_index ignore nulls) over (
          partition by icu_stay_id
          order by time_window_index asc
          rows between unbounded preceding and current row
        ) as time_since_last_control_ventilation,
      case
        when lag(mv_present) over (partition by icu_stay_id order by time_window_index) is null
          or mv_present != lag(mv_present) over (partition by icu_stay_id order by time_window_index)
        then 1 else 0
      end as seg_start
    from create_control_ventilation_time_window_index_label
  ),

  seg_id as (
    select
      *,
      sum(seg_start) over (
        partition by icu_stay_id
        order by time_window_index
        rows between unbounded preceding and current row
      ) as group_id
    from seg
  ),

  mv_duration as (
    select
      icu_stay_id,
      time_window_index,
      start_time,
      end_time,
      fio2_ordered,
      peep_ordered,
      inspiratory_pressure,
      is_control_ventilation,
      time_since_last_control_ventilation,
      case
        when mv_present = 1 then
          row_number() over (
            partition by icu_stay_id, group_id
            order by time_window_index
          )
        else 0
      end as mv_duration
    from seg_id
  )

select
  *
from mv_duration