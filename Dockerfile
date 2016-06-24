FROM instructure/ruby-passenger:2.1

USER root
RUN echo "Disabling non-essential packages" && \
    echo "APT::Install-Recommends \"0\";" >> /etc/apt/apt.conf.d/02recommends && \
    echo "APT::Install-Suggests \"0\";" >> /etc/apt/apt.conf.d/02recommends && \
    true

# Install node 0.12
RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash - && \
    apt-get install -qq \
        nodejs \
        postgresql-client \
        libxmlsec1-dev \
        unzip \
        fontforge \
        && \
    apt-get clean && \
    true

# Install npm
RUN npm install -g gulp && \
    npm cache clean && \
    true

# Install sfnt2woff to build fonts
RUN mkdir /tmp/sfnt2woff && \
    cd /tmp/sfnt2woff && \
    curl -O http://people.mozilla.org/~jkew/woff/woff-code-latest.zip && \
    unzip woff-code-latest.zip && \
    make && \
    cp sfnt2woff /usr/local/bin && \
    true

# Install the specific bundler we need
RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi && \
    gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler && \
    gem install bundler --no-document -v 1.11.2 && \
    find $GEM_HOME ! -user docker -exec chown docker:docker {} \; && \
    true

WORKDIR /usr/src/app
USER docker

# Install Canvas LMS, install Ruby deps
RUN curl https://codeload.github.com/instructure/canvas-lms/tar.gz/stable | \
    tar -zxv --strip-components 1 && \
    bundle install --path vendor/bundle --without=sqlite mysql && \
    true

# Install frontend deps
RUN touch Gemfile.lock && \
    npm install && \
    npm cache clean && \
    true
