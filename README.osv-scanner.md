# osv-scanner

## Usage

``` yaml
    steps:
      - name: run action
        uses: wildsheepz/workflow-bin/setup-osv-scanner@osv-scanner

      - name: check executable
        shell: bash
        run: osv-scanner --help
```