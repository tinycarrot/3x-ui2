# ========================================================
# Stage: Builder
# ========================================================
FROM --platform=$BUILDPLATFORM golang:1.22 AS builder
WORKDIR /app
ARG TARGETARCH

# Cài đặt các gói cần thiết
RUN apt-get update && apt-get install -y \
  build-essential \
  gcc \
  wget \
  unzip \
  && apt-get clean

COPY . .

ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
RUN go build -o build/x-ui main.go
RUN ./DockerInit.sh "$TARGETARCH"

# ========================================================
# Stage: Final Image of 3x-ui
# ========================================================
FROM --platform=$BUILDPLATFORM ubuntu:22.04
ENV TZ=Asia/Tehran
WORKDIR /app

# Cài đặt các gói cần thiết
RUN apt-get update && apt-get install -y \
  ca-certificates \
  tzdata \
  fail2ban \
  bash \
  && apt-get clean

COPY --from=builder /app/build/ /app/
COPY --from=builder /app/DockerEntrypoint.sh /app/
COPY --from=builder /app/x-ui.sh /usr/bin/x-ui

# Cấu hình fail2ban
RUN rm -f /etc/fail2ban/jail.d/defaults-debian.conf \
  && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local \
  && sed -i "s/^\[ssh\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/^\[sshd\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/#allowipv6 = auto/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

RUN chmod +x \
  /app/DockerEntrypoint.sh \
  /app/x-ui \
  /usr/bin/x-ui

VOLUME [ "/etc/x-ui" ]
CMD [ "./x-ui" ]
ENTRYPOINT [ "/app/DockerEntrypoint.sh" ]
