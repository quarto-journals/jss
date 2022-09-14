# Journal of Statistical Software (JSS)

This Quarto format will help you create documents for the Journal of Statistical Software. To learn more about the Journal of Statistical Software, see [https://www.jstatsoft.org](https://www.jstatsoft.org). For more about Quarto and how to use format extensions, see <https://quarto.org/docs/journals/>.

## Creating a New Article

You can use this as a template to create an article for the Journal of Statistical Software. To do this, use the following command:

```quarto use template quarto-journals/jss```

This will install the extension and create an example qmd file and bibiography that you can use as a starting place for your article.


## Installation For Existing Document

You may also use this format with an existing Quarto project or document. From the quarto project or document directory, run the following command to install this format:

```quarto install extension quarto-journals/jss```

## Usage 

To use the format, you can use the format names `jss-pdf` and `jss-html`. For example:

```quarto render article.qmd --to jss-pdf```

or in your document yaml

```yaml
format:
  pdf: default
  jss-pdf:
    keep-tex: true    
```

You can view a preview of the rendered template at <https://quarto-journals.github.io/jss/>. 

## Format Options

The JSS format supports a number of options for customizing the format and appearance of the document. Specify these under the `journal` key.

---

**`type`**

`article` - default, for JSS article.

`codesnippets` - for JSS code snippets.

`bookreview` - for JSS book reviews.

`softwarereview` - for JSS software reviews.

---

**`cite-shortnames`**

Set to `true` to disable citations with all names globally.

--

**`suppress`**

List of:

`title` - suppress the automatic `\maketitle` at the beginning of the document.

`headings` - suppress headings on the pages.

`footer` - suppress the automatic `\makefooter` at the end of the document.

--

**`include-jss-default`**

Set to `false` to suppress JSS header and footer.

--

For example:

```yaml
format:
  jss-pdf:
    keep-tex: true
    journal:
      type: bookreview
      cite-shortnames: true
      suppress: [title]
      include-jss-default: false
```