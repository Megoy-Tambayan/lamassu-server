FROM alpine:3.14 as build
RUN apk add --no-cache nodejs npm git curl build-base net-tools python3 postgresql-dev

WORKDIR lamassu-server

COPY ["package.json", "package-lock.json", "./"]
RUN npm version --allow-same-version --git-tag-version false --commit-hooks false 1.0.0
RUN npm install --production

COPY . ./


FROM alpine:3.14 as l-s-base
RUN apk add --no-cache nodejs npm git curl bash libpq openssl

COPY --from=build /lamassu-server /lamassu-server


FROM l-s-base as l-s

RUN chmod +x /lamassu-server/bin/lamassu-server-entrypoint.sh

EXPOSE 3000

ENTRYPOINT [ "/lamassu-server/bin/lamassu-server-entrypoint.sh" ]


FROM alpine:3.14 as build-ui
RUN apk add --no-cache nodejs npm git curl build-base python3

COPY ["new-lamassu-admin/package.json", "new-lamassu-admin/package-lock.json", "./"]

RUN npm version --allow-same-version --git-tag-version false --commit-hooks false 1.0.0
RUN npm install

COPY new-lamassu-admin/ ./
RUN npm run build


FROM l-s-base as l-a-s
COPY --from=build-ui /build /lamassu-server/public

EXPOSE 443

ENTRYPOINT [ "node" ]
CMD [ "/lamassu-server/bin/lamassu-admin-server" ]
