#!/usr/bin/env ruby
# カメラ座標を確認する。
# xNyNdN, z120というプリセット値が必要(rewrite_adv_presets.rb参照)

require 'libdrama.rb'

MAP_TYPE = 'default'

MAP_DEFS = {
  "default" => {
    'desc' => "デフォルト",
    'list' => [
      "ダ・カーポ島\\風見学園",
      "クラナド島\\光坂高校",
      "シャッフル島\\バーベナ学園",
    ],
  },
  "town" => {
    'desc' => "商店街",
    'list' => [
      "ダ・カーポ島\\商店街",
      "クラナド島\\商店街",
      "シャッフル島\\商店街",
    ],
  },
  "classroom" => {
    'desc' => "教室",
    'list' => [
      "ダ・カーポ島\\風見学園教室",
      "クラナド島\\光坂高校教室",
      "シャッフル島\\バーベナ学園教室",
    ],
  },
  "akiba" => {
    'desc' => "アキバ",
    'list' => [
      "アキハバラ島\\アキハバラ",
      "アキハバラ島\\UDX",
    ],
  },
  "myroom" => {
    'desc' => "マイルーム",
    'list' => [
      "マイルーム\\マイルーム(6畳)",
      "マイルーム\\マイルーム(8畳)",
      "マイルーム\\マイルーム(10畳)",
      "マイルーム\\マイルーム(12.5畳)",
    ],
  },
  "hometown" => {
    'desc' => "住宅街",
    'list' => [
      "ダ・カーポ島\\住宅街",
      "クラナド島\\住宅街",
      "シャッフル島\\住宅街",
    ],
  },
  "misc1" => {
    'desc' => "その他1",
    'list' => [
      "その他\\ステージ",
      "その他\\撮影用",
      "その他\\アバターメイク",
    ],
  },
  "misc2" => {
    'desc' => "その他1",
    'list' => [
      "その他\\電車内",
      "その他\\外神田ビル内",
      "その他\\違反者隔離部屋",
      "その他\\テスト",
    ],
  },
}

def generate_data
  print "[ACTOR]\n"
  print "0,,doll,2022011,0,0,10100010,10200000,10400000,10500040,10600010,10700010,\n"
  print "1,,doll,2022021,0,0,10100010,10200000,10400000,10500040,10600010,10700010,\n"
  print "2,,doll,2022031,0,0,10100010,10200000,10400000,10500040,10600010,10700010,\n"
end

NAVI_MG = 0
AXIS_MG = 1
XY_MAX = 9

def get_state(cat, map, x, y, yaw, menuitem = 0)
  return ((((cat * 10 + map) * 10 + x) * 10 + y) * 10 + yaw) * 10 + menuitem
end

def get_navi_state(menuitem = 0)
  return get_state(-1, 0, 0, 0, 0, menuitem)
end

def get_move_state(map_index, x, y, yaw, menuitem = 0)
  return get_state(0, map_index, x, y, yaw, menuitem)
end

def generate_drama
  map_list = MAP_DEFS[MAP_TYPE]['list']

  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: map.rb,v $, $Revision: 1.4 $')
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
                       map_list.map{|x| x.sub(/\\/,'/')}) do |minfo|
    Drama.map(map_list[minfo.selection], 'day')
    Drama.cam(map_list[minfo.selection], "x4y4d0")
    Drama.transit_fsm_state(get_move_state(minfo.selection, 4, 4, 0))
  end

  # 移動
  map_list.each_index do |map_index|
    map = map_list[map_index]
    (0 ... XY_MAX).each do |x|
      (0 ... XY_MAX).each do |y|
	(0 ... 4).each do |d|
	  curr = "x#{x}y#{y}d#{d}"
	  menu_list = [
	    "X+1: #{curr}→x#{x+1}y#{y}d#{d}",
	    "X-1: #{curr}→x#{x-1}y#{y}d#{d}",
	    "Y+1: #{curr}→x#{x}y#{y+1}d#{d}",
	    "Y-1: #{curr}→x#{x}y#{y-1}d#{d}",
	    "D+1: #{curr}→x#{x}y#{y}d#{d+1}",
	    "D-1: #{curr}→x#{x}y#{y}d#{d-1}",
	    "マップ選択に戻る"]

          Drama.selection_menu("#{map}/#{curr}",
                               get_move_state(map_index, x, y, d),
                               menu_list) do |minfo|
	    nx = x; ny = y; nd = d
            case minfo.selection
            when 0
	      nx = (x + 1 + XY_MAX) % XY_MAX
              Drama.cam(map, "x#{nx}y#{ny}d#{nd}")
              state = get_move_state(map_index, nx, ny, nd, minfo.selection)
              Drama.transit_fsm_state(state)

            when 1
	      nx = (x - 1 + XY_MAX) % XY_MAX
              Drama.cam(map, "x#{nx}y#{ny}d#{nd}")
              state = get_move_state(map_index, nx, ny, nd, minfo.selection)
              Drama.transit_fsm_state(state)

            when 2
	      ny = (y + 1 + XY_MAX) % XY_MAX
              Drama.cam(map, "x#{nx}y#{ny}d#{nd}")
              state = get_move_state(map_index, nx, ny, nd, minfo.selection)
              Drama.transit_fsm_state(state)

            when 3
	      ny = (y - 1 + XY_MAX) % XY_MAX
              Drama.cam(map, "x#{nx}y#{ny}d#{nd}")
              state = get_move_state(map_index, nx, ny, nd, minfo.selection)
              Drama.transit_fsm_state(state)

            when 4
	      nd = (d + 1 + 4) % 4
              Drama.cam(map, "x#{nx}y#{ny}d#{nd}")
              state = get_move_state(map_index, nx, ny, nd, minfo.selection)
              Drama.transit_fsm_state(state)

            when 5
	      nd = (d - 1 + 4) % 4
              Drama.cam(map, "x#{nx}y#{ny}d#{nd}")
              state = get_move_state(map_index, nx, ny, nd, minfo.selection)
              Drama.transit_fsm_state(state)

            else 
              Drama.transit_fsm_state(get_navi_state(map_index))
            end
          end
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
