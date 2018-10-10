# General Usage

CGW is build as a [Helm Chart](https://docs.helm.sh/developing_charts).
Therefore I will guide how to use CGW with Helm to be able to deploy it.

For deeper understanding of how Helm works, please read the [Helm documentation](https://docs.helm.sh/)

## Install Helm

Please make sure you have Helm installed on your machine as well as its server component, *Tiller*,
on your cluster.

On macOS you can use `brew` to install helm:

```sh
$ brew install kubernetes-helm
```

On Linux have a look, if it is available via the package manager or follow the instructions
[installing Helm](https://docs.helm.sh/using_helm/#installing-helm) upstream.

## get a version of CGW

### using the repository

If the travelping internal chart repository is available to you, please update your helm repos:

```sh
$ helm repo update
```

Then you can verify, that CGW is available:

```sh
$ helm search cgw
```

Because the repository can be installed with different names, I will refer to it as `tp`.
My result is the following:

```
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
tp/cgw                          0.7.0-alpha.6                   A Helm chart for Kubernetes
```

Therefore the name of the chart will be `tp/cgw`.

#### installing development versions

By default, Helm will just use versions, which are no development versions.
Therefore when using for example `helm install -f myvalues.yaml tp/cgw` to install CGW,
it will use the last stable version.

To use a development version, you have to use either:

```sh
helm install -f myvalues.yaml --devel tp/cgw
```

Or specify the version directly:

```sh
helm install -f myvalues.yaml --version 0.7.0-alpha.6 tp/cgw
```

### using git

If the repsitory is not available to you, you can just clone the repository and checkout the latest version:

```sh
$ git clone https://github.com/openvnf/cgw.git
$ cd cgw
$ git checkout v0.7.0-alpha.2
```

Now you can use `.` as the chart path, meaning the local directory.

Throughout this documentation I will use `tp/cgw` as the chart, which you have to exchange with the folder, like `.`.

## install CGW on your cluster

Because there are plenty deployment models for CGW, it is not possible to create a minimum valuable configuration
as a default.

The [configuration documentation](../../README.md#configuration) will guide you through the creation of configurations.
If you just get the job done and already know the basics you can also follow the [How Tos](../howtos/howtos.md).

After you have created your configuration, just install the CGW as follows when using the Helm repository:

```sh
$ helm install -f <path to your configuration> -n <name of your deployment> --namespace <namespace> tp/cgw
```

If you want to use a specific version, you can add `--version <version>`.

## upgrade CGW on your cluster

If you changed your configuration, you can apply it to an existing deployment:

```sh
$ helm upgrade -f <path to your configuration> <name of your deployment> tp/cgw
```

`--version <version>` can also be used to match the desired one.


