with 
 get_camicu as (
      select
            icu_stay_id,
            time,
            -- 下でgroup by するために、ここで数値として持ち変える
            case 
            when camicu_score = 'positive' then 1
            else 0
            end as camicu_score
      from `medicu-beta.latest_one_icu.camicu`
      order by icu_stay_id, time
 )

select 
 icu_stay_id,
 max(camicu_score) as label_delirium_indication
from get_camicu
where
            icu_stay_id in (
                select icu_stay_id
                from
                    `medicu-production.research_nms_delirium_2025.001_eligibility_criteria`
            )
group by icu_stay_id
