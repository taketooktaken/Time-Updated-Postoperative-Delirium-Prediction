with
  label_control_ventilation as (
    select
      mechanical_ventilation_id,
      inspiratory_pressure,
      1 as is_control_ventilation
    from `medicu-beta.latest_one_icu.control_ventilations`
  )

  , join_control_and_support_ventilations as (
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
  )

  , join_mechanical_ventilations as (
    select
      co.icu_stay_id,
      co.time_window_index,
      co.start_time,
      co.end_time,
      mv.fio2_ordered as fio2_ordered,
      mv.peep as peep_ordered,
      mv.inspiratory_pressure as inspiratory_pressure,
      mv.is_control_ventilation as is_control_ventilation,
      greatest(mv.start_time, co.start_time) as mv_start_time,
      least(mv.end_time, co.end_time) as mv_end_time
    from `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` co
    left join join_control_and_support_ventilations mv
      on mv.icu_stay_id = co.icu_stay_id
     and co.end_time > mv.start_time
     and co.start_time <= mv.end_time
    -- ref:
    -- https://www.notion.so/medicu/time-window-join-b3fe7ece870b460c95496f994364bbe7?pvs=4
  )

 , create_control_ventilation_time_window_index_label as (
    select
      icu_stay_id,
      time_window_index,
      start_time,
      end_time,
      fio2_ordered,
      peep_ordered,
      inspiratory_pressure,
      is_control_ventilation,
      case when is_control_ventilation = 1 then time_window_index end as control_time_window_index,
      timestamp_diff(mv_end_time, mv_start_time, MINUTE) as mv_duration_seg
    from join_mechanical_ventilations
  )

  , calculate_time_since_last_control_ventilation as (
    select
      *,
    -- 時間ある時再検討
    -- 24hをtime_windowとして切った場合どうするか
      time_window_index - last_value(control_time_window_index ignore nulls) over (
          partition by icu_stay_id
          order by time_window_index asc
          rows between unbounded preceding and current row
        ) as time_since_last_control_ventilation,
    from create_control_ventilation_time_window_index_label
  )

  select
      icu_stay_id,
      time_window_index,
      start_time,
      end_time,
      max(fio2_ordered) as fio2_ordered,
      max(peep_ordered) as peep_ordered,
      max(inspiratory_pressure) as inspiratory_pressure,
      max(is_control_ventilation) as is_control_ventilation,
      max(time_since_last_control_ventilation) as time_since_last_control_ventilation,
      sum(mv_duration_seg) as mv_duration
  from calculate_time_since_last_control_ventilation
  group by 
      icu_stay_id,
      time_window_index,
      start_time,
      end_time
