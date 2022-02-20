FROM elixir:1.7

ENV NODE_VERSION v12.4.0

RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash \
&&  . ~/.nvm/nvm.sh \
&&  nvm install $NODE_VERSION \
&&  npm install npm@6.9.0 -g
ENV PATH $PATH:/root/.nvm/versions/node/$NODE_VERSION/bin

RUN apt update && apt install -y inotify-tools

RUN mix local.hex --force && \
  mix local.rebar --force

WORKDIR /app
