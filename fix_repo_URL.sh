#Fix repo URLs


sed -i s/'mirrorlist.centos.org'/'vault.centos.org'/g /etc/yum.repos.d/*
sed -i s/'#baseurl=http:\/\/mirror.centos.org'/'baseurl=http:\/\/vault.centos.org'/g /etc/yum.repos.d/*
sed -i s/'mirrorlist=http:\/\/vault'/'#mirrorlist=http:\/\/vault'/g /etc/yum.repos.d/*

yum clean all


