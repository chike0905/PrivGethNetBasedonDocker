FROM debian
LABEL maintainer="Ryosuke Abe <chike@sfc.wide.ad.jp>"

RUN apt update
RUN apt upgrade -y
RUN apt install -y python3 python3-pip
RUN pip3 install networkx matplotlib
ADD src /root/src
ENTRYPOINT ["python3", "/root/src/visualizer.py"]
CMD ["graph"]
