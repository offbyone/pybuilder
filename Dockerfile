FROM ubuntu:14.04
MAINTAINER Chris Rose <offline@offby1.net>

# ensure the base image has what we need
RUN apt-get update && apt-get -yqq install build-essential python-pip software-properties-common openjdk-7-jdk && add-apt-repository ppa:fkrull/deadsnakes && apt-get update

# install legacy python versions
RUN apt-get -yqq install python2.5 python2.6 python2.7 python3.1 python3.2 python3.3 python3.4

# add Jython installer
ADD jython-installer-2.7-b4.jar /tmp/

# install pypy versions
ADD pypy-2.5.0-linux64.tar.bz2 /opt/
ADD pypy3-2.4.0-linux64.tar.bz2 /opt/

RUN java -jar /tmp/jython-installer-2.7-b4.jar -d /opt/jython-2.7-b4 -s -t all
ENV PATH /opt/jython-2.7-b4/bin:$PATH
# bootstrap jython JAR cache
RUN jython

# make PyPy available
ENV PATH /opt/pypy-2.5.0-linux64/bin:/opt/pypy3-2.4.0-linux64/bin:$PATH

ENV PYTHON_BUILD_DOCKER=true

# install tox
RUN pip install tox

ADD clean-launch.sh /tools/clean-launch.sh

VOLUME /src
WORKDIR /src

ENTRYPOINT ["/tools/clean-launch.sh"]
CMD ["tox"]
