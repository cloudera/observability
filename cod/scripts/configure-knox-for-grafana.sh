#!/usr/bin/env bash
#
# Copyright (c) 2023 Cloudera, Inc. All rights reserved.
#

cdh_loc="$(find /opt/cloudera/parcels/ -name CDH-* | tail -1)"
service_loc="$cdh_loc/lib/knox/data/services"
j2topology_loc="/srv/salt/gateway/config/cm"
j2topology_orig_file="topology.xml.j2"
j2topology_backup_file="topology.xml.j2-backup"

topology_loc="/var/lib/knox/cloudbreak_resources/topologies"
topology_orig_file="cdp-proxy.xml"
topology_backup_file="cdp-proxy.xml-backup"

host_fqdn=$(hostname --fqdn)

service_xml_str=$(cat <<-END
<service role="GRAFANA" name="grafana" version="1.0.0">
  <metadata>
     <context>/../../grafanacod/dashboards</context>
     <description>Grafana</description>
     <shortDesc>GRAFANA</shortDesc>
     <type>UI</type>
  </metadata>
  <routes>
    <route path="/grafanacod/"></route>
    <route path="/grafanacod/**">
    </route>
  </routes>
  <dispatch classname="org.apache.knox.gateway.dispatch.HeaderPreAuthFederationDispatch" />
</service>
END
)

rewrite_xml_str=$(cat <<-END
<rules>
  <rule dir="IN" name="GRAFANA/grafanacod/root" pattern="*://*:*/**/grafanacod/">
    <rewrite template="{\$serviceUrl[GRAFANA]}/"/>
  </rule>
  <rule dir="IN" name="GRAFANA/grafanacod/inbound" pattern="*://*:*/**/grafanacod/{path=**}?{**}">
    <rewrite template="{\$serviceUrl[GRAFANA]}/{path=**}?{**}"/>
  </rule>
</rules>
END
)

if [ -d "$service_loc" ]; then
  grafana_dir="$service_loc/grafana/1.0.0"
  if [ -d "$grafana_dir" ]; then
    echo "Directory $grafana_dir already exists, do nothing"
  else
    echo "Installing knox service configs for grafana"
    mkdir -p $grafana_dir

    rewrite_file="rewrite.xml"
    service_file="service.xml"

    printf "%s" "$service_xml_str" > $grafana_dir/$service_file
    printf "%s" "$rewrite_xml_str" > $grafana_dir/$rewrite_file
    chmod 755 -R $grafana_dir/..
    chown cloudera-scm:cloudera-scm -R $grafana_dir/..
  fi
fi

if [ -d $j2topology_loc ]; then
  if [ -s $j2topology_loc/$j2topology_orig_file ]; then
    exists=$(grep -c GRAFANA $j2topology_loc/$j2topology_orig_file)
    if [ $exists -gt 0 ]; then
      echo "GRAFANA already exists, do nothing"
    else
      echo "Adding GRAFANA service in the cdp-proxy topology"
      mv $j2topology_loc/$j2topology_orig_file $j2topology_loc/$j2topology_backup_file

      sed "\#^</topology>#i\
          <service>\
            <role>GRAFANA</role>\
            <url>http://$host_fqdn:3000</url>\
          </service>\
          " $j2topology_loc/$j2topology_backup_file > $j2topology_loc/$j2topology_orig_file
      chmod 644 $j2topology_loc/$j2topology_orig_file
    fi
  fi
fi

if [ -d $topology_loc ]; then
  if [ -s $topology_loc/$topology_orig_file ]; then
    exists=$(grep -c GRAFANA $topology_loc/$topology_orig_file)
    if [ $exists -gt 0 ]; then
      echo "GRAFANA already exists, do nothing"
    else
      echo "Adding GRAFANA service in the cdp-proxy topology in the active directory"
      mv $topology_loc/$topology_orig_file $topology_loc/$topology_backup_file

      sed "\#^</topology>#i\
          <service>\
            <role>GRAFANA</role>\
            <url>http://$host_fqdn:3000</url>\
          </service>\
          " $topology_loc/$topology_backup_file > $topology_loc/$topology_orig_file
      chmod 644 $topology_loc/$topology_orig_file
    fi
  fi
fi
