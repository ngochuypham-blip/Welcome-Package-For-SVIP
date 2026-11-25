
/*
data linegae:

```mermaid
flowchart TD
    %% Source Tables
    subgraph Sources ["Raw Source Tables"]
        SRC_CLAIM["shopeepay.ods__shopeepay_promotion_hub_vn_db__<br/>user_reward_instance_tab__df"]
        SRC_CLICK["shopeepay.mart_dwd_traffic_click_hi__vn"]
        SRC_IMP["shopeepay.mart_dwd_traffic_impression_hi__vn"]
        SRC_VIEW["shopeepay.mart_dwd_traffic_view_hi__vn"]
    end

    %% Bronze Layer
    subgraph Bronze ["Bronze Layer (Extraction & Union)"]
        BRZ_CLAIM["brz_01_user_claim_welcome_package_successful<br/><i>Filter: reward_status=2, extra_info like '%svip%'</i>"]
        BRZ_CLICK["brz_01_user_click_for_svip_free_trial_3_months<br/><i>Filter: app_id in (0,3), operation='click'</i>"]
        BRZ_IMP["brz_01_user_impression_for_svip_free_trial_3_months<br/><i>Filter: app_id in (0,3), operation='impression'</i>"]
        BRZ_VIEW["brz_01_user_view_for_svip_free_trial_3_months<br/><i>Filter: app_id in (0,3), operation='view'</i>"]
        BRZ_UNION["brz_02_combine_all_traffics_into_one_table<br/><i>UNION ALL</i>"]
    end

    %% Silver Layer
    subgraph Silver ["Silver Layer (Aggregation)"]
        SLV_TRAFFIC["slv_01_traffic_agg<br/><i>Grain: (app_id, operation, grass_date)</i>"]
        SLV_CLAIM["slv_01_claim_agg<br/><i>Grain: (grass_date)</i>"]
    end

    %% Gold Layer & Output
    subgraph Gold ["Gold Layer & Output"]
        GLD_SUM["gld_01_summary<br/><i>Pivot operations + LEFT JOIN on grass_date</i>"]
        FINAL(["Final Output<br/><i>ORDER BY grass_date, app_id LIMIT 100</i>"])
    end

    %% Edges
    SRC_CLAIM --> BRZ_CLAIM
    SRC_CLICK --> BRZ_CLICK
    SRC_IMP --> BRZ_IMP
    SRC_VIEW --> BRZ_VIEW

    BRZ_CLICK --> BRZ_UNION
    BRZ_IMP --> BRZ_UNION
    BRZ_VIEW --> BRZ_UNION

    BRZ_UNION --> SLV_TRAFFIC
    BRZ_CLAIM --> SLV_CLAIM

    SLV_TRAFFIC -->|"Driver (Left)"| GLD_SUM
    SLV_CLAIM -->|"LEFT JOIN ON grass_date"| GLD_SUM

    GLD_SUM --> FINAL
```
*/

/*
objective: 
    - Find all the users who have claimed the SVIP free trial package.
    - Number of clicks 
    - Number of views
    - Number of impressions
        -> following the SVIP free-trial package for the next 3 months.
*/

