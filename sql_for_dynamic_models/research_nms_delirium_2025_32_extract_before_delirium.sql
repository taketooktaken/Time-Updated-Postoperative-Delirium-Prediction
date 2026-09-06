-- せん妄の発生を含むtime_window及び、それ以前のtime_windowのみを抽出する。 
select 
*
from `medicu-production.research_nms_delirium_2025.31_join_all_features`
where delirium_flag < 2