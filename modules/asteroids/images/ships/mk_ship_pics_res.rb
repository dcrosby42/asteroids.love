#!/usr/bin/env ruby
$here = File.expand_path(File.dirname(__FILE__))
require "find"
require_relative "lua_formatter"

class ShipArranger
  def initialize
    @dir = $here
    @pref = @dir.split("/").take_while do |step| step != "modules" end.join("/") + "/"
  end

  def ship_pngs
    @pngs ||= begin
        paths = []
        Find.find(@dir) do |path|
          if path =~ /\.png$/
            # path[pref] = ""
            paths << path
          end
        end
        paths
      end
  end

  def module_path(path)
    mp = path.clone
    mp[@pref] = ""
    mp
  end

  def name(path)
    path.split("/")[-3..-1].join("/").downcase().gsub(/[\/ ]+/, "_").gsub(/\.\w+$/, "").gsub(/^ships/,"ship")
  end

  def to_res(path)
    {
      type: "pic",
      name: name(path),
      data: { path: module_path(path) },
    }
  end

  def all_res
    ship_pngs.map do |path| to_res(path) end
  end

  def to_lua
    "return #{LuaFormatter.generate(all_res)}"
  end

  def generate_file(fname)
    File.write(fname, to_lua)
    puts "Wrote #{fname}"
  end
end

sa = ShipArranger.new
# puts sa.to_lua()
sa.generate_file("#{$here}/ship_pics.res.lua")
# puts(sa.ship_pngs.map do |x| sa.name(x) end)
