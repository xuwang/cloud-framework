resource "google_monitoring_alert_policy" "myapp_outage" {
    combiner = "OR"
    conditions = [
        {
        display_name = "test condition"
        condition_threshold {
            aggregations = [
            {
                alignment_period = "1200s"
                crossSeriesReducer = "REDUCE_COUNT_FALSE"
                group_by_fields = [
                    "resource.label.*"
                ]
                per_series_aligner = "ALIGN_NEXT_OLDER"
                notification_hannels = [
                    "${var.slack_channel}"
                ]
            }
            ]
            comparison = "COMPARISON_GT"
            display_name = "Generic HTTPS check on myapp.example.com at /healthz "
            duration = "300s"
            filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"myapp\" AND resource.label.host=\"myapp.example.com\" AND resource.type=\"uptime_url\""
            threshold_value = 1.0
            trigger {
                count = 1
            }
        }
        }
    ]
    display_name = "MyApp Outage"
    enabled = true
}