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

.. _pyenv: https://github.com/yyuu/pyenv
.. _tox: http://tox.readthedocs.org/
.. _up until Python 2.7.8/3.4.2: http://bugs.python.org/issue8876
