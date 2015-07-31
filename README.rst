Using Docker to run tox without adding Pythons to your system
#############################################################

If you would like to test python applications in a repeatable way,
especially if for interpreters beyond the ones you keep on your
development system, there are some ways to pull that off -- I've
usually fallen back on pyenv_, personally -- but they're all a bit
less than optimal. One of the worst things about them is trying to get
them to play nicely with tox_, which is an amazing way to run
cross-python tests.

Naturally, it occurred to me that using Docker might be a good way to
do this, and so I put together a Dockerfile that sets up basically the
omni-interpreter runtime, and configured it to run tox on a
mounted /src directory.

Once you've got this dockerfile built, then you can run tox tests that
depend on Pythons starting with 2.5 through 3.4, as well as pypy in
both the 2.x and 3.x flavors. Technically it also supports Jython, but
due to some issues with Jython and virtualenvs, I don't presently have
that working (pull requests welcome).

Here's literally all it takes to run it:

.. code:: bash

   $ cd ~/projects/MyProject
   $ docker run --rm -v `pwd`:/src chrisr/pybuilder:latest
   # tox output happens for your whole tox file

Some caveats apply if you are running docker by way of boot2docker,
though; because of the nature of the boot2docker filesystem, hardlinks
do not work, and distutils -- `up until Python
2.7.8/3.4.2`_ -- fails if it can't
hardlink files. Working around this requires a filthy hack in your
setup.py, which depends on a flag in this Dockerfile to trigger it:

.. code:: python

   # need to kill off link if we're in docker builds
   if os.environ.get('PYTHON_BUILD_DOCKER', None) == 'true':
       del os.link

If you're running docker natively on a linux, however, this won't be
necessary.

The dockerfile to build this image looks like this:

.. code:: docker

    FROM ubuntu:14.04
    MAINTAINER Chris Rose <offline@offby1.net>

    # ensure the base image has what we need
    RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -yqq install \
        build-essential python-pip software-properties-common \
        openjdk-7-jdk && \
        add-apt-repository ppa:fkrull/deadsnakes && \
        apt-get update

    # install legacy python versions
    RUN DEBIAN_FRONTEND=noninteractive apt-get -yqq install \
        python2.5 python2.6 python2.7 python3.1 python3.2 python3.3 python3.4

    # add Jython installer
    # ADD jython-installer-2.7-b4.jar /tmp/
    ADD http://search.maven.org/remotecontent?filepath=org/python/jython-installer/2.7-b4/jython-installer-2.7-b4.jar /tmp/jython-installer-2.7-b4.jar

    # install pypy versions
    # ADD pypy-2.5.0-linux64.tar.bz2 /opt/
    # ADD pypy3-2.4.0-linux64.tar.bz2 /opt/
    RUN mkdir -p /opt
    ADD https://bitbucket.org/pypy/pypy/downloads/pypy3-2.4.0-linux64.tar.bz2 /tmp/
    RUN cd /opt && tar -xf /tmp/pypy3-2.4.0-linux64.tar.bz2
    ADD https://bitbucket.org/pypy/pypy/downloads/pypy-2.5.0-linux64.tar.bz2 /tmp/
    RUN cd /opt && tar -xf /tmp/pypy-2.5.0-linux64.tar.bz2

    # install Jython version
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

The clean-launch.sh entry point is pretty simple:

.. code:: bash

   #!/bin/bash
   find /src \( -name __pycache__ -o -name '*.pyc' \) -delete
   exec "$@"

Its purpose is to remove all .pyc files that might reference absolute
paths on the host filesystem; otherwise the interpreter barfs rather
frequently.

.. _pyenv: https://github.com/yyuu/pyenv
.. _tox: http://tox.readthedocs.org/
.. _up until Python 2.7.8/3.4.2: http://bugs.python.org/issue8876
