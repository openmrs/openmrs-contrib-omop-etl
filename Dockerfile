FROM debian:bookworm

# Install dependencies and pgloader
RUN apt-get update && \
    apt-get install -y \
        curl \
        gnupg \
        lsb-release \
        default-mysql-client \
        postgresql-client \
        pgloader \
        python3 \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*


#COPY requirements.txt ./requirements.txt

# TOOD: Use a non-root user
RUN #pip3 install -r requirements.txt

# Copy scripts and config
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh
