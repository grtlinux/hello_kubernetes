# Vagrant on macOS
Create and configure lightweight, reproducible, and portable development evnironments.
Vagrant is an amazing tool for managing virtual machines via a simple to use command line interface.

## before you start
In order to simplify the installation process you should install homebrew-cask which provides a friendly
homebrew-style CLI workflow for the administration of Mac applications distributed as binaries.
Refer to this article in order to install homebrew-cask.

## Install
Vagrant uses Virtualbox to manage the virtual dependencies.
You can directly download virtualbox and install or use homebrew for it.
```
$ brew cask install virtualbox
```
Now install Vagrant either from the website or use home brew for installing it.
```
$ brew cask install vagrant
```
Vagrant-Manager helps you manage all your virtual machines in one place directly from the menubar.
```
$ brew cask install vagrant-manager
```

## Usage
Add the Vagrant box you want to use. We'll use Ubuntu 12.04 for the following example.
```
$ vagrant box add precise64 http://files.vagrantup.com/precise64.box
```
You can find more boxes at Vagrant Cloud.
Now create a test directory and cd into the test directory. Then we'll initialize the vagrant machine.
```
$ vagrant init precise64
```
Now lets start the machine using the following command
```
$ vagrant up
```
You can ssh into the machine now.
```
$ vagrant ssh
```
Halt the vagrant machine now.
```
$ vagrant halt
```
Other useful commands are suspend, destroy etc.

# Reference
- [Vagrant](https://sourabhbajaj.com/mac-setup/Vagrant/README.html)
- [vagrant 설치 in OSX](https://junho85.pe.kr/1426)
- [vagrant 로 ubuntu/precise64 설치하기](https://junho85.pe.kr/1428)
