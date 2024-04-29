# Install and configure Postgres data bse on Linux 7 for Cloudera streams and NiFi apps

# 1. Install required packages
wget --no-check-certificate https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql12-server

# Configure postgres

echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
#sudo su -l postgres -c "postgresql-setup initdb"
/usr/pgsql-12/bin/postgresql-12-setup initdb

sed -i 's/host    all             all             127.0.0.1\/32            ident/host    all            all             0.0.0.0\/0            md5\\\nhost    all            all             0.0.0.0\/0            ident/g' /var/lib/pgsql/12/data/pg_hba.conf
sed -i 's/\\//g' /var/lib/pgsql/12/data/pg_hba.conf

echo listen_addresses = \'*\' >> /var/lib/pgsql/12/data/postgresql.conf

#Eanble service during startup

systemctl enable postgresql-12

#Restart service

systemctl restart postgresql-12

#Create databases

cd /tmp
for dbname in schemaregistry scm rman ranger hue hive oozie ssb smm nifireg nifidata efm yqm; do echo "CREATE DATABASE $dbname;" | sudo -u postgres psql -U postgres;done
for dbname in schemaregistry scm rman hue hive oozie ssb smm nifireg nifidata efm yqm; do echo "CREATE USER $dbname WITH PASSWORD '$dbname';" | sudo -u postgres psql -U postgres;done
for dbname in schemaregistry scm rman hue hive oozie ssb smm nifireg nifidata efm yqm; do echo "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $dbname;" | sudo -u postgres psql -U postgres;done
for dbuser in rangeradmin rangerkms; do echo "CREATE USER $dbuser WITH PASSWORD '$dbuser';" | sudo -u postgres psql -U postgres;done
for dbuser in rangeradmin rangerkms; do echo "GRANT ALL PRIVILEGES ON DATABASE ranger TO $dbuser;" | sudo -u postgres psql -U postgres;done
#
echo "COMPLETED :)"