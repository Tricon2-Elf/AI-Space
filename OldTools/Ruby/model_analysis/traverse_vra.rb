#!/usr/bin/env ruby
# unpacked�ǥ��쥯�ȥ��ȥ�С�������vra�ե������õ����
# dxg�ե�����ؤλ��ȴط�����Ϥ��롣

require 'libvra'
require 'find'

def parse_dxg(vra, vraobj, dxglist, dxgref)
  nodeobj = vraobj.get_child('attribute')
  return if nodeobj == nil
  attrobj = nodeobj.get_attr('Geometry')
  return if attrobj == nil

  dxg = attrobj.values[0].gsub('\\', '/')
  dxglist[vra] = [dxg]

  if dxgref.has_key?(dxg)
    dxgref[dxg] << vra
  else
    dxgref[dxg] = [vra]
  end
end

def parse_tex(vra, vraobj, texlist, texref)
  if vraobj.name == 'diffuse'
    attrobj = vraobj.get_attr('fname')
    if attrobj != nil
      
      tex = attrobj.values[0].gsub('\\', '/')
      if texlist.has_key?(vra)
	texlist[vra] << tex
      else
	texlist[vra] = [tex]
      end
      if texref.has_key?(tex)
	texref[tex] << vra
      else
	texref[tex] = [vra]
      end
    end
  end

  vraobj.children.each do |child|
    parse_tex(vra, child, texlist, texref)
  end
end

def traverse(basepath)
  dxglist = Hash.new # dxglist[vra] = [dxg]�Ȥʤ�ϥå���
  dxgref = Hash.new # dxgref[dxg] = [vra]�Ȥʤ�ϥå���
  texlist = Hash.new # texlist[vra] = [tex]�Ȥʤ�ϥå���
  texref = Hash.new # texref[tex] = [vra]�Ȥʤ�ϥå���

  Find.find(basepath) do |path|
    # vra�ե����������ȥ�С���
    next unless path =~ /\.vra$/
    next unless path =~ /\/attr\//
    vra = path[basepath.length, path.length]
    STDERR.print "Evaluating #{vra}...\r"

    # VraNode���֥������Ȥ���������dxg�����tex�ؤλ��Ȥ�Ͽ
    vraobj = VraNode::load(path)
    parse_dxg(vra, vraobj, dxglist, dxgref)
    parse_tex(vra, vraobj, texlist, texref)
  end
  STDERR.print "Evaluation done\n"

  print "### Refereneces from vra to dxg ###\n"
  dxglist.keys.sort.each do |vra|
    print "#{vra} refers\n"
    dxglist[vra].sort.each do |dxg|
      print "\t#{dxg}\n"
    end
  end

  print "### Refereneces for dxg from vra ###\n"
  dxgref.keys.sort.each do |dxg|
    print "#{dxg} referred by\n"
    dxgref[dxg].sort.each do |vra|
      print "\t#{vra}\n"
    end
  end

  print "### Refereneces from vra to tex ###\n"
  texlist.keys.sort.each do |vra|
    print "#{vra} refers\n"
    texlist[vra].sort.each do |tex|
      print "\t#{tex}\n"
    end
  end

  print "### Refereneces for tex from vra ###\n"
  texref.keys.sort.each do |tex|
    print "#{tex} referred by\n"
    texref[tex].sort.each do |vra|
      print "\t#{vra}\n"
    end
  end
end

traverse ARGV[0]
