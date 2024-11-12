with CTE1 as (
select 													-- вибираємо дані з ФБ
	fabd.ad_date,
	fabd.url_parameters ,
	fc.campaign_name,
	fa.adset_name,
	coalesce (fabd.impressions,	0) as impressions, 		-- захист від NULL.
	coalesce (fabd.spend, 0) as spend,	
	coalesce (fabd.reach, 0) as reach,
	coalesce (fabd.clicks, 0) as clicks,
	coalesce (fabd.leads, 0) as leads,
	coalesce (fabd.value, 0) as value,
	'Facebook' as source
from
	facebook_ads_basic_daily fabd 
left join facebook_adset fa on 							-- джойним Адсети
	fa.adset_id = fabd.adset_id
left join facebook_campaign fc on 						-- джойним Кампейни
	fc.campaign_id = fabd.campaign_id 
),
CTE2 as (
select 													-- вибираємо дані з Гугл
	GABD.ad_date ,
	gabd.url_parameters,
	GABD.campaign_name ,
	GABD.adset_name ,
	coalesce (gabd.impressions,	0) as impressions,
	coalesce (gabd.spend, 0) as spend,	
	coalesce (gabd.reach, 0) as reach,
	coalesce (gabd.clicks, 0) as clicks,
	coalesce (gabd.leads, 0) as leads,
	coalesce (gabd.value, 0) as value,
	'Google' as source
from
	google_ads_basic_daily GABD
union all												-- ліпимо докупи ФБ та Гугл
select
	cte1.ad_date,
	cte1.url_parameters,
	cte1.campaign_name,
	cte1.adset_name,
	cte1.impressions,
	cte1.spend,
	cte1.reach,
	cte1.clicks,
	cte1.leads,
	cte1.value,
	source
from
	CTE1
),
CTE3 as
(
select
	date(DATE_TRUNC('month', ad_date)) as ad_month,												-- згортаємо дні у місяці
	nullif(lower(SUBSTRING(url_parameters from 'utm_campaign=([^&]+)')),'nan') as utm_campaign,	-- вибираємо імена кампейнів
	-- Сумарні показники
	sum(spend) as t_spend,
	sum(impressions) as t_impressions,
	sum(clicks) as t_clicks,
	sum(value) as t_value,
	-- Метрики
	round(sum(clicks::numeric)/ nullif(sum(impressions),0)* 100,2) as CTR,
	round(sum(spend::numeric)/ nullif(sum(clicks),0),2) as CPC,
	round(sum(spend::numeric)/ nullif(sum(impressions),	0)* 1000,0) as CPM,
	round((sum(value::numeric)-sum(spend))/ nullif(sum(spend),0)* 100,0) as ROMI
from
	cte2
group by
	ad_month,
	utm_campaign
order by 
	ad_month,
	utm_campaign
)
select
	cte3.ad_month,
	c_to_l (da17_decode_url_part (utm_campaign)) as utm_campaign,		-- перетворення крякозябрів у трансліт, першу функцію стягнув в інеті, друга вже була у базі.
	cte3.t_spend,
	cte3.t_impressions,
	cte3.t_clicks,
	cte3.t_value,
	cte3.CTR, 
	round(((cte3.CTR - lag(cte3.CTR) over (partition by cte3.utm_campaign order by cte3.ad_month)) / nullif(lag(cte3.CTR) over (partition by cte3.utm_campaign order by cte3.ad_month),	0)) * 100,
	2) as CTR__diff, 	-- страшна функція, без ГПТ не повторю.
	cte3.CPC, 
	round(((cte3.CPC - lag(cte3.CPC) over (partition by cte3.utm_campaign order by cte3.ad_month)) / nullif(lag(cte3.CPC) over (partition by cte3.utm_campaign order by cte3.ad_month),	0)) * 100,
	2) as CPC_diff,
	cte3.cpm,
	round(((cte3.CPM - lag(cte3.CPM) over (partition by cte3.utm_campaign order by cte3.ad_month)) / nullif(lag(cte3.CPM) over (partition by cte3.utm_campaign order by cte3.ad_month),	0)) * 100,
	2) as CPM__diff,
	cte3.romi,
	round(((cte3.ROMI - lag(cte3.ROMI) over (partition by cte3.utm_campaign order by cte3.ad_month)) / nullif(lag(cte3.ROMI) over (partition by cte3.utm_campaign order by cte3.ad_month), 0)) * 100,
	2) as ROMI__diff
from
	CTE3
;