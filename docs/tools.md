# Required Tools

To use shared code for cloud framework, you will need a number of tools installed. This document is a guide on how to install these tools and keep them updated.

## Supported Operating Systems
Our framework is designed to work in Linux and MacOS. We target MacOS as the primary development environment, so we have scripts to help you to keep some tools we use up to date

## Installing Base tools
You must first install these tools manually:

### Git
All the projects we develop and support are stored in Git.

* For instructions on installing Git, go to https://git-scm.com

### Google Cloud SDK
* Install **gcloud** SDK (includes ) with the following instructions:
  * https://cloud.google.com/sdk/downloads
* Update with ```$ gcloud components update```. We recommend regularly running this command.

### Kubernetes CLI (kubectl)
**kubectl** is installed via **gcloud** tool. To install do:
* ```$ gcloud components install kubectl```
* `kubectl` is also updated with `gcloud components update`

### envsubst
The easiest way to install envsubst for MacOS is via brew (a MacOS package manager). [Install brew](https://brew.sh/) and do the following:

* ```$ brew install gettext```

**envsubst** is already available in most Linux environments.

## Installing/updating all other tools
### Mac OS
After you have the base tools, you can install the rest of the required tools by navigating to a project directory with a `Makefile` and typing:
* ```$ make deps```

```$ make deps``` will update your tools to the correct versions (*except* for the **base tools** detailed above)

### Linux or other OS
You can still type `$ make deps` in Linux, but instead of automatically installing binaries, it will tell you what URLs to go to for the remainder of the tools

### Checking versions
To make sure you have the right versions of the required tools, you can use `make deps-check`

## Complete Required tools List
### MacOS
See [dependencies/deps-mac.txt](dependencies/deps-mac.txt)

### Linux or other OS
See [dependencies/deps-other.txt](dependencies/deps-other.txt)
