-- 12/14
with 
  get_camicu as (
    select
      icu_stay_id,
      time,
      timestamp_trunc(time, hour) as start_time,  -- 後でstart_timeとjoinするために切り捨て
      -- 下でgroup by するために、ここで数値として持ち変える
      case 
       when camicu_score = 'positive' then 1
       else 0
       end as camicu_score
    from `medicu-beta.latest_one_icu.camicu`
  ),

  join_time_window as (
    select
      co.icu_stay_id,
      co.time_window_index,
      co.start_time,
      co.end_time,
      max(camicu_score) as camicu_score
    from `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` co
    left join get_camicu using (icu_stay_id, start_time)
    group by icu_stay_id, time_window_index, start_time, end_time
  ),

  first_positive as (
    select
      *,
    -- 最初にcamicu_score = positiveになったtime_window_indexを取得 
      min(case when camicu_score = 1 then time_window_index end)
        over (partition by icu_stay_id) as first_pos_twi
    from join_time_window
  ),

  label_outcome as (
    select
      icu_stay_id,
      time_window_index,
      start_time,
      end_time,
      camicu_score,
      case
        when first_pos_twi is null then 0                 -- 一度も positive にならない症例は全て 0
        when time_window_index < first_pos_twi then 0     -- 初回 positive より前は 0
        when time_window_index = first_pos_twi then 1     -- 初回 positive は 1
        else 2                                            -- 以後は 2
      end as delirium_flag
    from first_positive
  ),
  -- 初めてせん妄になったtime_window_indexをとってくる
  join_delirium_time as (
    with 
    extract_delirium_index as (
     select 
      icu_stay_id,
      time_window_index as delirium_time_index
     from label_outcome
     where delirium_flag = 1
    )

    select 
     l.icu_stay_id,
     l.time_window_index,
     l.start_time,
     l.end_time,
     l.delirium_flag,
     e.delirium_time_index
    from label_outcome l
    left join extract_delirium_index e
    using (icu_stay_id)
  )

    select 
      *,
      -- モデリングの際に使用する
      case 
        when delirium_time_index is null then 0
        else 1
      end as label_delirium_indication
    from join_delirium_time
