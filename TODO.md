## Open Issues

### Tables
- Tables are not currently globally centered.
- Tables are not currently placed at the top of the page by default.

In order to fix the above, we will need Quarto to either expose table options or we'll need to likely use a LaTeX post processor to fix up tables (trying to fix this in a filter is challenge since we will need to deal with all sorts of table representations).

### Section Titles
- We don't currently have a way to write 'plain' section LaTeX
- `short-title.lua` does this for rticles, but generating the sections results in Quarto cross referencing being evaded (because we transform the headings into raw tex)
- will likely need Quarto to add suppot for this.

### Authors
- We're currently outputing authors without addresses / affiliations in the bottom section
- The address output doesn't quite match the template

### Appendixes
- We're not properly numbering the appendixes (e.g. should have letters/be proper appendix rather than being unnumbered)
