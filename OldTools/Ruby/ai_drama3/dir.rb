#!/usr/bin/env ruby
# カメラ座標のyawを確認する。
# dirNというプリセット値が必要(rewrite_adv_presets.rb参照)

require 'libdrama.rb'

MAP_LIST = [
  "ダ・カーポ島\\風見学園",
  "クラナド島\\光坂高校",
  "シャッフル島\\バーベナ学園",
]

def generate_data
  print "[ACTOR]\n"
end

NAVI_MG = 0
AXIS_MG = 1
DIR_MAX = 30

def get_state(cat, map, dir, menuitem = 0)
  return ((cat * 100 + map) * 100 + dir) * 10 + menuitem
end

def get_navi_state(menuitem = 0)
  return get_state(-1, 0, 0, menuitem)
end

def get_dir_state(map, dir, menuitem = 0)
  return get_state(0, map, dir, menuitem)
end

def generate_drama

  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: dir.rb,v $, $Revision: 1.3 $')
  Drama.indent do
    # マップデータはいずれにしろ読み直すので、ここでは軽いマップを選ぶ
    Drama.map('その他\\アバターメイク', 'day')
    Drama.cam('その他\\アバターメイク', 'z120')
    Drama.transit_fsm_state(get_navi_state())
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # ナビ
  nrStates = 0
  Drama.selection_menu("マップ選択",
		       get_navi_state(),
		       MAP_LIST.map{|x| x.sub(/\\/,'/')}) do |minfo|
    Drama.map(MAP_LIST[minfo.selection], 'day')
    Drama.cam(MAP_LIST[minfo.selection], 'dir15')
    Drama.transit_fsm_state(get_dir_state(minfo.selection, 15))
  end

  # 方向
  MAP_LIST.each_index do |map_index|
    map = MAP_LIST[map_index]
    (0..DIR_MAX).each do |dir|
      rotr = (dir + 1 + DIR_MAX) % DIR_MAX
      rotl = (dir - 1 + DIR_MAX) % DIR_MAX
      menu_list = [
	"右を向く: #{dir}→#{rotr}",
	"左を向く: #{dir}→#{rotl}",
	"マップ選択に戻る"]

      Drama.selection_menu("#{map}/dir#{dir}",
			   get_dir_state(map_index, dir),
			   menu_list) do |minfo|
	    case minfo.selection
	    when 0 # 右
	      Drama.cam(map, "dir#{rotr}")
	      state = get_dir_state(map_index, rotr, minfo.selection)
	      Drama.transit_fsm_state(state)

	    when 1 # 左
	      Drama.cam(map, "dir#{rotl}")
	      state = get_dir_state(map_index, rotl, minfo.selection)
	      Drama.transit_fsm_state(state)

	    else 
	      Drama.transit_fsm_state(get_navi_state(map_index))
	    end
      end
    end
  end

  Drama.catch_all do
    Drama.amsg("FSM異常", "エラー")
  end

  Drama.end_fsm_block
  Drama.page_footer
end

if ARGV[0] == "-data"
  generate_data
else
  generate_drama
end
