buoyant
=======
**buoyant** leverages docker to provide an alternative to VM-centric SaltStack development environments.  buoyant
containers may be spun up nearly instantly, once an initial docker image has been built.

A common docker pattern is to run few, or as little as a single process within a container.  While buoyant
containers run very few processes, they are very un-container-like, more resembling lightweight VMs as
they run init and systemd.  This configuration is necessary for the salt-minion to run, as well as for
salt states such as *service.running*.

SaltStack development with buoyant containers is intended for use in developing states that will
target full Linux instances, it is not intended for targeting states on production docker instances.
Note that buoyant containers should never be run in production and should only exist in a trusted
development environment.  They require extended privileges (--privileged) for systemd to function.

Why Not Just Use Vagrant?
-------------------------
Vagrant is an excellent, mature, feature-rich tool that does work exceptionally well for
SaltStack development.

What buoyant brings to the table is speed, simplicity, and instance management with the docker cli.
Once a docker image has been created and is available, spinning up several test instances is nearly
instantaneous, with zero configuration files to update.  Common Vagrantfile options such as port
forwarding and synced folders are handled with built-in Docker functionality.  Instances can be treated
as truly ephemeral and destroyed and created in a matter of seconds.


Pre-requisites
--------------

+ Docker Engine must be [installed](https://docs.docker.com/).


Getting Started
---------------
**1) Clone this repository and cd to the top-level directory of the repository**

**2) Modify the Dockerfile**

  While buoyant works out of the box, it may be useful to change a few settings
  such as the version of salt to use.

**3) Update files/resolv.conf**

  Update search domains and set nameservers.

**4) Update files/sources.list**

  Update this file only when using a local Ubuntu mirror or using a different Ubuntu release.

**5) Build a Reusable Base Image**
```bash
docker build -t salt_minion_masterless:v15.10_2015.8.1 .
```
*NOTE that we've included the Ubuntu and salt versions in the tag.*
*A full image build process typically lasts as much as 10 minutes, but only has to be completed once.*


**6) Create web and redis instances**

```bash
docker run -d --name web -h web.example.com  \
--privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(pwd)/srv/salt:/srv/salt \
-v $(pwd)/srv/pillar:/srv/pillar salt_minion_masterless:v15.10_2015.8.1 /sbin/init

docker run -d --name redis -h redis.example.com  \
--privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(pwd)/srv/salt:/srv/salt \
-v $(pwd)/srv/pillar:/srv/pillar salt_minion_masterless:v15.10_2015.8.1 /sbin/init
```
*NOTE that --name is the short hostname.  If the fqdn is used, the dots are replaced by hyphens in the
/etc/hosts file.  Ideally the hosts file would have both the short name and fqdn, but this does not
appear to be possible with the automated host file management built into docker*

**6) Attach to the web and redis containers**

```bash
docker exec -it web /bin/bash

docker exec -it redis /bin/bash
```

**7) Run a highstate to install redis and nginx**

```bash
root@web:/# salt-call state.highstate
```

```bash
root@redis:/# salt-call state.highstate
```
*Basic example salt states are distributed with this repository*

**8) Test out pillar**

```bash
root@web:/# salt-call pillar.item buoyant
```

**9) Start writing states!**

Development of states normally occurs under the home directory of the user present on the container host.

Container and Image Management
------------------------------
Please refer to the official [Docker CLI documentation](http://docs.docker.com/engine/reference/commandline/cli/)
for information about working with images and containers.

### Kill and delete the containers we created earlier

```bash
docker kill web redis && docker rm web redis
```

### Delete the image we created earlier

```bash
docker rmi salt_minion_masterless:v15.10_2015.8.1
```

Tips
----
+ If making heavy use of salt and pillar environments that reside in separate repositories
(ie not using gitfs), it may be desirable to clone them under ~/salt/ and ~/pillar/.  For example,
~/salt/prod/ and ~/pillar/prod/, which would be referenced in 10-minion-overrides.conf,
with /srv/salt/ and /srv/pillar/ mounted as volumes hosted from ~/salt/ and ~/pillar/
for the container that is created with *docker run*.


FAQ
---
+ **buoyant uses systemd, Ubuntu 15.10 and SaltStack 2015.8.1, but can it work with upstart, and different
versions of Ubuntu and salt, and possibly even different distros?**

    Other configurations have not been tested.  It is likely that modifying the Dockerfile to
    use more recent versions of SaltStack and Ubuntu will work with little or no additional
    modifications.  Running buoyant containers on a different distro or a system using upstart is
    likely possible, but customizations to the Dockerfile would be required.


+ **This is great for SaltStack, but what about chef, ansible, puppet, etc.?**

    This pattern may very well be reusable for creating environments for developing cookbooks
    with chef-solo for example, or any other similar technology for that matter.  Fork away!

+ **Does buoyant make for a good environment for developing my application and stack?**

    Some limited experimentation has been performed for applications that will eventually
    target VMs and physicals, and it appears that buoyant may be a valid alternative to
    Vagrant in certain straight-forward scenarios.

+ **/srv/salt/ and /srv/pillar/ are not mounted?**

    When creating a container, make sure the cwd is the top-level directory of this git
    repository, or specify the full path to salt and pillar directories when adding volume arguments.

License
-------

Apache License, version 2.0.  Please see LICENSE
