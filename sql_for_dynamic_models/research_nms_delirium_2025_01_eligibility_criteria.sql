with
-- 最新1/29
  -- inclusion criteria
  -- 1. hospital_id in (1,2,3,5,6,7,8,9,10,11)
  -- 2. camicuの記録が2回以上ある症例（camicuのテーブルにある icu_stay_id）
  inclusion_criteria as (
    with filtered as (
      select
        *
      from
        `medicu-beta.latest_one_icu.camicu` c
      left join
        `medicu-beta.latest_one_icu_derived.extended_icu_stays` e
      using (icu_stay_id)
        -- 1. hospital_id in (1,2,3,5,6,7,8,9,10,11)
      where
        hospital_id in (1, 2, 3, 5, 6, 7, 8, 9, 10, 11)
    )
    select 
      distinct icu_stay_id
    from
      filtered
    where
      icu_stay_id in (
        select
          icu_stay_id
        from filtered
        group by icu_stay_id
        -- 2. camicuの記録が2回以上ある症例（camicuのテーブルにある icu_stay_id）
        having count(*) >= 1
      )
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
