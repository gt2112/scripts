#!/bin/bash          
# Install Open LDAP v2.6.7 on RedHat 8. Adding 500 users distributed in 5 groups
# Admin credentials
# principal: cn=admin,dc=ldap,dc=supportlab,dc=com
# password: Hadoop12345!
# Base DN: dc=ldap,dc=supportlab,dc=com



install_home=/tmp
pass={SSHA}NGLkc2hUKkHdcn0BtSlPtipytEDzueFe

rm -rf $install_home/ldap_files
mkdir -p $install_home/ldap_files
#install openldap packages

yum clean all
dnf install wget vim cyrus-sasl-devel libtool-ltdl-devel openssl-devel libdb-devel make libtool autoconf  tar gcc perl perl-devel -y
dnf groupinstall "Development Tools" -y

# useradd -r -M -d /var/lib/openldap -u 55 -s /usr/sbin/nologin ldap

wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.7.tgz
tar xzf openldap-2.6.7.tgz
mv openldap-2.6.7 /opt
cd /opt/openldap-2.6.7


./configure --prefix=/usr --sysconfdir=/etc \
--enable-debug --with-tls=openssl --with-cyrus-sasl --enable-dynamic \
--enable-crypt --enable-spasswd --enable-slapd --enable-modules \
--enable-rlookups

make depend
make
make install

mkdir /var/lib/openldap /etc/openldap/slapd.d

cp /usr/share/doc/sudo/schema.OpenLDAP  /etc/openldap/schema/sudo.schema

sudo mv /etc/openldap/slapd.ldif /etc/openldap/slapd.ldif.bak

sudo echo "dn: cn=config
objectClass: olcGlobal
cn: config
olcArgsFile: /var/lib/openldap/slapd.args
olcPidFile: /var/lib/openldap/slapd.pid

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath: /usr/libexec/openldap
olcModuleload: back_mdb.la

# Include more schemas in addition to default core
include: file:///etc/openldap/schema/core.ldif
include: file:///etc/openldap/schema/cosine.ldif
include: file:///etc/openldap/schema/nis.ldif
include: file:///etc/openldap/schema/inetorgperson.ldif
#include: file:///etc/openldap/schema/sudo.ldif

dn: olcDatabase=frontend,cn=config
objectClass: olcDatabaseConfig
objectClass: olcFrontendConfig
olcDatabase: frontend
olcAccess: to dn.base=\"cn=Subschema\" by * read
olcAccess: to * 
  by dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" manage 
  by * none

dn: olcDatabase=config,cn=config
objectClass: olcDatabaseConfig
olcDatabase: config
olcRootDN: cn=config
olcAccess: to * 
  by dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" manage 
  by * none">/etc/openldap/slapd.ldif 


slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif

# chown -R ldap:ldap /etc/openldap/slapd.d


echo "[Unit]
Description=OpenLDAP Server Daemon
After=syslog.target network-online.target
Documentation=man:slapd
Documentation=man:slapd-mdb

[Service]
Type=forking
PIDFile=/var/lib/openldap/slapd.pid
Environment=\"SLAPD_URLS=ldap:/// ldapi:/// ldaps:///\"
Environment=\"SLAPD_OPTIONS=-F /etc/openldap/slapd.d\"
ExecStart=/usr/libexec/slapd -4 -h \${SLAPD_URLS} \$SLAPD_OPTIONS

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/slapd.service


sudo systemctl daemon-reload

sudo systemctl enable --now slapd

#adminPassword: Hadoop12345!
pass={SSHA}NGLkc2hUKkHdcn0BtSlPtipytEDzueFe


echo "dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbMaxSize: 42949672960
olcDbDirectory: /var/lib/openldap
olcSuffix: dc=ldap,dc=supportlab,dc=com
olcRootDN: cn=admin,dc=ldap,dc=supportlab,dc=com
olcRootPW: pass
olcDbIndex: uid pres,eq
olcDbIndex: cn,sn pres,eq,approx,sub
olcDbIndex: mail pres,eq,sub
olcDbIndex: objectClass pres,eq
olcDbIndex: loginShell pres,eq
olcAccess: to attrs=userPassword,shadowLastChange,shadowExpire
  by self write
  by anonymous auth
  by dn.subtree="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage 
  by dn.subtree="ou=system,dc=ldap,dc=supportlab,dc=com" read
  by * none
