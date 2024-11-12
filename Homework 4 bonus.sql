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
	'Reptiloids' as source
	-- sorry, i'm stressed
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
	'EvilCorp' as source
	--still stressed
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
	cte2.source,
	cte2.campaign_name,
	(sum(value::decimal)-sum(spend::decimal))/ nullif(sum(spend::decimal),
	0)* 100 as ROMI
from
	cte2
group by
	cte2.source,
	cte2.campaign_name
having
	sum(spend) > 500000
order by
	ROMI desc
--limit 11

;