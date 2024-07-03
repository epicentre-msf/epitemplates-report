# epitemplates-report

EpiDS templates for quarto documents and presentations in mutiple formats

### Installation and usage

To use this custom format, first install the extension at the root directory of your project:

```bash
quarto add epicentre-msf/epitemplates-report
```

And add the format to your YAML configuration, along with other HTML format options if needed:

```yaml
format:
    epicentre-report-html:
        toc: true
        toc-depth: 3
```

Alternatively, you can also use the [epitemplates](https://github.com/epicentre-msf/epitemplates) R package from within R/Rstudio.
The template provides different formats, presented bellow.

### Formats

<div align="center">

**`epitemplates-report-html`: html document**

![html screenshot](screenshots/html_document.png)

**`epitemplates-report-pdf`: pdf document**

![pdf screenshot](screenshots/pdf_document.png)

**`epitemplates-report-docx`: word document**

![word screenshot](screenshots/word_document.png)

**`epitemplates-report-pptx`: powerpoint presentation**

![word screenshot](screenshots/pptx_presentation.png)

**`epitemplates-report-revealjs`: revealjs presentation**

![word screenshot](screenshots/revealjs_presentation.png)
</div>