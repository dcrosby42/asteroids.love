require "stringio"

module LuaFormatter
  extend self

  def generate(x, indent_level: 0, indent: "  ", io: nil, in_list: false, in_hash: false)
    made_stringio = false
    if not io
      io = StringIO.new
      made_stringio = true
    end
    io ||= StringIO.new
    append = ->s { io << s }
    endl = -> { append["\n"] }
    appendl = ->s { append[s]; endl[] }

    # line = lambda do append["#{pref}#{s}\n"] end
    indent_in = -> { indent_level += 1 }
    indent_out = -> { indent_level -= 1 }
    pref = -> { indent * indent_level }
    do_indent = -> { io << pref[] }

    if in_list
      do_indent[]
    end
    case x
    when Numeric, String, true, false, nil
      append[x.inspect]
    when Array
      appendl["{"]
      indent_in[]
      x.each do |val|
        generate val, indent_level: indent_level, indent: indent, io: io, in_list: true
        append[","]
        endl[]
      end
      indent_out[]
      do_indent[]
      append["}"]
    when Proc.new { |n| n.respond_to?(:to_h) }
      appendl["{"]
      indent_in[]
      x.to_h.each do |key, val|
        do_indent[]
        append[key]
        append[" = "]
        generate val, indent_level: indent_level, indent: indent, io: io, in_hash: true
        append[","]
        endl[]
      end
      indent_out[]
      do_indent[]
      append["}"]
    end
    if made_stringio
      io.string
    end
  end
end

# puts LuaFormatter.generate(42)
# puts LuaFormatter.generate(nil)
# puts LuaFormatter.generate(1.234)
# puts LuaFormatter.generate("Duder")
# puts LuaFormatter.generate(true)
# puts LuaFormatter.generate(false)
# puts LuaFormatter.generate({ a: 1, b: true, c: "hello", d: { e: 42, f: ["interestin", "choice"] } })