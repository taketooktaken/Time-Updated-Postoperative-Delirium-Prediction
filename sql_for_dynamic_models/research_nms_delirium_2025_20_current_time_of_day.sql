select 
 icu_stay_id,
 time_window_index,
 start_time,
 end_time,
 timestamp_diff(start_time, timestamp_trunc(start_time, day), hour) as current_time_of_day
from
`medicu-production.research_nms_delirium_2025.02_icu_stays_hourly`
