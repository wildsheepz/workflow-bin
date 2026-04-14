# helm

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-helm@helm

      - name: check executable
        shell: bash
        run: helm --help
```