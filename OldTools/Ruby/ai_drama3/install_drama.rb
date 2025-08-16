#!/usr/bin/env ruby
# ���������ɥ���ѤΥե�����򥳥ԡ�����
# ���饤����Ȥ������Ѥ˻ȤäƤ���CSV�ե�����򹹿����롣
# 
# ��: ����ɥ�ޤο��ȥڡ������ϥ�����¦�Ǥ��������Ƥ��롣
# ���٤ϥ��饤����Ⱦ�ǥɥ�ޤ�������ʤ��ȡ�
# �ե�����򥳥ԡ����Ƥ⥯�饤����Ȥ��������Ǥ��ʤ���
# ���ΤȤ�����������ɥ�ޤ϶��äݤǤ��ɤ�(�ɥ�ޥե����뤬����Ȥ������¤�
# �����Ф˵�Ͽ�����н�ʬ)��

require 'fileutils'
require 'nkf'

author = '�ʤʤ�'

dir = ARGV.shift
drama_list = ARGV

drama_list.each_index do |i|
  drama = drama_list[i]
  print "Copying #{drama} #{i}\n"
  FileUtils.cp("#{drama}/datalist_0.txt", "#{dir}/datalist_#{i}.txt")
  FileUtils.cp("#{drama}/drama_0.csv", "#{dir}/drama_#{i}.csv")
end

list = ['#̾��,��������,���ѻ���,ID,��å�,�������,���̾,������,�������,����,����ʸ,']
drama_list.each_index do |i|
  drama = drama_list[i]
  mtime = File.mtime("#{drama}/drama_0.csv").to_i
  # �������=2, ���=�ʤʤ�, ������=�ƥ���, �������0, ����
  list << ["#{drama},#{mtime},0,#{i},0,2,#{author},6,0,1,,"]
end
list << ''

open("#{dir}/list.csv", "wb") do |out|
  out.print NKF.nkf("-w16L -c", list.join("\n"))
end
