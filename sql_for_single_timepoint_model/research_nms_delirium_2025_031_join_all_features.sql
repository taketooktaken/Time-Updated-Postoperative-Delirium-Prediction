with
    join_outcome as (
        select
            icu_stays_hourly.*,
            outcome.* except (icu_stay_id)
        from
            `medicu-production.research_nms_delirium_2025.002_icu_stays_24hours` icu_stays_hourly
        left join
            `medicu-production.research_nms_delirium_2025.003_outcome_labeling` outcome
            using (icu_stay_id)
    ),

    join_blood_gas as (
        select
            join_outcome.*,
            blood_gas.* except (icu_stay_id, time_window_index, start_time, end_time)
        from join_outcome
        left join
            `medicu-production.research_nms_delirium_2025.011_blood_gas` blood_gas
            using (icu_stay_id, time_window_index)
    ),

    join_gcs as (
        select
            join_blood_gas.*,
            gcs.* except (icu_stay_id, time_window_index, start_time, end_time)
        from join_blood_gas
        left join
            `medicu-production.research_nms_delirium_2025.012_gcs` gcs using (
                icu_stay_id, time_window_index
            )
    ),

    join_weight as (
        select
            join_gcs.*,
            weight.* except (icu_stay_id, time_window_index, start_time, end_time)
        from join_gcs
        left join
            `medicu-production.research_nms_delirium_2025.013_weight` weight using (
                icu_stay_id, time_window_index
            )
    ),

    join_vital_measurements as (
        select
            join_weight.*,
            vital_measurements.* except (
                icu_stay_id, time_window_index, start_time, end_time
            )
        from join_weight
        left join
            `medicu-production.research_nms_delirium_2025.014_vital_measurements` vital_measurements
            using (icu_stay_id, time_window_index)
    ),

    join_labolatory_tests as (
        select
            join_vital_measurements.*,
            labolatory_tests.* except (
                icu_stay_id, time_window_index, start_time, end_time
            )
        from join_vital_measurements
        left join
            `medicu-production.research_nms_delirium_2025.015_labolatory_tests` labolatory_tests
            using (icu_stay_id, time_window_index)
    ),

    join_static_features as (
        select join_labolatory_tests.*, static_features.* except (icu_stay_id) 
        from join_labolatory_tests
        left join
            `medicu-production.research_nms_delirium_2025.016_static_features` static_features
            using (icu_stay_id)
    ),

    join_mechanical_ventilations as (
        select
            join_static_features.*,
            mechanical_ventilations.* except (
                icu_stay_id, time_window_index, start_time, end_time
            )
        from join_static_features
        left join
            `medicu-production.research_nms_delirium_2025.017_mechanical_ventilations` mechanical_ventilations
            using (icu_stay_id, time_window_index)
    ),

    join_rass as (
        select
            join_mechanical_ventilations.*,
            rass.* except (
                icu_stay_id, time_window_index, start_time, end_time
            )
        from join_mechanical_ventilations
        left join
            `medicu-production.research_nms_delirium_2025.018_rass` rass
            using (icu_stay_id, time_window_index)
    ),

    join_sofa as (
        select
            join_rass.*,
            sofa.* except (
                icu_stay_id, time_window_index, start_time, end_time
            )
        from join_rass
        left join
            `medicu-production.research_nms_delirium_2025.019_sofa` sofa
            using (icu_stay_id, time_window_index)
    ),

    join_input_amount as (
        select
            join_sofa.*,
            input_amount.* except (icu_stay_id, time_window_index, start_time, end_time)
        from join_sofa
        left join
            `medicu-production.research_nms_delirium_2025.021_input_amount` input_amount
            using (icu_stay_id, time_window_index)
    ),

    join_drug_active_ingredients as (
        select
            join_input_amount.*,
            drug_active_ingredients.* except (
                icu_stay_id, time_window_index, start_time, end_time
            )
        from join_input_amount
        left join
            `medicu-production.research_nms_delirium_2025.022_drug_active_ingredients` drug_active_ingredients
            using (icu_stay_id, time_window_index)
    ),

    join_out as (
        select
            join_drug_active_ingredients.*,
            out.* except (icu_stay_id, time_window_index, start_time, end_time)
        from join_drug_active_ingredients
        left join
            `medicu-production.research_nms_delirium_2025.023_out` out using (
                icu_stay_id, time_window_index
            )
    ),

    join_transfusion as (
        select
            join_out.*,
            transfusion.* except (icu_stay_id, time_window_index, start_time, end_time)
        from join_out
        left join
            `medicu-production.research_nms_delirium_2025.024_transfusion` transfusion using (
                icu_stay_id, time_window_index
            )
    )

select *
from join_transfusion