#!/bin/bash -eux

debconf-set-selections <<!
slapd slapd/password1 password vagrant
slapd slapd/password2 password vagrant
slapd shared/organization string example.org
slapd slapd/domain string example.org
!

DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends slapd ldap-utils ldapscripts

cat > ~/README.ldap <<!
BaseDN: dc=example,dc=org
BindDN: cn=admin,dc=example,dc=org
Password: vagrant
!
chown vagrant:vagrant ~/README.ldap
