with
    infusion_injection_active_ingredients as (
        with
            infusion_injection_records as (
                select
                    icu_stay_id,
                    start_time,
                    end_time,
                    active_ingredient_name,
                    unit_per_hour,
                    unit
                from
                    `medicu-beta.latest_one_icu_derived.infusion_injection_active_ingredient_rate`
                where
                    active_ingredient_name in (
                        'propofol',
                        'noradrenaline',
                        'fentanyl',
                        'dexmedetomidine',
                        'dopamine',
                        'midazolam',
                        'dobutamine',
                        'landiolol',
                        'vasopressin',
                        'remifentanil',
                        'thiamylal',
                        'adrenaline',
                        'vecuronium',
                        'rocuronium'
                    )
                    and icu_stay_id in (
                        select icu_stay_id
                        from
                            `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
                    )
            ),

            match_infusion_injection_in_time_window as (
                -- このクエリの時点では、time window内のinputの記録数だけtime windowごとにrecordが存在することに注意する
                -- See:
                -- https://www.notion.so/medicu/time-window-join-b3fe7ece870b460c95496f994364bbe7?pvs=4
                select
                    time_windows.icu_stay_id,
                    time_window_index,
                    time_windows.start_time as time_window_start_time,
                    time_windows.end_time as time_window_end_time,
                    infusion_injection_records.start_time
                    as active_ingredient_start_time,
                    infusion_injection_records.end_time as active_ingredient_end_time,
                    active_ingredient_name,
                    unit_per_hour,
                    unit
                from
                    `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` time_windows
                left join
                    infusion_injection_records
                    on time_windows.icu_stay_id = infusion_injection_records.icu_stay_id
                    and time_windows.end_time > infusion_injection_records.start_time
                    and time_windows.start_time <= infusion_injection_records.end_time
            ),

            calculate_infusion_injection_duration as (
                select
                    icu_stay_id,
                    time_window_index,
                    time_window_start_time as start_time,
                    time_window_end_time as end_time,
                    greatest(
                        time_window_start_time, active_ingredient_start_time
                    ) as duration_start_time,
                    least(
                        time_window_end_time, active_ingredient_end_time
                    ) as duration_end_time,
                    active_ingredient_name,
                    unit_per_hour,
                    unit
                from match_infusion_injection_in_time_window
            ),

            calculate_infusion_injection_input_amount as (
                select
                    icu_stay_id,
                    time_window_index,
                    start_time,
                    end_time,
                    active_ingredient_name,
                    unit_per_hour,
                    unit,
                    unit_per_hour * cast(
                        timestamp_diff(
                            duration_end_time, duration_start_time, minute
                        ) as int64
                    )
                    / 60 as input_amount_active_ingredient,  -- time window内でのinput
                from calculate_infusion_injection_duration
            )

        select *
        from calculate_infusion_injection_input_amount
    ),

    prescription_active_ingredients as (
        with
            prescription_records as (
                select
                    icu_stay_id,
                    time,
                    timestamp_trunc(time, hour) as start_time,  -- timeを60分ごとに切り捨てて、time windowのstart_timeに合わせる。あとでtime windowにjoinするために使う
                    active_ingredient_name,
                    amount
                    * active_ingredient_per_unit_prescription_product
                    as amount_active_ingredient
                from `medicu-beta.latest_one_icu.prescriptions`
                left join
                    `medicu-beta.latest_one_icu_standard.prescription_product_active_ingredients`
                    using (prescription_product_name)
                -- active_ingredients tableをjoinしてactive_ingredientの単位を取得
                left join
                    `medicu-beta.latest_one_icu_standard.active_ingredients` using (
                        active_ingredient_name
                    )
                where
                    icu_stay_id in (
                        select icu_stay_id
                        from
                            `medicu-production.research_nms_delirium_2025.01_eligibility_criteria`
                    )
            ),

            join_prescription_active_ingredients as (
                select
                    time_windows.icu_stay_id,
                    time_window_index,
                    time_windows.start_time,
                    time_windows.end_time,
                    active_ingredient_name,
                    sum(amount_active_ingredient) as input_amount_active_ingredient
                from
                    `medicu-production.research_nms_delirium_2025.02_icu_stays_hourly` time_windows
                left join prescription_records using (icu_stay_id, start_time)
                group by
                    icu_stay_id,
                    time_window_index,
                    start_time,
                    end_time,
                    active_ingredient_name
            )

        select *
        from join_prescription_active_ingredients
    ),

    combine as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            active_ingredient_name,
            input_amount_active_ingredient
        from infusion_injection_active_ingredients
        union all
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            active_ingredient_name,
            input_amount_active_ingredient
        from prescription_active_ingredients
    ),

    pivot_active_ingredients as (
        select *
        from
            (
                select
                    icu_stay_id,
                    time_window_index,
                    start_time,
                    end_time,
                    active_ingredient_name,
                    input_amount_active_ingredient
                from combine
            ) pivot (
                sum(input_amount_active_ingredient) for active_ingredient_name in (
                    'propofol',
                    'noradrenaline',
                    'fentanyl',
                    'dexmedetomidine',
                    'dopamine',
                    'midazolam',
                    'dobutamine',
                    'landiolol',
                    'vasopressin',
                    'remifentanil',
                    'thiamylal',
                    'adrenaline',
                    'vecuronium',
                    'rocuronium'
                )
            )
    ),

    rename_columns as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            coalesce(propofol, 0) as active_ingredient_propofol,
            coalesce(noradrenaline, 0) as active_ingredient_noradrenaline,
            coalesce(fentanyl, 0) as active_ingredient_fentanyl,
            coalesce(dexmedetomidine, 0) as active_ingredient_dexmedetomidine,
            coalesce(dopamine, 0) as active_ingredient_dopamine,
            coalesce(midazolam, 0) as active_ingredient_midazolam,
            coalesce(dobutamine, 0) as active_ingredient_dobutamine,
            coalesce(landiolol, 0) as active_ingredient_landiolol,
            coalesce(vasopressin, 0) as active_ingredient_vasopressin,
            coalesce(remifentanil, 0) as active_ingredient_remifentanil,
            coalesce(thiamylal, 0) as active_ingredient_thiamylal,
            coalesce(adrenaline, 0) as active_ingredient_adrenaline,
            coalesce(vecuronium, 0) as active_ingredient_vecuronium,
            coalesce(rocuronium, 0) as active_ingredient_rocuronium
        from pivot_active_ingredients
    )

select *
from rename_columns
