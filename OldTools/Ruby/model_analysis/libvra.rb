#!/usr/bin/env ruby
# vraファイルの解析用ライブラリ

# ノード階層
#    vra
#    +-geometry
#    | +-mesh
#    |   +-lod0
#    +-material_set
#    | +-material
#    |   +-texture
#    |   +-diffuse
#    |   +-param_block
#    +-attribute
#    +-dynamics_set
#      +-collision
#      +-dynamics
#        +-joint
#        +-connect

#----------------------------------------------------------------------

# ノード属性を表すクラス
class Attr
  attr_reader :name
  attr_reader :basetype
  attr_reader :values

  # 文字列を解析してAttrインスタンスを返すファクトリメソッド
  def self.parse(s)
    if s =~ /^\s*\((\w+)\s+(\w+)\[(\d+)\]\s+(.*?)\s*,?\s*\)$/
      name = $1; basetype = $2; nr = $3.to_i; args = $4

      values = (nr > 1) ? args.split(',', nr) : [args]
      # TODO: 引用符中にカンマがある場合
      case basetype
      when 'int32', 'int16', 'int8'
        values.map! {|x| x.to_i}
      when 'float'
        values.map! {|x| x.to_f}
      when 'string'
        values.map! {|x| x[1 .. -2]}
      end
      return Attr.new(name, basetype, values)
    else
      raise "Attr::parse: cannot match: #{s}"
    end
  end

  private
  # 例えば(fname string[1] "path")に対しては、
  # Attr.new("fname", "string", ["path"])
  def initialize(name, basetype, values)
    @name = name
    @basetype = basetype
    @values = values
  end
end

#----------------------------------------------------------------------
# ノード

class VraNode
  private

  # コンテクスト
  class Context
    attr_reader :lines, :i
    attr_accessor :nodestack
    public

    def initialize(lines)
      @lines = lines
      @i = 0
      @nodestack = []
    end

    def push_node(node_name, parent_node)
      child = VraNode.new(node_name, parent_node)
      if parent_node != nil
	parent_node.children << child
      end
      @nodestack.unshift(child)
    end

    def pop_node
      @nodestack.shift
    end

    def add_attr(attr)
      @nodestack[0].attrs << attr
    end

    def gets
      s = @lines[@i]
      @i = @i + 1
      return s
    end

    def unget
      @i = @i - 1
    end

    def eof
      return @i >= @lines.length
    end
  end

  public
  attr_reader :name
  attr_reader :parent
  attr_reader :children
  attr_reader :attrs

  # vraファイルを読んでそのルートノードを返すファクトリメソッド
  def self.load(path)
    # コンテクスト作成
    lines = get_preprocessed_lines(path)
    ctx = Context.new(lines)

    # ルートノードをコンテクストにプッシュ
    ctx.push_node('vra', nil)

    # ルートノードを解析
    parse(ctx)
    node = ctx.nodestack[0]

    # コンテクストを清算して、ノードを返す
    ctx.pop_node
    die "VraNode.load: stack not empty" if ctx.nodestack.length != 0
    return node
  end

  # 整形して出力
  def pp(depth = 0)
    indent = "  " * depth
    print "#{indent}Node: #{@name}\n"
    @attrs.each do |a|
      print "#{indent}  attr #{a.name} #{a.basetype}[#{a.values.length}] #{a.values.to_s}\n"
    end
    @children.each do |c|
      c.pp(depth + 1)
    end
  end

  def get_child(node_name)
    @children.each do |c|
      next if node_name != c.name
      return c
    end
    return nil
  end

  def get_attr(attr_name)
    @attrs.each do |a|
      next if attr_name != a.name
      return a
    end
    return nil
  end

  def [](key)
    # node['child_node_name'] = child_node
    return get_child(key)
  end

  def find_node(path)
    node = self
    path.split('/').each do |elem|
      node = node[elem]
      return nil if node == nil
    end
    return node
  end

  private

  DEBUG = false

  def initialize(name, parent)
    @name = name
    @parent = parent
    @children = []
    @attrs = []
  end

  # コンテクストに基づいてノードを読み込む
  def self.parse(ctx)
    while !ctx.eof
      s = ctx.gets

      if DEBUG
	nodehier = ctx.nodestack.map {|x| x.name}.reverse.join('.')
	print "Current node: #{nodehier}\n"
	print "Input: #{s}\n"
      end

      if s =~ /^\s*\{(\w+)$/
        # 新しい子ノードの開始
        ctx.push_node($1, ctx.nodestack[0])
	parse(ctx) # 再帰呼び出し
        ctx.pop_node

      elsif s=~ /^\s*\}$/
	break

      elsif s =~ /^\s*(\(.*\))\s*$/
        # 現ノードに属性値を追加
        ctx.add_attr(Attr.parse($1))

      else
        raise "VraNode::parse: unrecognizable input: #{s}"
      end
    end
  end
    
  # ファイルから読み出して改行文字の削除と継続行の連結を行ったものを返す
  def self.get_preprocessed_lines(path)
    r = []
    open(path) do |ifp|
      cflag = false

      ifp.readlines.each do |line|
        line.chomp!
        if cflag
          r[-1] = r[-1] + line
          cflag = false if line =~ /\)\s*$/
        else
          r << line
          if (line =~ /\s*\(/) && !(line =~ /\)\s*$/)
            cflag = true
          end
        end
      end
    end
    return r
  end
end

def test
  rootnode = VraNode::load(ARGV[0])
  rootnode.pp
  p rootnode['material_set'].name
  p rootnode.find_node('material_set/material/texture').name
end

