#Install MIT KDC on top of Linux 8, and setup a root/admin@DMAIN user

#!/bin/bash


#Set Variables
domain=MIT.SUPPORTLAB.COM
pass=Hadoop12345!
hostname=`hostname -f`


# Install Kerberos packages
yum install -y krb5-server krb5-libs krb5-workstation

#Create log directory
mkdir /var/log/krb5

# Configure /etc/krb5.conf
cat > /etc/krb5.conf << EOF
[logging]
   default = FILE:/var/log/krb5/krb5libs.log
   kdc = FILE:/var/log/krb5/krb5kdc.log
   admin_server = FILE:/var/log/krb5/kadmind.log

[libdefaults]
   default_realm = $domain
   dns_lookup_kdc = false
   dns_lookup_realm = false
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true
   rdns = false

[realms]
  $domain = {
  kdc = $hostname
  admin_server = $hostname
  }

[domain_realm]
  .coelab.cloudera.com = $domain
  coelab.cloudera.com = $domain
EOF

# Configure /var/kerberos/krb5kdc/kdc.conf
cat > /var/kerberos/krb5kdc/kdc.conf << EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
$domain  = {
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal
default_principal_flags = +renewable, +forwardable
 }
EOF

# Add admin principal to /var/kerberos/krb5kdc/kadm5.acl
echo "admin/admin@$domain   *" >> /var/kerberos/krb5kdc/kadm5.acl
echo "root/admin@$domain   *" >> /var/kerberos/krb5kdc/kadm5.acl

# Create the Kerberos database
kdb5_util create -s -P $pass

# Create admin principal
kadmin.local -q "addprinc -pw $pass root/admin"
kadmin.local -q "addprinc -pw $pass admin/admin"


# Start and enable krb5kdc and kadmin services
systemctl start krb5kdc kadmin
systemctl enable krb5kdc kadmin


