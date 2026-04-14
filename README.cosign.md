# cosign

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-cosign@cosign

      - name: check executable
        shell: bash
        run: cosign --help
```