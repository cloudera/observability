# Cloudera Data Platform Operational Database (COD) Grafana Dashboards
This repository contains dashboard files for COD Grafana. When a COD cluster is created with the Grafana feature enabled these Grafana dashboards are automatically installed. The instructions on how to install a COD cluster with Grafana and examples of the Grafana dashboards are available in the [Enabling Grafana dashboard in COD](https://docs.cloudera.com/operational-database/cloud/managing-database/topics/cod-monitor-metrics-grafana.html) documentation.

## Prerequisite for manual installation steps
When installing Grafana dashboards manually, verify the following Grafana plugins exist.

1. Install the [CM foursquare plugin](https://grafana.com/grafana/plugins/foursquare-clouderamanager-datasource/) in the Grafana instance.
2. Install the Cloudwatch plugin in the Grafana instance to enable AWS S3 dashboards.

> **_NOTE:_** If you have already enabled Grafana as part of the COD creation process, you may not need to follow the prerequisite requisites.

## Manual Installation Steps
Follow these steps for manual installation of the COD dashboards to your Grafana instance.

1. Download the dashboard json files in your local computer.
2. Open your Grafana portal and go to Dashboard page.
3. Choose your folder where you want to install the dashboards.
4. Click New and select Import in the drop down menu.
5. Upload the dashboard JSON files you have downloaded earlier one by one.
6. After uploading the files you can see the dashboards have created in your chosen folder.
7. Select one of them to see the graphs.
