# grype

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-grype@grype

      - name: check executable
        shell: bash
        run: grype --help
```