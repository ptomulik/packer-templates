packer-templates
================

Various templates for Hashicorp's packer_.

REQUIREMENTS
------------

- ruby_,
- rake_,
- packer_
- vagrant_
- virtualbox_

maybe others.

Installing Dependencies on Debian
`````````````````````````````````

.. code:: bash

    sudo apt-get install ruby rake packer vagrant virtualbox

USAGE
-----


Building Boxes
``````````````

.. code:: bash

    rake -T

to see full list of targets. Then build your desired target, for example

.. code:: bash

    rake freebsd-10.3-amd64

The box will be built and placed in project's top level directory, for example
as ``packer_freebsd-10.3-amd64_virtualbox.box``.


Testing built Vagrant boxes
```````````````````````````

Example

.. code:: bash

  vagrant up freebsd-10.3-amd64


.. _ruby: https://www.ruby-lang.org/
.. _rake: https://www.virtualbox.org/
.. _packer: https://www.packer.io/
.. _vagrant: https://www.vagrantup.com/
.. _virtualbox: https://www.virtualbox.org/
