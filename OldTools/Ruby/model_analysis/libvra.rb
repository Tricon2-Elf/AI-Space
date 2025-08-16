#!/usr/bin/env ruby
# vra�ե�����β����ѥ饤�֥��

# �Ρ��ɳ���
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

# �Ρ���°����ɽ�����饹
class Attr
  attr_reader :name
  attr_reader :basetype
  attr_reader :values

  # ʸ�������Ϥ���Attr���󥹥��󥹤��֤��ե����ȥ�᥽�å�
  def self.parse(s)
    if s =~ /^\s*\((\w+)\s+(\w+)\[(\d+)\]\s+(.*?)\s*,?\s*\)$/
      name = $1; basetype = $2; nr = $3.to_i; args = $4

      values = (nr > 1) ? args.split(',', nr) : [args]
      # TODO: ��������˥���ޤ�������
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
  # �㤨��(fname string[1] "path")���Ф��Ƥϡ�
  # Attr.new("fname", "string", ["path"])
  def initialize(name, basetype, values)
    @name = name
    @basetype = basetype
    @values = values
  end
end

#----------------------------------------------------------------------
# �Ρ���

class VraNode
  private

  # ����ƥ�����
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

  # vra�ե�������ɤ�Ǥ��Υ롼�ȥΡ��ɤ��֤��ե����ȥ�᥽�å�
  def self.load(path)
    # ����ƥ����Ⱥ���
    lines = get_preprocessed_lines(path)
    ctx = Context.new(lines)

    # �롼�ȥΡ��ɤ򥳥�ƥ����Ȥ˥ץå���
    ctx.push_node('vra', nil)

    # �롼�ȥΡ��ɤ����
    parse(ctx)
    node = ctx.nodestack[0]

    # ����ƥ����Ȥ��������ơ��Ρ��ɤ��֤�
    ctx.pop_node
    die "VraNode.load: stack not empty" if ctx.nodestack.length != 0
    return node
  end

  # �������ƽ���
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

  # ����ƥ����Ȥ˴�Ť��ƥΡ��ɤ��ɤ߹���
  def self.parse(ctx)
    while !ctx.eof
      s = ctx.gets

      if DEBUG
	nodehier = ctx.nodestack.map {|x| x.name}.reverse.join('.')
	print "Current node: #{nodehier}\n"
	print "Input: #{s}\n"
      end

      if s =~ /^\s*\{(\w+)$/
        # �������ҥΡ��ɤγ���
        ctx.push_node($1, ctx.nodestack[0])
	parse(ctx) # �Ƶ��ƤӽФ�
        ctx.pop_node

      elsif s=~ /^\s*\}$/
	break

      elsif s =~ /^\s*(\(.*\))\s*$/
        # ���Ρ��ɤ�°���ͤ��ɲ�
        ctx.add_attr(Attr.parse($1))

      else
        raise "VraNode::parse: unrecognizable input: #{s}"
      end
    end
  end
    
  # �ե����뤫���ɤ߽Ф��Ʋ���ʸ���κ���ȷ�³�Ԥ�Ϣ���Ԥä���Τ��֤�
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

