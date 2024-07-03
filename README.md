# epitemplates-report

`epitemplates-report` provides
epicentre templates for quarto documents in mutiple formats

## Installation and Usage

To use this custom format, first install the extension at the root directory of your project:

```bash
quarto add epicentre_msf/epitemplates-report
```

And add the format to your YAML configuration, along with other HTML format options if needed:

```yaml
format:
    epicentre-report-html:
        toc: true
        toc-depth: 3
```

Alternatively, you can also use the [epitemplates]() R package from within R.

The templates provide differents formats, presented bellow.

## Screenshots

<div align="center">

**`epitemplates-report-html`: Single html document**

![html screenshot](screenshots/html_document.png)


</div>