olcAccess: to dn.subtree="ou=system,dc=ldap,dc=supportlab,dc=com" by dn.subtree="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
  by * none
olcAccess: to dn.subtree="dc=ldap,dc=supportlab,dc=com" by dn.subtree="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
  by users read 
  by * none" > $install_home/ldap_files/rootdn.ldif


sed -i s/pass/$pass/g $install_home/ldap_files/rootdn.ldif


ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/rootdn.ldif


#add openldap tree

echo "dn: dc=ldap,dc=supportlab,dc=com
objectClass: dcObject
objectClass: organization
dc: ldap
o : supportlab

dn: ou=Users,dc=ldap,dc=supportlab,dc=com
objectClass: organizationalUnit
ou: Users

dn: ou=Groups,dc=ldap,dc=supportlab,dc=com
objectClass: organizationalUnit
ou: Groups" >$install_home/ldap_files/basedn.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/basedn.ldif



echo "dn: olcDatabase={-1}frontend,cn=config
changetype: modify
add: olcAccess
olcAccess: to dn.base="" by * read
olcAccess: to dn.base="cn=subschema" by * read" >$install_home/ldap_files/fixRootDSE.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/fixRootDSE.ldif


# Add 500 users to openldap DB

for i in {1..500}; do echo "dn: cn=user$i,ou=Users,dc=ldap,dc=supportlab,dc=com
cn: user$i
sn: user$i
objectClass: inetOrgPerson
userPassword: user$i
uid: user$i" >> $install_home/ldap_files/user$i.ldif;ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/user$i.ldif; 
done

# Add 5 SME,Engineering,QA,Support and Research groups tp openldap DB

for i in {SME,Engineering,QA,Support,Research}; do echo "dn: cn=$i,ou=Groups,dc=ldap,dc=supportlab,dc=com
cn: $i
objectClass: groupOfNames
member: cn=user1,ou=Users,dc=ldap,dc=supportlab,dc=com" >> $install_home/ldap_files/group_$i.ldif;ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/group_$i.ldif; 
done


# Assign first 100 users to group SME

for i in {1..100}; do echo "dn: cn=SME,ou=Groups,dc=ldap,dc=supportlab,dc=com
changetype: modify
add: member
member: cn=user$i,ou=Users,dc=ldap,dc=supportlab,dc=com" >> $install_home/ldap_files/Add_User_To_Group_SME_user$i.ldif; ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/Add_User_To_Group_SME_user$i.ldif;
done

# Assign second 100 users to group Engineering

for i in {101..200}; do echo "dn: cn=Engineering,ou=Groups,dc=ldap,dc=supportlab,dc=com
changetype: modify
add: member
member: cn=user$i,ou=Users,dc=ldap,dc=supportlab,dc=com" >> $install_home/ldap_files/Add_User_To_Group_Engineering_user$i.ldif; ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/Add_User_To_Group_Engineering_user$i.ldif;
done

# Assign third 100 users to group QA

for i in {201..300}; do echo "dn: cn=QA,ou=Groups,dc=ldap,dc=supportlab,dc=com
changetype: modify
add: member
member: cn=user$i,ou=Users,dc=ldap,dc=supportlab,dc=com" >> $install_home/ldap_files/Add_User_To_Group_QA_user$i.ldif; ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/Add_User_To_Group_QA_user$i.ldif;
done

# Assign fourth 100 users to group Support

for i in {301..400}; do echo "dn: cn=Support,ou=Groups,dc=ldap,dc=supportlab,dc=com
changetype: modify
add: member
member: cn=user$i,ou=Users,dc=ldap,dc=supportlab,dc=com" >> $install_home/ldap_files/Add_User_To_Group_Support_user$i.ldif; ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/Add_User_To_Group_Support_user$i.ldif;
done

# Assign fifth 100 users to group Research

for i in {401..500}; do echo "dn: cn=Research,ou=Groups,dc=ldap,dc=supportlab,dc=com
changetype: modify
add: member
member: cn=user$i,ou=Users,dc=ldap,dc=supportlab,dc=com" >> $install_home/ldap_files/Add_User_To_Group_Research_user$i.ldif; ldapadd -Y EXTERNAL -H ldapi:/// -f $install_home/ldap_files/Add_User_To_Group_Research_user$i.ldif;
done

rm -rf $install_home/ldap_files

echo "COMPLETED :)"

# We are all done now
