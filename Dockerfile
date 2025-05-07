FROM python:3.11-bullseye


RUN apt-get update && \
    apt-get install -y default-mysql-client && \
    rm -rf /var/lib/apt/lists/*


COPY requirements.txt ./requirements.txt

RUN pip3 install -r requirements.txt

# Copy scripts and config
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh
