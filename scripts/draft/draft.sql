with brz_01_detail_user_wp as (
select 
    grass_date,
    shopeepay_user_id,
    first_login_datetime,
    last_login_datetime,
    eligible_datetime,
    claimed_datetime,
    welcome_package_id,
    welcome_package_start_datetime,
    welcome_package_end_datetime,
    welcome_package_claimable_duration
from shopeepay.dws_promo_user_welcome_package_detail_di__vn
where 1=1
    -- and grass_date = '2026-11-18'
    and is_reach_homepage = 1
    and is_eligible = 1
    and is_landing_page_claim_click = 1 
    and is_full_kyc_completed = 1
    and is_claim_success = 1
),
brz_01_detail_uid_spp_shp as (
select 
    shopeepay_user_id,
    shopee_user_id
from dev_vnapbi_general.dim_spp_user_account_flag_vn_tbl_dl_all_user
where 1=1
-- and shopee_user_name = 'lddbwuqyoi';
    -- and shopeepay_user_id = 675549743775237
    -- and shopee_user_id = 6431493520
),
brz_01_svip_subscription as (
select 
    grass_date,
    plan_id,
    user_id as shopee_user_id,
    is_svip_active
from mp_user.dim_svip_user__vn_live
where 1=1
    -- and grass_date = date'2026-11-18'
    and plan_id = 'shopee_vip_3_month_one_time_payment_subscription_vn_v1'
    and is_svip_active = 1
),
slv_01_mapping_user_plan as (
select
    brz_01_wp.grass_date,
    brz_01_wp.shopeepay_user_id,
    
    brz_01_uid.shopee_user_id,
    
    brz_01_wp.first_login_datetime,
    brz_01_wp.last_login_datetime,
    brz_01_wp.eligible_datetime,
    brz_01_wp.claimed_datetime,
    brz_01_wp.welcome_package_id,
    brz_01_wp.welcome_package_start_datetime,
    brz_01_wp.welcome_package_end_datetime,
    brz_01_wp.welcome_package_claimable_duration
from brz_01_detail_user_wp brz_01_wp
join brz_01_detail_uid_spp_shp brz_01_uid
    on brz_01_wp.shopeepay_user_id = brz_01_uid.shopeepay_user_id
),
slv_02_mapping_user_plan_with_svip as (
select 
    slv_01.grass_date,
    slv_01.shopeepay_user_id,
    slv_01.shopee_user_id,
    slv_01.first_login_datetime,
    slv_01.last_login_datetime,
    slv_01.eligible_datetime,
    slv_01.claimed_datetime,
    slv_01.welcome_package_id,
    slv_01.welcome_package_start_datetime,
    slv_01.welcome_package_end_datetime,
    slv_01.welcome_package_claimable_duration,
    coalesce(brz_01_svip.is_svip_active, 0) as is_svip_active
from slv_01_mapping_user_plan slv_01
join brz_01_svip_subscription brz_01_svip
    on slv_01.shopee_user_id = brz_01_svip.shopee_user_id
    and cast(slv_01.grass_date as date) = cast(brz_01_svip.grass_date as date)
)
select 
    count(distinct shopeepay_user_id) as total_shopeepay_user
from slv_02_mapping_user_plan_with_svip
where 1=1;
    -- and shopeepay_user_id = 324668765;