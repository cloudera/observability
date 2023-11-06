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
root_url = %(protocol)s://$host_fqdn:3000/grafanacod
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

get_distribution() {
     lsb_dist=""
     # Every system that we officially support has /etc/os-release
     if [ -r /etc/os-release ]; then
         lsb_dist="$(. /etc/os-release && echo "$ID")"
     fi
     # Returning an empty string here should be alright since the
     # case statements don't act unless you provide an actual value
     echo "$lsb_dist"
}

install_grafana() {
    # perform some very rudimentary platform detection
    lsb_dist=$( get_distribution )
    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
    dist_version=""
    case "$lsb_dist" in
        centos|rhel|sles)
            if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
                dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
            fi
        ;;
    esac
    majorVersion=$(echo "$dist_version" | cut -f1 -d.)
    echo "$lsb_dist" "$majorVersion"

    if [ "$lsb_dist" == "rhel" ] && [ "$majorVersion" == "8" ]; then
        echo "installing for RHEL 8"
        RHEL_VERSION=$(cat /etc/redhat-release | grep -oP "[0-9\.]*")
        RHEL_VERSION=${RHEL_VERSION/.0/}
        REPO_FILE=rhel${RHEL_VERSION}_cldr_mirrors.repo
        curl https://mirror.infra.cloudera.com/repos/rhel/server/8/${RHEL_VERSION}/${REPO_FILE} > /etc/yum.repos.d/${REPO_FILE}
        yum install grafana -y https://dl.grafana.com/oss/release/grafana-9.5.3-1.x86_64.rpm || echo "ERROR: Failed to install grafana."
        rm -f /etc/yum.repos.d/${REPO_FILE}
    else
        echo "installing for RHEL <8"
        yum install grafana -y https://dl.grafana.com/oss/release/grafana-9.5.3-1.x86_64.rpm || echo "ERROR: Failed to install grafana."
    fi

}

install_grafana

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
