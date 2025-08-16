#!/usr/bin/env ruby
# 作成したドラマ用のファイルをコピーし、
# クライアントが管理用に使っているCSVファイルを更新する。
# 
# 注: 自作ドラマの数とページ数はサーバ側でも管理されている。
# 一度はクライアント上でドラマを作成しないと、
# ファイルをコピーしてもクライアントからは選択できない。
# このとき、作成するドラマは空っぽでも良い(ドラマファイルがあるという事実が
# サーバに記録されれば十分)。

require 'fileutils'
require 'nkf'

author = 'ななし'

dir = ARGV.shift
drama_list = ARGV

drama_list.each_index do |i|
  drama = drama_list[i]
  print "Copying #{drama} #{i}\n"
  FileUtils.cp("#{drama}/datalist_0.txt", "#{dir}/datalist_#{i}.txt")
  FileUtils.cp("#{drama}/drama_0.csv", "#{dir}/drama_#{i}.csv")
end

list = ['#名称,取得時間,使用時間,ID,ロック,使用枚数,作者名,ジャンル,販売価格,公開,説明文,']
drama_list.each_index do |i|
  drama = drama_list[i]
  mtime = File.mtime("#{drama}/drama_0.csv").to_i
  # 使用枚数=2, 作者=ななし, ジャンル=テスト, 販売価格0, 公開
  list << ["#{drama},#{mtime},0,#{i},0,2,#{author},6,0,1,,"]
end
list << ''

open("#{dir}/list.csv", "wb") do |out|
  out.print NKF.nkf("-w16L -c", list.join("\n"))
end
