packer-templates
================

Various templates for Hashicorp's packer_.

REQUIREMENTS
------------

- ruby_,
- rake_,
- packer_,
- jq_,
- vagrant_,
- virtualbox_,
- vmware-workstation_ (optionally)

maybe others.

Installing Dependencies on Debian
`````````````````````````````````

In general

.. code:: bash

    sudo apt-get install ruby rake packer jq
    sudo apt-get purge vagrant
    VER="1.8.1" && \
    wget "https://releases.hashicorp.com/vagrant/${VER}/vagrant_${VER}_x86_64.deb" \
      -O /tmp/vagrant.deb && \
    sudo dpkg -i /tmp/vagrant.deb


For virtualbox provider

.. code:: bash

    sudo apt-get install virtualbox


For VMWare provider (Linux/Windows)

.. code:: bash

    wget http://www.vmware.com/go/tryworkstation-linux-64 -O /tmp/vmware-workstation.bundle && \
      chmod +x /tmp/vmware-workstation.bundle && gksudo /tmp/vmware-workstation.bundle
    vagrant plugin install vagrant-vmware-workstation

Note, that vagrant-vmware-workstation_ plugin is non-free, it requires a
license to be purchased.

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

The boxes are names as follows:

.. code::

    <system>-<version>-<arch>[-<variant>]_<provider>


- ``<system>`` stands for operating system name, for example ``'freebsd'``,
- ``<version>`` is the version of the ``<system>`` used, for example ``9.3``,
- ``<arch>`` is system architecture, e.g. ``amd64``,
- ``<variant>`` is optional variant name (e.g. ``ports`` for ``freebsd`` with ports preinstalled),
- ``<provider>`` is a provider name, e.g. ``virtualbox`` or ``vmware_workstation``.

Some parts of the box name may be omitted (leading to multitasks), for example:

.. code::

    rake -j5 freebsd-10.3

shall build all defined architectures and variants of ``FreeBSD 10.3``, or

.. code::

    rake -j5 freebsd-amd64

shall build all defined versions and variants of FreeBSD for amd64 arch.

Building and uploading to `Vagrant Cloud`_
``````````````````````````````````````````

.. code:: bash

    VAGRANTCLOUD_USER=ptomulik VAGRANTCLOUD_TOKEN=<vagrantcloud-token> rake freebsd-10.3-amd64

You may also use ``VAGRANTCLOUD_DISABLE`` to prevent uploading to `Vagrant Cloud`_.


Testing built Vagrant boxes
```````````````````````````

Example

.. code:: bash

  vagrant up freebsd-10.3-amd64

Cleaning out
````````````

Clean intermediate files (input artefacts e.g.)

.. code:: bash

    rake clean

Clean generated boxes

.. code:: bash

    rake clobber


.. _ruby: https://www.ruby-lang.org/
.. _rake: https://www.virtualbox.org/
.. _packer: https://www.packer.io/
.. _vagrant: https://www.vagrantup.com/
.. _virtualbox: https://www.virtualbox.org/
.. _vmware-workstation: https://www.vmware.com/pl/products/workstation
.. _jq: https://stedolan.github.io/jq/
.. _vagrant-vmware-workstation: https://www.vagrantup.com/vmware/
.. _Vagrant Cloud: https://vagrantcloud.com/
