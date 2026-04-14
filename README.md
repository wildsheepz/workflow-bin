# workflow-bin

This repository provides GitHub Actions for setting up various executables in GitHub Actions workflows.

## How it works

- **Template Branch (`default`):** The default branch contains the template for creating new executable setup actions.
- **Executable Branches:** Each supported executable is maintained in its own dedicated branch.
- **Setup Action:** Each branch contains a `setup-<executable>` folder, which is a GitHub Action designed to add the specific executable to the GitHub path.

## The `run.sh` Utility

Each setup folder contains a `run.sh` script used to manage the lifecycle of the executable's binaries within this repository. It supports the following commands:

- `download`: Fetches the latest release metadata and binary archives from the upstream repository.
- `verify`: Validates the integrity and authenticity of the downloaded binaries (e.g., using `cosign` or `slsa-verifier` or by hash comparison).
- `extract`: Unpacks and/or copies the binary into the appropriate directory.
- `store`: Copies the necessary archives and checksum files into the `setup-<executable>` directory to be committed to the branch.

## Supported Tools

The following tools are maintained in their respective branches. Click the links to view the documentation and configuration for each:

- [`betterleaks`](https://github.com/wildsheepz/workflow-bin/tree/betterleaks/README.betterleaks.md)
- [`cosign`](https://github.com/wildsheepz/workflow-bin/tree/cosign/README.cosign.md)
- [`grype`](https://github.com/wildsheepz/workflow-bin/tree/grype/README.grype.md)
- [`helm`](https://github.com/wildsheepz/workflow-bin/tree/helm/README.helm.md)
- [`helmfile`](https://github.com/wildsheepz/workflow-bin/tree/helmfile/README.helmfile.md)
- [`osv-scanner`](https://github.com/wildsheepz/workflow-bin/tree/osv-scanner/README.osv-scanner.md)
- [`poutine`](https://github.com/wildsheepz/workflow-bin/tree/poutine/README.poutine.md)
- [`slsa-verifier`](https://github.com/wildsheepz/workflow-bin/tree/slsa-verifier/README.slsa-verifier.md)
- [`yq`](https://github.com/wildsheepz/workflow-bin/tree/yq/README.yq.md)

## Usage

To use an action from this repository, reference the specific branch for the executable you need:

```yaml
- name: Setup My Executable
  uses: wildsheepz/workflow-bin/setup-<executable>@<branch-name>
```
