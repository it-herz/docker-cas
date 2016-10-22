FROM itherz/java8

MAINTAINER Dmitrii Zolotov <dzolotov@herzen.spb.ru>

ENV DEBIAN_FRONTEND noninteractive

# Download the CAS overlay project
RUN apt update -y && apt install -y maven git
RUN cd / \
    && git clone -b 5.0 --single-branch https://github.com/apereo/cas-overlay-template.git cas-overlay \
    && cd cas-overlay \
    && mkdir /etc/cas \
    && mkdir /etc/cas/jetty \
    && mkdir bin \
    && mkdir -p src/main/webapp \
    && cp -R etc/* /etc/cas \
    && mkdir -p src/main/webapp/ && touch src/main/webapp/.donotdel

EXPOSE 8080 8443

WORKDIR /cas-overlay

#ADD thekeystore -> /etc/cas/jetty/

RUN sed -i 's~</dependencies>~<dependency><groupId>org.apereo.cas</groupId><artifactId>cas-server-support-ldap</artifactId><version>${cas.version}</version></dependency></dependencies>~ig' pom.xml

ADD run.sh /
ADD deployerConfigContext.xml /cas-overlay/src/main/webapp/WEB-INF/classes/
RUN cd /cas-overlay && ./build.sh package

CMD ["/run.sh"]
