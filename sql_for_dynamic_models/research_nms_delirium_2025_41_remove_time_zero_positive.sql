-- 12/14
select 
* except(delirium_time_index)
from `medicu-production.research_nms_delirium_2025.34_forward_filling`
where delirium_time_index != 0 or delirium_time_index is null