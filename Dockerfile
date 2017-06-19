FROM debian:stretch-slim

LABEL description "Simple and full-featured mail server using Docker" \
      maintainer="Convive <info@convive.io>"

ARG TINI_VER=0.14.0
ARG SCHLEUDER_VER=3.1.0
ARG SCHLEUDER_CLI_VER=0.0.4

# https://pgp.mit.edu/pks/lookup?search=0x0B588DFF0527A9B7&fingerprint=on&op=index
# pub  4096R/7001A4E5 2012-07-23 Thomas Orozco <thomas@orozco.fr>
ARG TINI_GPG_SHORTID="0x0527A9B7"
ARG TINI_GPG_FINGERPRINT="6380 DC42 8747 F6C3 93FE  ACA5 9A84 159D 7001 A4E5"
ARG TINI_SHA256_HASH="420e47096487f72e3e48cca85ce379f18f9c6d2c3809ecc4bcf34e2b35f7c490"

ARG SCHLEUDER_GPG_ID="0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3"

RUN BUILD_DEPS=" \
    wget" \
 && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    postfix \
    postfix-mysql \
    postfix-pcre \
    postgrey \
    gross \
    dovecot-core \
    dovecot-imapd \
    dovecot-lmtpd \
    dovecot-mysql \
    dovecot-sieve \
    dovecot-managesieved \
    dovecot-pop3d \
    opendkim \
    opendkim-tools \
    opendmarc \
    amavisd-new \
    amavisd-milter \
    spamassassin \
    clamav-daemon \
    clamav-milter \
    libsasl2-modules \
    libsys-syslog-perl \
    libmail-spf-perl \
    libhttp-message-perl \
    fetchmail \
    libdbi-perl \
    libdbd-mysql-perl \
    liblockfile-simple-perl \
    altermime \
    supervisor \
    openssl \
    rsyslog \
    python-pip \
    pigz \
    pxz \
    pbzip2 \
    dnsutils \
    ca-certificates \
    ruby-dev \
    gnupg2 \
    libgpgme11-dev \
    libsqlite3-dev \
    libssl-dev \
    build-essential\
    rubygems \
    python-setuptools
 RUN pip install wheel \
 && pip install envtpl
 RUN apt install dirmngr \
 && cd /tmp \
 && wget -q https://github.com/krallin/tini/releases/download/v$TINI_VER/tini_$TINI_VER.deb \
 && wget -q https://github.com/krallin/tini/releases/download/v$TINI_VER/tini_$TINI_VER.deb.asc \
 && wget -q https://0xacab.org/schleuder/schleuder/raw/master/gems/schleuder-$SCHLEUDER_VER.gem \
 && wget -q https://0xacab.org/schleuder/schleuder/raw/master/gems/schleuder-$SCHLEUDER_VER.gem.sig \
 && wget -q https://0xacab.org/schleuder/schleuder-cli/raw/master/gems/schleuder-cli-$SCHLEUDER_CLI_VER.gem \
 && wget -q https://0xacab.org/schleuder/schleuder-cli/raw/master/gems/schleuder-cli-$SCHLEUDER_CLI_VER.gem.sig \
 && echo "Verifying both integrity and authenticity of tini_${TINI_VER}.deb..." \
 && CHECKSUM=$(sha256sum tini_${TINI_VER}.deb | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${TINI_SHA256_HASH}" ]; then echo "Warning! tini_${TINI_VER}.deb checksum does not match!" && exit 1; fi \
 && gpg --keyserver keys.gnupg.net --recv-keys ${TINI_GPG_SHORTID} \
 && FINGERPRINT="$(LANG=C gpg --verify tini_${TINI_VER}.deb.asc tini_${TINI_VER}.deb 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! tini_${TINI_VER}.deb.asc invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${TINI_GPG_FINGERPRINT}" ]; then echo "Warning! tini_${TINI_VER}.deb.asc wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking tini_${TINI_VER}.deb..." \
 && dpkg -i tini_$TINI_VER.deb \
 && echo "Verifying both authenticity of schleuder..." \
 && gpg --keyserver keys.gnupg.net --recv-keys ${SCHLEUDER_GPG_ID} \
 && gpg --verify schleuder-$SCHLEUDER_VER.gem.sig \
 && gpg --verify schleuder-cli-$SCHLEUDER_CLI_VER.gem.sig  \
 && gem install \
    rake \
    activerecord \
    sqlite3 \
    thor \
    thin \
    mail-gpg \
    sinatra \
    sinatra-contrib \
    thor \
 && gem install ./schleuder-$SCHLEUDER_VER.gem \
 && gem install ./schleuder-cli-$SCHLEUDER_CLI_VER.gem \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old

VOLUME /var/mail /etc/opendkim/keys /etc/letsencrypt /etc/schleuder
EXPOSE 25 143 465 587 993 4190 4443

COPY rootfs /
CMD ["tini","--","startup"]
