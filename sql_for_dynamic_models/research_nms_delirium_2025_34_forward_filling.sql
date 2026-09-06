with
    forward_filling as (
        select
            icu_stay_id,
            time_window_index,
            start_time,
            end_time,
            -- 03_outcome
            delirium_flag,
            delirium_time_index,
            label_delirium_indication,
            -- 16_static
            hospital_id,
            icu_admit_time,
            female,
            age,
            icu_admission_type,
            -- 疾患カテゴリー
            diagnosis_category,
            covid19,
            sepsis,
            stroke,
            poisoning,
            anaphylaxis,
            burn,
            temperature_disorder,
            hanging_asphyxiation,
            trauma,
            infection,
            neoplasms,
            circulatory,
            respiratory,
            digestive,
            neurological,
            genitourinary,
            electrolyte_metabolic_disorders,
            musculoskeletal,
            psychiatric,
            congenital,
            undefined,
            other,
            icd10,
            -- apache2
            apache2_score,
            -- charlson
            charlson_comorbidity_index,
            myocardial_infarct,
            congestive_heart_failure,
            peripheral_arterial_disease,
            cerebrovascular_disease,
            dementia,
            chronic_pulmonary_disease,
            connective_tissue_disease,
            peptic_ulcer_disease,
            mild_liver_disease,
            diabetes_without_cc,
            diabetes_with_cc,
            paraplegia,
            renal_disease,
            malignant_cancer,
            severe_liver_disease,
            metastatic_solid_tumor,
            aids,
            age_score,
            -- 20_current_time_of_day
            current_time_of_day,
            -- 17_mechanical_ventilation
            -- fio2,peepはunbounded preceding
            -- それ以外のfeatureはfillingなし
            {{
                forward_filled(
                    "fio2_ordered",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as fio2_ordered,
            fio2_ordered_is_current_value,
            delta_fio2_ordered_lag1,
            delta_fio2_ordered_lag6,
            delta_fio2_ordered_lag12,
            {{
                forward_filled(
                    "peep_ordered",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as peep_ordered,
            peep_ordered_is_current_value,
            delta_peep_ordered_lag1,
            delta_peep_ordered_lag6,
            delta_peep_ordered_lag12,
            {{
                forward_filled(
                    "inspiratory_pressure",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as inspiratory_pressure,
            time_since_last_control_ventilation,
            mv_duration,
            -- 11_blood_gas
            -- 26hまで遡る
            {{
                forward_filled(
                    "ph",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as ph,
            {{
                forward_filled(
                    "pao2",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as pao2,
            {{
                forward_filled(
                    "pvo2",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as pvo2,
            {{
                forward_filled(
                    "paco2",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as paco2,
            {{
                forward_filled(
                    "pvco2",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as pvco2,
            {{
                forward_filled(
                    "bg_lactate",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as bg_lactate,
            {{
                forward_filled(
                    "bg_glucose",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as bg_glucose,

            -- 12_gcs
            -- unbounded preceding
            {{
                forward_filled(
                    "gcs_e",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as gcs_e,
            {{
                forward_filled(
                    "gcs_v",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as gcs_v,
            {{
                forward_filled(
                    "gcs_m",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as gcs_m,

            -- 13_weight
            -- unbounded preceding
            {{
                forward_filled(
                    "body_weight",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as body_weight,

            -- 14_vital_measurements
            -- btは12h遡る
            {{
                forward_filled(
                    "bt50",
                    12,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as bt50,
            -- hr,rr,spo2は2h, 血圧系は4hまで遡る
            {{
                forward_filled(
                    "hr10",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as hr10,
            {{
                forward_filled(
                    "hr50",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as hr50,
            {{
                forward_filled(
                    "hr90",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as hr90,
            {{
                forward_filled(
                    "hr_sd",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as hr_sd,
            delta_hr10_lag1,
            delta_hr10_lag6,
            delta_hr10_lag12,
            delta_hr50_lag1,
            delta_hr50_lag6,
            delta_hr50_lag12,
            delta_hr90_lag1,
            delta_hr90_lag6,
            delta_hr90_lag12,
            delta_hr_sd_lag1,
            delta_hr_sd_lag6,
            delta_hr_sd_lag12,
            {{
                forward_filled(
                    "rr10",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as rr10,
            {{
                forward_filled(
                    "rr50",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as rr50,
            {{
                forward_filled(
                    "rr90",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as rr90,
            {{
                forward_filled(
                    "rr_sd",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as rr_sd,
            delta_rr10_lag1,
            delta_rr10_lag6,
            delta_rr10_lag12,
            delta_rr50_lag1,
            delta_rr50_lag6,
            delta_rr50_lag12,
            delta_rr90_lag1,
            delta_rr90_lag6,
            delta_rr90_lag12,
            delta_rr_sd_lag1,
            delta_rr_sd_lag6,
            delta_rr_sd_lag12,
            {{
                forward_filled(
                    "sbp10",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as sbp10,
            {{
                forward_filled(
                    "sbp50",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as sbp50,
            {{
                forward_filled(
                    "sbp90",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as sbp90,
            {{
                forward_filled(
                    "sbp_sd",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as sbp_sd,
            delta_sbp10_lag1,
            delta_sbp10_lag6,
            delta_sbp10_lag12,
            delta_sbp50_lag1,
            delta_sbp50_lag6,
            delta_sbp50_lag12,
            delta_sbp90_lag1,
            delta_sbp90_lag6,
            delta_sbp90_lag12,
            delta_sbp_sd_lag1,
            delta_sbp_sd_lag6,
            delta_sbp_sd_lag12,
            {{
                forward_filled(
                    "mbp10",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as mbp10,
            {{
                forward_filled(
                    "mbp50",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as mbp50,
            {{
                forward_filled(
                    "mbp90",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as mbp90,
            {{
                forward_filled(
                    "mbp_sd",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as mbp_sd,
            delta_mbp10_lag1,
            delta_mbp10_lag6,
            delta_mbp10_lag12,
            delta_mbp50_lag1,
            delta_mbp50_lag6,
            delta_mbp50_lag12,
            delta_mbp90_lag1,
            delta_mbp90_lag6,
            delta_mbp90_lag12,
            delta_mbp_sd_lag1,
            delta_mbp_sd_lag6,
            delta_mbp_sd_lag12,
            {{
                forward_filled(
                    "dbp10",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as dbp10,
            {{
                forward_filled(
                    "dbp50",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as dbp50,
            {{
                forward_filled(
                    "dbp90",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as dbp90,
            {{
                forward_filled(
                    "dbp_sd",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as dbp_sd,
            delta_dbp10_lag1,
            delta_dbp10_lag6,
            delta_dbp10_lag12,
            delta_dbp50_lag1,
            delta_dbp50_lag6,
            delta_dbp50_lag12,
            delta_dbp90_lag1,
            delta_dbp90_lag6,
            delta_dbp90_lag12,
            delta_dbp_sd_lag1,
            delta_dbp_sd_lag6,
            delta_dbp_sd_lag12,
            {{
                forward_filled(
                    "spo2_10",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as spo2_10,
            {{
                forward_filled(
                    "spo2_50",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as spo2_50,
            {{
                forward_filled(
                    "spo2_90",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as spo2_90,
            {{
                forward_filled(
                    "spo2_sd",
                    2,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as spo2_sd,
            delta_spo2_10_lag1,
            delta_spo2_10_lag6,
            delta_spo2_10_lag12,
            delta_spo2_50_lag1,
            delta_spo2_50_lag6,
            delta_spo2_50_lag12,
            delta_spo2_90_lag1,
            delta_spo2_90_lag6,
            delta_spo2_90_lag12,
            delta_spo2_sd_lag1,
            delta_spo2_sd_lag6,
            delta_spo2_sd_lag12,
            {{
                forward_filled(
                    "bp_invasive",
                    4,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as bp_invasive,

            -- 15_laboratory_tests
            -- 26hまで遡る
            {{
                forward_filled(
                    "wbc",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as wbc,
            {{
                forward_filled(
                    "hemoglobin",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as hemoglobin,
            {{
                forward_filled(
                    "platelet",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as platelet,
            {{
                forward_filled(
                    "sodium",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as sodium,
            {{
                forward_filled(
                    "creatinine",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as creatinine,
            {{
                forward_filled(
                    "potassium",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as potassium,
            {{
                forward_filled(
                    "aspartate_aminotransferase",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as aspartate_aminotransferase,
            {{
                forward_filled(
                    "blood_urea_nitrogen",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as blood_urea_nitrogen,
            {{
                forward_filled(
                    "alanine_aminotransferase",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as alanine_aminotransferase,
            {{
                forward_filled(
                    "total_bilirubin",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as total_bilirubin,
            {{
                forward_filled(
                    "crp",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as crp,
            {{
                forward_filled(
                    "albumin",
                    26,
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as albumin,

            -- 18_rass
            {{
                forward_filled(
                    "rass_score",
                    "unbounded",
                    partition_keys=["icu_stay_id"],
                    order=["time_window_index"],
                )
            }} as rass_score,

            -- 19_sofa
            -- １つのtime_window毎に１レコードあるので補完は不要
            respiration_24hours,
            coagulation_24hours,
            liver_24hours,
            cardiovascular_24hours,
            cns_24hours,
            renal_24hours,
            sofa_24hours,

            -- input
            input_amount,
            cumsum_in,

            -- output
            window_total_output,
            cumsum_out,

            -- cumsum_balance
            cumsum_balance,

            -- 22_drug active ingredients
            active_ingredient_propofol,
            active_ingredient_noradrenaline,
            active_ingredient_fentanyl,
            active_ingredient_dexmedetomidine,
            active_ingredient_dopamine,
            active_ingredient_midazolam,
            active_ingredient_dobutamine,
            active_ingredient_landiolol,
            active_ingredient_vasopressin,
            active_ingredient_remifentanil,
            active_ingredient_thiamylal,
            active_ingredient_adrenaline,
            active_ingredient_vecuronium,
            active_ingredient_rocuronium,

            -- 24_transfusion
            transfusion_rbc,
            transfusion_platelet,
            transfusion_plasma,
            transfusion_albumin

        from `medicu-production.research_nms_delirium_2025.33_derived_features`
    )

select *
from forward_filling
