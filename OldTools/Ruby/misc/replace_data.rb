#!/usr/bin/env ruby
# データファイル(chara, item, field)の中身を置き換える。
# 元のファイルは、.backupをつけた名前で退避される。

require 'fileutils'

def id_to_path(type, id)
  case type
  when 'chara'
    id = id / 10
    return sprintf("chara/%01d/%05d", id / 100000, id % 100000)
  when 'item'
    return sprintf("item/%01d/%02d/%05d",
		   id / 100000 / 100, (id / 100000) % 100, id % 100000)
  when 'field'
    return sprintf("world/field/%s", id)
  else
    raise "不明なタイプ: #{type}"
  end
end

def make_backup(dir, backup)
  if not File.directory?(backup)
    print "Making backup of #{dir}...\n"
    FileUtils.cp_r(dir, backup, {:preserve => true})
  end
end

def make_dummy(dir, backup)
  print "Making dummy files in #{dir}...\n"
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)
  Dir::entries(backup).each do |entry|
    next unless FileTest::file?("#{backup}/#{entry}")
    next if entry =~ /\.backup$/
    FileUtils.touch("#{dir}/#{entry}")
  end
end

def replace_gen(basedir, type, virtid, realid)
  case type
  when 'chara'
    subdirs = ['anim', 'attr', 'face', 'model', 'tex']
  when 'item'
    subdirs = ['attr']
  end

  subdirs.each do |subdir|
    virtdir = basedir + "/" + id_to_path(type, virtid) + "/" + subdir
    realdir = basedir + "/" + id_to_path(type, realid) + "/" + subdir
    virtbak = "#{virtdir}.backup"

    # まだ取ってなければ、元のディレクトリをバックアップ
    make_backup(virtdir, virtbak)

    # もともとあったファイルは、いったん空のファイルとして作成
    #make_dummy(virtdir, virtbak)

    return if realid == -1

    # 実ファイルを仮のファイルにコピー
    # このとき、プレフィックスがID値に一致していたらファイル名を置き換える
    case type
    when 'chara'
      rprefix = (realid / 10).to_s
      vprefix = (virtid / 10).to_s
    when 'item'
      rprefix = realid.to_s
      vprefix = virtid.to_s
    end

    Dir::entries(realdir).each do |realfile|
      next unless FileTest.file?("#{realdir}/#{realfile}")
      next if realfile =~ /\.backup$/

      if realfile[0, rprefix.length] == rprefix
	virtfile = vprefix + realfile[rprefix.length, 1000]
      else
	virtfile = realfile
      end

      print "Copying #{realdir}/#{realfile}\n"
      print "   into #{virtdir}/#{virtfile}\n"
      FileUtils.rm_f("#{virtdir}/#{virtfile}")
      FileUtils.cp("#{realdir}/#{realfile}", "#{virtdir}/#{virtfile}")
    end
  end
end

def replace_field(basedir, type, virtid, realid)
  raise "type != 'field'" if type != 'field'
  raise "virtid != 'R01'" if virtid != 'R01'

  virtdir = basedir + "/" + id_to_path(type, virtid)
  realdir = basedir + "/" + id_to_path(type, realid)
  virtbak = "#{virtdir}.backup"
  make_backup(virtdir, virtbak)

  ['.', 'attr', 'model', 'tex'].each do |subdir|
    make_dummy("#{virtdir}/#{subdir}", "#{virtbak}/#{subdir}")
  end

  # 実ファイルを仮のファイルにコピー
  # A11/A11_01.obj <- R01/R01_nn.obj
  (1..4).each do |n|
    ['.vra', '_obj.vra'].each do |postfix|
      virtfile = sprintf('%s_%02d%s', virtid, n, postfix)
      realfile = sprintf('%s_01%s', realid, postfix)
      print "Copying from #{realdir}/#{realfile}\n"
      print "          to #{virtdir}/#{virtfile}\n"
      FileUtils.rm_f("#{virtdir}/#{virtfile}")
      FileUtils.cp("#{realdir}/#{realfile}", "#{virtdir}/#{virtfile}")
    end
  end
end

def show_help_and_exit
  print "Usage:\n"
  print "\truby replace.rb [item|chara|field] virt real\n"
  exit 1
end

def main
  basedir = 'unpacked'
  show_help_and_exit if ARGV.length < 3
  case ARGV[0]
  when 'chara', 'item'
    replace_gen(basedir, ARGV[0], ARGV[1].to_i, ARGV[2].to_i)
  when 'field'
    replace_field(basedir, ARGV[0], ARGV[1], ARGV[2])
  end
end

main
