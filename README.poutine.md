# poutine

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-poutine@poutine

      - name: check executable
        shell: bash
        run: poutine --help
```