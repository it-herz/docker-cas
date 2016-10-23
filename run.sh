#!/bin/bash

if [ ! -f /etc/cas/jetty/thekeystore ]
then
  openssl pkcs12 -export -in /etc/ssl/fullchain.pem -inkey /etc/ssl/privkey.pem -out /etc/ssl/all.p12 -name tomcat -CAfile /etc/ssl/chain.pem -caname root -password pass:export
  keytool -importkeystore -srcstorepass export -deststorepass changeit -srckeystore /etc/ssl/all.p12 -srcstoretype PKCS12 -alias tomcat -keystore /etc/cas/jetty/thekeystore
  keytool -import -trustcacerts -alias root -deststorepass changeit -file /etc/ssl/chain.pem -noprompt -keystore /etc/cas/jetty/thekeystore
fi

echo "cas.server.name: https://$FQDN:$PORT" >/cas.properties
echo "cas.server.prefix: https://$FQDN:$PORT/cas" >>/cas.properties
echo "cas.adminPagesSecurity.ip=`echo $ADMINIP | sed 's/\./\\\./ig'`" >>/cas.properties
echo "host.name=$FQDN" >>/cas.properties

for A in `env`
do
  NAME=`echo $A | awk -F'=' '{ print $1 }'`
  if [[ $NAME =~ ^LDAP_.*$ ]]
  then
    echo "`echo $NAME | sed 's/LDAP_\(.*\)/ldap.\1/ig' | tr '_' '.'`=${!NAME}" >>/cas.properties
  fi
done
echo "" >>/cas/properties

#patch for ldap bind dn
sed -i "s/\${ldap.authn.searchFilter}/$LDAP_authn_searchFilter/ig" /cas-overlay/src/main/webapp/WEB-INF/deployerConfigContext.xml

mkdir -p /etc/cas/config
cp /cas.properties /etc/cas/cas.properties
cp /cas.properties /etc/cas/config/cas.properties

cd /cas-overlay
./mvnw jetty:run-forked
