view: cloud_billing_combined{
  derived_table: {
    datagroup_trigger: daily
    partition_keys: ["invoice_month"]
    sql:
      SELECT
        usage_start_date,
        invoice_month,
        cost_center,
        apmid_2,
        project,
        service,
        environment_clean,
        sku_category,
        sku_id,
        sku,
        cloud_source,
        final_cost,
        total_net_cost
            FROM
              (
              SELECT
                usage_start_date,
                PARSE_DATE("%Y-%m",invoice_month) as invoice_month,
                cost_center,
                apmid_2,
                project,
                service,
                environment_clean,
                sku_category,
                sku_id,
                sku,
                "GCP" cloud_source,
                final_cost,
                total_net_cost,
              FROM
                ${cloud_billing_combined_gcp_base.SQL_TABLE_NAME} as combined_costs_gcp_base
              )

              UNION ALL

              (
              SELECT
                aws_billing_aggregate_table.line_item_usage_date AS aws_billing_aggregate_table_line_item_usage_date,
                CAST(aws_billing_aggregate_table.billing_period_start_date as DATE) AS aws_billing_aggregate_table_invoice_month,
                aws_billing_aggregate_table.cost_center AS aws_billing_aggregate_table_cost_center,
                aws_billing_aggregate_table.apmid AS aws_billing_aggregate_table_apmid,
                aws_billing_aggregate_table.alias AS aws_billing_aggregate_table_alias,
                aws_billing_aggregate_table.product_code AS aws_billing_aggregate_table_product_code,
                aws_billing_aggregate_table.environment_clean AS aws_billing_aggregate_table_environment_clean,
                aws_billing_aggregate_table.productfamily AS aws_billing_aggregate_table_productfamily,
                aws_billing_aggregate_table.product_sku AS aws_billing_aggregate_table_product_sku,
                aws_billing_aggregate_table.description AS aws_billing_aggregate_table_description,
                "AWS" cloud_source,
                COALESCE(SUM(aws_billing_aggregate_table.final_costs ), 0) AS aws_billing_aggregate_table_final_costs,
                COALESCE(SUM(aws_billing_aggregate_table.total_unblended_cost ), 0) AS aws_billing_aggregate_table_total_unblended_cost
              FROM
                ${aws_billing_aggregate_table.SQL_TABLE_NAME} AS aws_billing_aggregate_table
              GROUP BY 1,2,3,4,5,6,7,8,9,10,11
              ) ;;
  }

  dimension_group: usage_start {
    #drill_fields: [project,environment.environment,resource.resource,sku_category,sku,pricing_unit]
    timeframes: [raw,date,day_of_week_index,day_of_month,day_of_year,week,week_of_year,month,month_name,quarter,quarter_of_year,year]
    type: time
    sql: cast(${TABLE}.usage_start_date as timestamp) ;;
    convert_tz: no
  }
  dimension_group: invoice_month {
    type: time
    datatype: date
    timeframes: [raw,month]
    sql: ${TABLE}.invoice_month ;;
  }
  filter: invoice_month_filter {
    type: string
    suggest_explore: month_selection_filter
    suggest_dimension: month_selection_filter.month_select
  }
  dimension: cost_center {}
  dimension: apmid_2 {
    label: "APMID"
  }
  dimension: project {}
  dimension: service {}
  dimension: environment_clean {
    label: "Environment"
    description: "The environment values standardized. EX: prod and production both become Production"
  }
  dimension: sku_category {
    description: "Provides an additional layer of granularity above SKU"
  }
  dimension: sku_id {}
  dimension: sku {}
  dimension: final_cost {
    hidden: yes
    description: "Total costs, less credits, plus support and tax allocation"
    value_format: "$#,##0.00"
    type: number
  }
  dimension: total_net_cost {
    hidden: yes
    description: "The total cost associated to an SKU, between Start Date and End Date, less credits"
    value_format: "$#,##0.00"
    type: number
  }
  dimension: cloud_source {
    type: string
    sql: ${TABLE}.cloud_source ;;
  }
  measure: net_cost{
    label: "Total Net Cost"
    type: sum
    sql: ${total_net_cost} ;;
    value_format_name: usd_0
  }
  measure: total_final_cost{
    label: "Final Cost"
    type: sum
    sql: ${final_cost} ;;
    value_format_name: usd_0
  }
}

view: cloud_billing_combined_gcp_base{
  derived_table: {
    datagroup_trigger: daily
    #https://cardinalhealthnonprod.cloud.looker.com/explore/cloud_billing/billing_aggregated?qid=gLiEjzUBmp96w4Lq1mawze
    explore_source: billing_aggregated {
      column: usage_start_date {}
      column: invoice_month {}
      column: cost_center {}
      column: apmid_2 {}
      column: project {}
      column: service {}
      column: environment_clean {}
      column: sku_category {}
      column: sku_id {}
      column: sku {}
      column: final_cost {}
      column: total_net_cost {}
    }
  }
}
