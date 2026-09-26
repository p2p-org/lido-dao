FROM ethereum/client-go:v1.17.6

COPY ./genesis.json /root
COPY ./password.txt /root
COPY ./keystore /root/keystore
COPY ./entrypoint.sh .
RUN chmod +x ./entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]