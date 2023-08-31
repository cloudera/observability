# Cloudera Data Platform Operational Database (COD) Grafana Scripts
This repository contains scripts for COD to install Grafana manually.

## Ensure to consider the following aspects while enabling Grafana for COD:

1. Grafana server upgrade: COD focuses on utilizing the existing version to meet the requirements and the upgrade of the Grafana server is not within the scope of this solution.
2. Manual dashboard updates: You must explicitly download the updated dashboards from the Cloudera Public repository. This allows flexibility and ensures you have the most up-to-date dashboard versions whenever necessary.
3. OS support: The existing solution works on Red Hat, CentOS, RHEL, and Fedora OS because of an RPM-based installation. That is why COD does not allow you to install Grafana with custom images having different OS.
4. Data Lake metrics support: COD does not include the Data Lake metrics in this solution. Only individual COD (Data Hub) metrics appear in the Grafana dashboard.
5. HA Knox support: Currently, COD only supports a single Gateway host with a single Knox Gateway.
6. Foursquare plugin support: The Cloudera Manager foursquare datasource plugin does not support sending alerts. That is why alerts cannot be created on HBase, HDFS, and ZooKeeper dashboard panels.

## Before you begin
1. Your cluster must have access to the Cloudera repository (this repo) so that the dashboards are created automatically.
2. Your cluster must have access to dl.grafana.com so that Grafana is installed successfully.
3. You need to have the root access to execute scripts.
4. Keep Backup of /opt/cloudera/parcels/CDH/lib/knox/data/services, /var/lib/knox/gateway/data/services and /srv/salt/gateway/config/cm folders


## Manual Installation Steps
1. scp two Files grafana-install-configure-v2.sh and configure-knox-for-grafana.sh to the gateway node of the COD cluster.
e.g,
```
scp -i ~/.ssh/odx-developers.pem ./grafana-install-configure-v2.sh cloudbreak@10.80.192.182:
scp -i ~/.ssh/odx-developers.pem ./configure-knox-for-grafana.sh cloudbreak@10.80.192.182:
```

3. ssh to gateway node
e.g,
`ssh -i ~/.ssh/odx-developers.pem cloudbreak@10.80.201.52`

4. Run sudo to get root permission and go to the folder where you transferred the script files
e.g,
`sudo -i`
`cd /home/cloudbreak/`

5. Set the proper permission and owner of the script files so that it can run successfully
e.g,
`chown root:root *`

6. Below is the example of permission expected

`ls -lrt`

```
-rwxr-x---. 1 root root 3874 Aug 22 10:47 configure-knox-for-grafana.sh
-rwxr-x---. 1 root root 4066 Aug 22 10:47 grafana-install-configure-v2.sh`
```


6. Run the grafana installation script
e.g,
`./grafana-install-configure-v2.sh`

Expected Output like below,
```ecmascript 6
extracted string: cod--186yjxqvwcwoh
Failed to set locale, defaulting to C
Loaded plugins: fastestmirror, versionlock
Determining fastest mirrors
epel/x86_64/metalink                                                                                                                                                   |  27 kB  00:00:00
* base: download.cf.centos.org
* centos-sclo-rh: download.cf.centos.org
* centos-sclo-sclo: download.cf.centos.org
* epel: ftp-osl.osuosl.org
* extras: download.cf.centos.org
* updates: download.cf.centos.org
  base                                                                                                                                                                   | 3.6 kB  00:00:00
  cdp-infra-tools                                                                                                                                                        | 2.9 kB  00:00:00
  centos-sclo-rh                                                                                                                                                         | 3.0 kB  00:00:00

…

Created symlink from /etc/systemd/system/multi-user.target.wants/grafana-server.service to /usr/lib/systemd/system/grafana-server.service. 
```
Note: the output is truncated as it is pretty big, if it is successful you must see the symlink created msg


7. If the above step completed successfully, you will be able to see the grafana service status though systemctl command
e.g,
`systemctl status grafana-server.service`

Output of this command should be as below
```ecmascript 6
● grafana-server.service - Grafana instance
Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; enabled; vendor preset: disabled)
Active: active (running) since Tue 2023-08-22 10:51:08 UTC; 16s ago
Docs: http://docs.grafana.org
Main PID: 25273 (grafana)
CGroup: /system.slice/grafana-server.service
└─25273 /usr/share/grafana/bin/grafana server --config=/etc/grafana/grafana.ini --pidfile=/var/run/grafana/grafana-server.pid --packaging=rpm cfg:default.paths.logs=/var/log/gr...
```

8. Run the knox configuration script
e.g,
`./configure-knox-for-grafana.sh`

Output of the above command should be as below
```ecmascript 6
Installing knox service configs for grafana
Adding GRAFANA service in the cdp-proxy topology
Adding GRAFANA service in the cdp-proxy topology in the active directory
```

9. Restart the knox service from CM and wait for few minutes [5-10 minutes] before you access grafana dashboard
10. Grafana dashboard url can be formed like below
`https://<GATEWAY-FQDN>/grafanacod/dashboards`
Here value of GATEWAY-FQDN can be obtained from COD DATAHUB > Nodes > Gateway
In the listed table you can find the FQDN column
e.g,
`https://cod--186yjxqvwcwoh-gateway0.cod-7216.xcu2-8y8x.dev.cldr.work/grafanacod/dashboards`


## Importing a New Dashboard
By default, the scripts will install HBase, HDFS and Zookeeper dashboard. If you want to install additional dashboard like S3[Only for AWS environment], you need to perform the following

1. Download the dashboard json files [e.g, S3.json] in your local computer from [Cloudera Repo](../dashboards)
2. Open your Grafana portal and go to the Dashboard page.
3. Choose your folder where you want to install the dashboards. [e.g, Cloudera]
4. Click New and select Import in the drop-down menu.
5. Upload the dashboard JSON file you have downloaded earlier.
6. After uploading the file you can see the dashboard has been created in your chosen folder.
7. Select the dashboard to see the graphs.
