with
  -- 1/29
  -- inclusion criteria
  inclusion_criteria as (
    with 
    filtered_1 as (
      select
        c.*,
        e.in_time,
        e.out_time,
        e.hospital_id
      from
        `medicu-beta.latest_one_icu.camicu` c
      left join
        `medicu-beta.latest_one_icu_derived.extended_icu_stays` e
      using (icu_stay_id)
      where
        -- 1. hospital_id in (1,2,3,5,6,7,8,9,10,11)
        hospital_id in (1, 2, 3, 5, 6, 7, 8, 9, 10, 11)
    ),

    -- 2. camicuの記録が1回以上ある症例
    filtered_2 as (
      select *
      from filtered_1
      where icu_stay_id in (
        select icu_stay_id
        from filtered_1
        group by icu_stay_id
        having count(*) >= 1
      )
    ),

    -- 3. ICU滞在期間が24hより長い症例 only
    filtered_3 as (
      select *
      from filtered_2
      where timestamp_add(in_time, interval 24 hour) < out_time
    ),

    -- 4. first_positive_time が 24h より後 or positive が存在しない症例のみ残す
    first_positive as (
      select
        icu_stay_id,
        min(time) as first_positive_time
      from filtered_3
      where camicu_score = 'positive'
      group by icu_stay_id
    ),

    filtered_4 as (
      select 
       f3.*
      from filtered_3 f3
      left join first_positive fp using (icu_stay_id)
      where
        -- 条件1: positive がない (fp.first_positive_time が null)
        fp.first_positive_time is null
        OR
        -- 条件2: 最初の positive が in_time + 24h より後
        fp.first_positive_time > timestamp_add(f3.in_time, interval 24 hour)
    )

    select distinct icu_stay_id from filtered_4
  ),

    -- exclusion criteria
    -- 1. 年齢、性別の記録がない症例
    -- 2. vital measurementの記録がない症例
    -- 3. ICD病名の記録がない症例
    -- 4. 小児（15歳未満）の症例は除外
    -- 5. time_window_index = 0 にCAMICU = positiveがある症例（最後に除外）
    exclusion_criteria as (
        with

            -- 1. 年齢、性別の記録がない症例
            no_recorded_gender_age as (
                select distinct icu_stay_id
                from inclusion_criteria
                where
                    icu_stay_id not in (
                        select distinct icu_stay_id
                        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
                        where age is not null and female is not null
                    )
            ),

            -- 2. vital measurementの記録がない症例
            no_recorded_vital_measurement as (
                select distinct icu_stay_id
                from inclusion_criteria
                where
                    icu_stay_id not in (
                        select distinct icu_stay_id
                        from `medicu-beta.latest_one_icu_derived.aggregated_vital_measurements`
                        where
                            (bt_core_count + bt_surface_count) > 0
                            and hr_count > 0
                            and rr_count > 0
                            and spo2_count > 0
                            and (invasive_sbp_count + non_invasive_sbp_count) > 0
                            and (invasive_mbp_count + non_invasive_mbp_count) > 0
                            and (invasive_dbp_count + non_invasive_dbp_count) > 0
                    )
            ),

            -- 3. ICD病名の記録がない症例
            no_recorded_icu_diagnosis as (
                select distinct icu_stay_id
                from inclusion_criteria
                where
                    icu_stay_id not in (
                        select distinct icu_stay_id
                        from `medicu-beta.latest_one_icu.icu_diagnoses`
                        group by icu_stay_id
                        having count(diagnosis) > 0
                    )
            ),

            -- 4. 小児（15歳未満）の症例は除外
            age_less_than_15 as (
                select distinct icu_stay_id
                from inclusion_criteria
                where
                    icu_stay_id not in (
                        select distinct icu_stay_id
                        from `medicu-beta.latest_one_icu_derived.extended_icu_stays`
                        where age >= 15
                    )
            )

        select icu_stay_id
        from no_recorded_gender_age
        union all
        select icu_stay_id
        from no_recorded_vital_measurement
        union all
        select icu_stay_id
        from no_recorded_icu_diagnosis
        union all
        select icu_stay_id
        from age_less_than_15
    )

select icu_stay_id
from inclusion_criteria
where icu_stay_id not in (select distinct icu_stay_id from exclusion_criteria)
