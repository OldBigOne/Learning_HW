with CTE1 as (
select
	fabd.ad_date,
	fabd.url_parameters ,
	fc.campaign_name,
	fa.adset_name,
	coalesce (fabd.impressions,	0) as impressions,
	coalesce (fabd.spend, 0) as spend,	
	coalesce (fabd.reach, 0) as reach,
	coalesce (fabd.clicks, 0) as clicks,
	coalesce (fabd.leads, 0) as leads,
	coalesce (fabd.value, 0) as value,
	'Facebook' as source
from
	facebook_ads_basic_daily fabd
left join facebook_adset fa on	fa.adset_id = fabd.adset_id
left join facebook_campaign fc on	fc.campaign_id = fabd.campaign_id 
),
CTE2 as (
select
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
union all
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
BDD as
(
select
	date(DATE_TRUNC('month', ad_date)) as ad_month,
	nullif(lower(SUBSTRING(url_parameters from 'utm_campaign=([^&]+)')),'nan') as utm_campaign,
	--SUMMARY
	sum(spend) as t_spend,
	sum(impressions) as t_impressions,
	sum(clicks) as t_clicks,
	sum(value) as t_value,
	--METRICS
	round(sum(clicks::numeric)/ nullif(sum(impressions),0)* 100,2) as CTR,
	round(sum(spend::numeric)/ nullif(sum(clicks),0),2) as CPC,
	round(sum(spend::numeric)/ nullif(sum(impressions),	0)* 1000,0) as CPM,
	round((sum(value::numeric)-sum(spend))/ nullif(sum(spend),0)* 100,0) as ROMI
from
	cte2
group by
	ad_month,
	utm_campaign
)
select 
CM.ad_month,
c_to_l (da17_decode_url_part (cm.utm_campaign)) as utm_campaign,
--round((cm.ctr/nullif(pm.ctr,0)*100),2) as CTR_perc,
CM.CTR as current_CTR,
pm.ctr as previous_CTR
--CM.CPM,
--CM.ROMI
from BDD as CM
left JOIN BDD as PM on CM.ad_month = PM.ad_month + INTERVAL '1 month'
;