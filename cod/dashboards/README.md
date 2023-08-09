## Grafana Dashboards
This repository contains dashboard files for COD Grafana instances to be consumed. Bydefault when COD instances are created, enabling Grafana, these files are automatically installed by the installation scripts and Grafana Dashboards will be ready for use.

## Pre Requisites for manual installation steps
> **_NOTE:_** If you have already enabled grafana as part of the COD creation process, you might not need to follow the pre requisites. But these dashboard files will only work on the below plugins so it is good to verify.

1. CM foursquare plugin should be installed and configured [https://grafana.com/grafana/plugins/foursquare-clouderamanager-datasource/]
2. If you want to install AWS S3 dasboard then Cloudwatch plugin should be configured.

## Manual Installaiton Steps
If you need to install these files manually in your grafana instances then follow the below steps

1. Download the json files in your local computer
2. Open your Grafana portal and goto Dashboard page.
3. Choose your folder where you want to install the dasboards.
4. Click New and select Import in the dropdown menu.
5. Upload the dashboard JSON files you have downloaded earlier one by one.
6. After uploading the files you can see the dashboards have created in your chosen folder.
7. You can select one of them to see the graphs.
