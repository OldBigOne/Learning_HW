with CTE1 as (
select
	fabd.ad_date,
	fc.campaign_name,
	fa.adset_name,
	fabd.impressions ,
	fabd.spend,	
	fabd.reach ,
	fabd.clicks ,
	fabd.leads,
	fabd.value,
	'Reptiloids' as source	-- sorry, i'm stressed
from
	facebook_ads_basic_daily fabd
left join facebook_adset fa on
	fa.adset_id = fabd.adset_id
left join facebook_campaign fc on
	fc.campaign_id = fabd.campaign_id 
),
CTE2 as (
select
	GABD.ad_date ,
	GABD.campaign_name ,
	GABD.adset_name ,
	GABD.spend ,
	GABD.impressions ,
	GABD.reach ,
	GABD.clicks ,
	GABD.leads ,
	GABD.value,
	'EvilCorp' as source	--still stressed
from
	google_ads_basic_daily GABD
union all
select
	ad_date,
	campaign_name,
	adset_name,
	spend,
	impressions,
	reach,
	clicks,
	leads,
	value,
	source
from
	CTE1
)
select
	cte2.ad_date,
	cte2.source,
	cte2.campaign_name,
	cte2.adset_name,
	sum(spend) as t_spend,
	sum(impressions) as t_impressions,
	sum(clicks) as t_clicks,
	sum(value) as t_value
from
	cte2
group by
	campaign_name,
	ad_date,
	source ,
	adset_name
having sum(spend)>0
order by
	ad_date,
	source,
	campaign_name,
	adset_name
;