with
    primary_select as (
        select *
        from `medicu-beta.latest_one_icu_derived.unioned_icu_diagnoses`
        where primary
    ),

    get_static_features as (
        -- ここでicu_diagnosisを取得する
        select 
         e.*, 
         d.diagnosis, 
         d.icd10, 
         d.category,
        --  apache2も取得
         a.apache2_score,
        -- charlsonからall variablesを取得
         c.charlson_comorbidity_index,
         c.myocardial_infarct,
         c.congestive_heart_failure,
         c.peripheral_arterial_disease,
         c.cerebrovascular_disease,
         c.dementia,
         c.chronic_pulmonary_disease,
         c.connective_tissue_disease,
         c.peptic_ulcer_disease,
         c.mild_liver_disease,
         c.diabetes_without_cc,
         c.diabetes_with_cc,
         c.paraplegia,
         c.renal_disease,
         c.malignant_cancer,
         c.severe_liver_disease,
         c.metastatic_solid_tumor,
         c.aids,
         c.age_score
        from `medicu-beta.latest_one_icu_derived.extended_icu_stays` e
        left join primary_select d using (icu_stay_id)
        left join `medicu-beta.latest_one_icu_derived.apache2` a using (icu_stay_id)
        left join `medicu-beta.latest_one_icu_derived.charlson` c using (icu_stay_id)
        where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
    ),

    one_hot_encoding_category as (
        select
            icu_stay_id,
            hospital_id,
            in_time,
            female,
            age,
            icu_admission_type,
            ideal_body_weight,
            -- 疾患カテゴリーごとのone hot encoding
            category as diagnosis_category,
            case when category = 'covid19' then 1 else 0 end as covid19,
            case when category = 'sepsis' then 1 else 0 end as sepsis,
            case when category = 'stroke' then 1 else 0 end as stroke,
            case when category = 'poisoning' then 1 else 0 end as poisoning,
            case when category = 'anaphylaxis' then 1 else 0 end as anaphylaxis,
            case when category = 'burn' then 1 else 0 end as burn,
            case
                when category = 'temperature_disorder' then 1 else 0
            end as temperature_disorder,
            case
                when category = 'hanging_asphyxiation' then 1 else 0
            end as hanging_asphyxiation,
            case when category = 'trauma' then 1 else 0 end as trauma,
            case when category = 'infection' then 1 else 0 end as infection,
            case when category = 'neoplasms' then 1 else 0 end as neoplasms,
            case when category = 'circulatory' then 1 else 0 end as circulatory,
            case when category = 'respiratory' then 1 else 0 end as respiratory,
            case when category = 'digestive' then 1 else 0 end as digestive,
            case when category = 'neurological' then 1 else 0 end as neurological,
            case when category = 'genitourinary' then 1 else 0 end as genitourinary,
            case
                when category = 'electrolyte_metabolic_disorders' then 1 else 0
            end as electrolyte_metabolic_disorders,
            case when category = 'musculoskeletal' then 1 else 0 end as musculoskeletal,
            case when category = 'psychiatric' then 1 else 0 end as psychiatric,
            case when category = 'congenital' then 1 else 0 end as congenital,
            case when category = 'null' then 1 else 0 end as undefined,
            case when category = 'other' then 1 else 0 end as other,
            icd10,
            apache2_score,
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
            age_score
        from get_static_features
    )

select
    icu_stay_id,
    hospital_id,
    timestamp_diff(in_time, timestamp_trunc(in_time, day), hour) as icu_admit_time,
    female,
    age,
    icu_admission_type,
    ideal_body_weight,
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
    apache2_score,
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
    age_score
from one_hot_encoding_category
