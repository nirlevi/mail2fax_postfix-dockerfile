from ubuntu:12.04
maintainer Vo Minh Thu <noteed@gmail.com>

run apt-get update
run apt-get install -q -y language-pack-en
run update-locale LANG=en_US.UTF-8


# rvm 
RUN apt-get install -y nginx openssh-server git-core openssh-client curl
RUN apt-get install -y build-essential
RUN apt-get install -y openssl libreadline6 libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config


# install Ruby and Sidekiq
RUN \curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.1"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install sidekiq --no-ri --no-rdoc"

# hosts
run echo fax > /etc/hostname
add etc-hosts.txt /etc/hosts
run chown root:root /etc/hosts

run apt-get install -q -y vim

# create mail2fax user
RUN echo mail2fax:mail2fax | chpasswd
RUN echo 'mail2fax ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/mail2fax
RUN chmod 0440 /etc/sudoers.d/mail2fax


# Install Postfix.
run echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt
run echo "postfix postfix/mailname string mail.netfax.co.il" >> preseed.txt
# Use Mailbox format.
run debconf-set-selections preseed.txt
run DEBIAN_FRONTEND=noninteractive apt-get install -q -y postfix


# main.cf
add etc-postfix-main.cf /etc/postfix/main.cf
run chown root:root /etc/postfix/main.cf

# transport
add etc-postfix-transport /etc/postfix/transport
run "postmap transport"

# master
add etc-postfix-master.cf /etc/postfix/master.cf


# access 
add etc-access.txt /etc/postfix/access
run chown root:root /etc/postfix/access
run "makemap hash /etc/mail/access.db < /etc/postfix/access"

# Use syslog-ng to get Postfix logs (rsyslog uses upstart which does not seem
# to run within Docker).
run apt-get install -q -y syslog-ng

expose 25
cmd ["sh", "-c", "service syslog-ng start ; service postfix start ; tail -F /var/log/mail.log"]
