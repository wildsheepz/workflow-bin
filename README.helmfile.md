# helmfile

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-helmfile@helmfile

      - name: check executable
        shell: bash
        run: helmfile --help
```