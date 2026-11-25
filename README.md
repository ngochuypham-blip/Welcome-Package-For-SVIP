# Tracking Traffic `SVIP` that include in `Welcome Package`

> script: [tracking welcome package - svip](scripts/welcome_package_for_svip_tracking/tmp_traffic_svip_with_welcome_package.sql)

## Objective:

Find all the users who have claimed the SVIP free trial package.
    - Number of clicks 
    - Number of views
    - Number of impressions
   
**Note:** all above metrics must follow the `SVIP free-trial welcome-package`.

## Asset:

**data traffic click**:

* type: `data-warehouse-detail`

* schema: `shopeepay`

* name: `dwd_traffic_click_hi__vn`

**data traffic impression**:

* type: `data-warehouse-detail`

* schema: `shopeepay`

* name: `dwd_traffic_impression_hi__vn`

**data traffic view**:

* type: `data-warehouse-detail`

* schema: `shopeepay`

* name: `dwd_traffic_view_hi__vn`

**welcome package**:

* type: `operational-data-store`

* schema: `shopeepay`

* name: `ods__shopeepay_promotion_hub_vn_db__user_reward_instance_tab__df`

## Data-Lineage:

```mermaid
flowchart TD
    %% Source Tables
    subgraph Sources ["Raw Source Tables"]
        SRC_CLAIM["shopeepay.ods__shopeepay_promotion_hub_vn_db__user_reward_instance_tab__df"]
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

