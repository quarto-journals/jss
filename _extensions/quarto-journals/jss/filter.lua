


local texMappings = {
  "proglang",
  "pkg",
  "fct",
  "class"
}

return {
  {
    Span = function(el) 
      -- read the span contents and emit correct output
      local contentStr = pandoc.utils.stringify(el.content)

      for i, mapping in ipairs(texMappings) do
        if #el.attr.classes == 1 and el.attr.classes:includes(mapping) then
            if quarto.doc.isFormat("pdf") then
                return pandoc.RawInline("tex", "\\" .. mapping .. "{" .. contentStr .. "}" )
            else 
                return pandoc.Code(contentStr);
            end
        end
      end
    end
  }
}