# slsa-verifier

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-slsa-verifier@slsa-verifier

      - name: check executable
        shell: bash
        run: slsa-verifier --help
```