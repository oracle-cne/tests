# Oracle Cloud Native Environment Integration Test Suite

Integration tests for the Oracle Cloud Native Environment platform and its
components live here.

## Documentation

These test require at least BATS 1.10

The structure of this suite is to run a common set of tests aginst a set of
cluster configuration.  Every test in this suite is run against each
configuration, for a total of (tests * configurations) assertions.

To run some tests, at least one test configuration is required.  Each test
configuration is a directory that contains a specific set of files:

* info.yaml - high level metadata about the test
  * provider - the cluster provider
  * version - the Kubernetes version
  * skip - If set to `true`, the test runner will skip this scenario
* defaults.yaml - A defaults.yaml to use as the defaults.
* clusterConfig.yaml - The cluster configuration file that defines the cluster.

Test configurations must be placed in a directory that contains only test
configurations.

Tests can be run like so:

`./run_tests.sh <tests-directory>`

The test runner also accept a regular expression to select a subset of tests


`./run_tests.sh <tests-directory> <selection-regex>`

The suite automatically configures an output directory for instrumented `ocne`
builds.  Instrumented builds can be generated by cloning
https://www.github.com/oracle-cne/ocne and running `make build-cli-instrumented`

### Built-In Configurations

This suite provides two sets of built-in configurations.  One of them has two
deployments and is useful as a quick sanity test.  The other is a substantial
library of deployments based around the `libvirt` provider.  That set of
cluster configurations gives good coverage for Oracle Cloud Native Environment
as a platform without having to invest resources into deploying and maintaing
the infrastructure for the other providers.

To run the sanity tests:
```
$ ./run_tests.sh ./scenarios/sanity
```

To run the libvirt tests:
```
# If this is the first time, run the environment setup
# script.  This script defines a couple networks that are
# used by the configuration set
$ ./scenarios/libvirt/environment/setup.sh

$ ./run_tests.sh ./scenarios/libvirt

# To remove the test infrastructure, run the following
# script.  This is not essential, and should only be done
# if you no longer intend to use the system for testing
# or just enjoy being tidy.
$ ./scenarios/libvirt/environment/unsetup.sh
```

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md)

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2025, Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