with brz_01_user_claim_welcome_package_successful as (
/*
commented by: ngochuy.pham
notation:
    reward_status = 2 (means: `successful` status)
objective: 
    find all the users that claim the %SVIP% package
*/
    select 
        user_id as shopeepay_user_id,
        reward_package_id,
        reward_type,
        reward_status,
        from_unixtime(create_time) as create_time,
        json_extract(extra_info,'$.request_id') as request_id,
        reward_item_id
    from shopeepay.ods__shopeepay_promotion_hub_vn_db__user_reward_instance_tab__df
    where 1=1
        and reward_status = 2
        and lower(extra_info) like '%svip%'
),
brz_01_user_click_for_svip_free_trial_3_months as (
/*
commented by: ngochuy.pham
view-screen: view in TMS:
    - track-url: https://trafficsuite.shopee.io/tms/tracker/trackerLibrary?appId=3&comEndDate=2026-11-11&comStartDate=2026-11-05&direction=ASC&endDate=2026-11-18&isAdvanced=false&operation=click&page=1&pageSize=100&pageType=shopee_pay_promo_welcome_package_landing_page&quickFilter=%7B%7D&searchMode=BASIC&sortBy=target_type&startDate=2026-11-12&timezone=LOCAL

Notation:
    app_id (application_id)

Logic:
    - app_id in (0,3) --> where 0 = shopee, 3 = shopeepay
    - collect 'click' only
    - page_type | page_section0 | target_type -- following the TMS above
*/
    select 
        user_id as shopeepay_user_id,
        app_id,
        session_id,
        event_id,
        operation,
        json_extract(data, '$.user_claim_status') as claim_status,
        json_extract(data, '$.kyc_status') as kyc_status,
        json_extract(data, '$.reward_package_id') as reward_package_id,
        json_extract(data, '$.shopee_uid') as shopee_user_id,
        grass_date
    from shopeepay.mart_dwd_traffic_click_hi__vn
    where 1=1
        and app_id in (0,3)
        and env = 'live'
        and operation = 'click'
        and page_type = 'shopee_pay_promo_welcome_package_landing_page'
        and page_section0 = 'voucher_card_list'
        and target_type = 'activate_button'
),
brz_01_user_impression_for_svip_free_trial_3_months as (
/*
commented by: ngochuy.pham
view-screen: view in TMS:
    - track-url: https://trafficsuite.shopee.io/tms/tracker/trackerLibrary?appId=3&comEndDate=2026-11-11&comStartDate=2026-11-05&direction=ASC&endDate=2026-11-18&isAdvanced=false&operation=click&page=1&pageSize=100&pageType=shopee_pay_promo_welcome_package_landing_page&quickFilter=%7B%7D&searchMode=BASIC&sortBy=target_type&startDate=2026-11-12&timezone=LOCAL

Notation:
    app_id (application_id)

Logic:
    - app_id in (0,3) --> where 0 = shopee, 3 = shopeepay
    - collect 'impression' only
    - page_type | page_section0 | target_type -- following the TMS above

*/
    select 
        user_id as shopeepay_user_id,
        app_id,
        session_id,
        event_id,
        operation,
        json_extract(data, '$.user_claim_status') as claim_status,
        json_extract(data, '$.kyc_status') as kyc_status,
        json_extract(data, '$.reward_package_id') as reward_package_id,
        json_extract(data, '$.shopee_uid') as shopee_user_id,
        grass_date
    from shopeepay.mart_dwd_traffic_impression_hi__vn
    where 1=1
        and app_id in (0,3)
        and env = 'live'
        and operation = 'impression'
        and page_type = 'shopee_pay_promo_welcome_package_landing_page'
        and page_section0 = 'voucher_card_list'
        and target_type = 'activate_button'
),
brz_01_user_view_for_svip_free_trial_3_months as (
/*
commented by: ngochuy.pham
view-screen: view in TMS:
    - track-url: https://trafficsuite.shopee.io/tms/tracker/trackerLibrary?appId=3&comEndDate=2026-11-11&comStartDate=2026-11-05&direction=ASC&endDate=2026-11-18&isAdvanced=false&operation=click&page=1&pageSize=100&pageType=shopee_pay_promo_welcome_package_landing_page&quickFilter=%7B%7D&searchMode=BASIC&sortBy=target_type&startDate=2026-11-12&timezone=LOCAL

Notation:
    app_id (application_id)

Logic:
    - app_id in (0,3) --> where 0 = shopee, 3 = shopeepay
    - collect 'view' only
    - page_type | page_section0 | target_type -- following the TMS above
*/
    select 
        user_id as shopeepay_user_id,
        app_id,
        session_id,
        event_id,
        operation,
        json_extract(data, '$.user_claim_status') as claim_status,
        json_extract(data, '$.kyc_status') as kyc_status,
        json_extract(data, '$.reward_package_id') as reward_package_id,
        json_extract(data, '$.shopee_uid') as shopee_user_id,
        grass_date
    from shopeepay.mart_dwd_traffic_view_hi__vn
    where 1=1
        and app_id in (0,3)
        and env = 'live'
        and operation = 'view'
        and page_type = 'shopee_pay_promo_welcome_package_landing_page'
        and page_section0 = 'voucher_card_list'
        and target_type = 'activate_button'
),
brz_02_combine_all_traffics_into_one_table as (
    select 
        shopeepay_user_id,
        shopee_user_id,
        app_id,
        session_id,
        event_id,
        operation,
        claim_status,
        kyc_status,
        reward_package_id,
        grass_date
    from brz_01_user_click_for_svip_free_trial_3_months

    union all 

    select 
        shopeepay_user_id,
        shopee_user_id,
        app_id,
        session_id,
        event_id,
        operation,
        claim_status,
        kyc_status,
        reward_package_id,
        grass_date
    from brz_01_user_impression_for_svip_free_trial_3_months

    union all 

    select 
        shopeepay_user_id,
        shopee_user_id,
        app_id,
        session_id,
        event_id,
        operation,
        claim_status,
        kyc_status,
        reward_package_id,
        grass_date
    from brz_01_user_view_for_svip_free_trial_3_months
),
slv_01_traffic_agg as (
/*
commented by: ngochuy.pham
objective:
    aggregate traffic events by app_id, operation, grass_date
    => distinct user count (num_user) and total event count (num_event) per group
*/
    select
        app_id,
        operation,
        grass_date,
        count(distinct shopeepay_user_id) as num_user,
        count(*) as num_event
    from brz_02_combine_all_traffics_into_one_table
    group by
        app_id,
        operation,
        grass_date
),
slv_01_claim_agg as (
/*
commented by: ngochuy.pham
objective:
    aggregate successful claim events by grass_date
note:
    app_id and operation are NOT available in the claim source table
    => cast(create_time as date) is used as proxy for grass_date
*/
    select
        cast(create_time as date) as grass_date,
        count(distinct shopeepay_user_id) as num_user_claim_successfully,
        count(*) as num_claim_successfully
    from brz_01_user_claim_welcome_package_successful
    group by
        cast(create_time as date)
),
gld_01_summary as (
/*
commented by: ngochuy.pham
objective:
    gold layer - wide-format summary per (app_id, grass_date)
    pivot traffic metrics (click / view / impression) using conditional aggregation
    then left join claim metrics on grass_date
note:
    slv_01_traffic_agg is the driver (grouped by app_id, operation, grass_date per silver convention)
    slv_01_claim_agg has no app_id => claim counts repeat for each app_id on the same date (expected)
*/
    select
        t.app_id,
        t.grass_date,
        sum(
            case 
                when t.operation = 'click' then t.num_user  
            else 0 
            end
        ) as num_user_click,
        sum(
            case 
                when t.operation = 'click' then t.num_event 
            else 0 
            end
        ) as num_click,
        sum(
            case 
                when t.operation = 'view' then t.num_user  
            else 0 
            end
        ) as num_user_view,
        sum(
            case 
                when t.operation = 'view' then t.num_event 
            else 0 
            end
        ) as num_view,
        sum(
            case 
                when t.operation = 'impression' then t.num_user  
            else 0 
            end
        ) as num_user_impression,
        sum(
            case 
                when t.operation = 'impression' then t.num_event 
            else 0 
            end
        ) as num_impression,
        max(c.num_user_claim_successfully) as num_user_claim_successfully,
        max(c.num_claim_successfully) as num_claim_successfully
    from slv_01_traffic_agg t
    left join slv_01_claim_agg c
        on t.grass_date = c.grass_date
    group by
        t.app_id,
        t.grass_date
)
select
    grass_date,
    app_id,
    num_user_click,
    num_click,
    num_user_view,
    num_view,
    num_user_impression,
    num_impression,
    num_user_claim_successfully,
    num_claim_successfully
from gld_01_summary
order by
    grass_date,
    app_id
limit 
    100
