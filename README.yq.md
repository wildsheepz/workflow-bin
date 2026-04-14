# yq

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-yq@yq

      - name: check executable
        shell: bash
        run: yq --help
```