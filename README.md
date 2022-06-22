# Quarto Extension - Journal of Statistical Software

## Using the Template
If you'd like, you can use this as a template to create an article for the Journal of Statistical Software. To do this, use the following command:

```
quarto use template quarto-journals/jss
```

This will install the extension and create an example `qmd` file and bibiography that you can use as a starting place for your article.

## Using the Format Extension
You may also use this format with an existing Quarto project or document. From the quarto project or document directory, run the following command to install this format:

```
quarto install extension quarto-journals/jss
```

This will install the extension. To use the extension, you can use the format names:

- `jss-pdf`
- `jss-html`

For example:

```
quarto render article.qmd --to jss-pdf
```

or in your document yaml

```yaml
format:
  pdf: default
  jss-pdf:
    keep-tex: true    
```

Learn more at [https://www.jstatsoft.org](https://www.jstatsoft.org)
