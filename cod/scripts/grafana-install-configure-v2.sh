#!/usr/bin/env bash
#
# Copyright (c) 2023 Cloudera, Inc. All rights reserved.
#

dashboard_url="https://raw.githubusercontent.com/cloudera/observability/main/cod/dashboards/"
dashboard_files_str="Hbase.json,Hdfs.json,Zookeeper.json"

if [[ "$dashboard_url" =~ ^\{ ]] ||
   [[ "$dashboard_files_str" =~ ^\{ ]];
then
    dashboard_not_specified=true
fi

if [[ -n "$dashboard_url" ]] &&
   [[ -n "$dashboard_files_str" ]] &&
   [[ -z "$dashboard_not_specified" ]];
then
  need_to_configure_dashboard=true
fi

host_fqdn=$(hostname --fqdn)
hostname=$(hostname)
cod_str="${hostname/-gateway0/}"
echo extracted string: "${cod_str}"
cm_url="https://$host_fqdn/$cod_str/cdp-proxy"

gr_dsyaml_str=$(cat <<-END
apiVersion: 1
datasources:
  - name: ClouderaManager
    type: foursquare-clouderamanager-datasource
    uid: PCBD112296461D5A7
    access: proxy
    orgId: 1
    url: $cm_url
    basicAuth: false
    withCredentials: false
    isDefault: true
    jsonData:
      tlsSkipVerify: true
      cmAPIVersion: 'v6-10'
    version: 1
    readOnly: false
    accessControl:
      alert.instances.external:read: true
      alert.instances.external:write: true
      alert.notifications.external:read: true
      alert.notifications.external:write: true
      alert.rules.external:read: true
      alert.rules.external:write: true
      datasources.id:read: true
      datasources:delete: true
      datasources:query: true
      datasources:read: true
      datasources:write: true
  - name: CloudWatch
    type: cloudwatch
    uid: P034F075C744B399F
    access: proxy
    basicAuth: false
    withCredentials: false
    isDefault: false
    jsonData:
      authType: default
      defaultRegion: default
    version: 1
    readOnly: false
    accessControl:
      alert.instances.external:read: true
      alert.instances.external:write: true
      alert.notifications.external:read: true
      alert.notifications.external:write: true
      alert.rules.external:read: true
      alert.rules.external:write: true
      datasources.id:read: true
      datasources:delete: true
      datasources:query: true
      datasources:read: true
      datasources:write: true
END
)

grafana_dir="/var/lib/grafana"
plugins_dir="$grafana_dir/plugins"
prvsn_dir="$grafana_dir/provisioning"
conf_dir="/etc/grafana"
dashboard_dir="$grafana_dir/dashboards"

gr_conf_str=$(cat <<-END
[server]
protocol = http
root_url = %(protocol)s://$host_fqdn:3000/grafana
[users]
allow_sign_up = true
auto_assign_org_role = Editor
default_theme = light
[auth.proxy]
enabled = true
header_name = SM_USER
header_property = username
auto_sign_up = true
ldap_sync_ttl = 60
whitelist =
headers =
[paths]
provisioning = $prvsn_dir
plugins = $plugins_dir
[auth]
disable_login_form: true
disable_signout_menu: true
END
)

gr_dbyaml_str=$(cat <<-END
apiVersion: 1
providers:
  - name: Default
    folder: Cloudera
    type: file
    options:
      path:
        $dashboard_dir
END
)

yum install grafana -y https://dl.grafana.com/oss/release/grafana-9.5.3-1.x86_64.rpm || echo "ERROR: Failed to install grafana."
grafana-cli --pluginsDir "$plugins_dir" plugins install foursquare-clouderamanager-datasource || echo "ERROR: Failed to install cm plugin on grafana."
mv $conf_dir/grafana.ini $conf_dir/grafana.ini_backup

printf "%s" "$gr_conf_str" > $conf_dir/grafana.ini
chown root:grafana $conf_dir/grafana.ini

prv_ds_dir="$prvsn_dir/datasources"
mkdir -p $prv_ds_dir
printf "%s" "$gr_dsyaml_str"> $prv_ds_dir/datasource.yaml

mkdir -p $dashboard_dir

if [[ -n "$need_to_configure_dashboard" ]]; then
  IFS=','
  read -ra arr <<< "$dashboard_files_str"
  for val in "${arr[@]}";
  do
    wget -O - $dashboard_url$val > $dashboard_dir/$val
  done
fi

prv_db_dir="$prvsn_dir/dashboards"
mkdir -p $prv_db_dir
printf "%s" "$gr_dbyaml_str" > $prv_db_dir/default.yaml

chown grafana:grafana -R $plugins_dir/
chown grafana:grafana -R $dashboard_dir/
chown grafana:grafana -R $prvsn_dir/
chmod 755 $dashboard_dir/*

systemctl daemon-reload
systemctl enable --now grafana-server || echo "ERROR: Failed to start grafana."
