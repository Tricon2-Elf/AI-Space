#!/usr/bin/env ruby

require 'libdrama.rb'

LOCATIONS = [
  [
    "風見学園", "ダ・カーポ島\\風見学園",
    %w[桜並木 街並み１ 街並み２ 校門１ 校門２ 校舎前 校庭 校庭２ 焼却炉 バスケコート 体育館前 裏門 通学路１ 通学路２ 通学路３ 住宅街 中庭 バス停]],
  [
    "光坂高校", "クラナド島\\光坂高校",
    %w[高校前の坂 校門１ 校門２ 玄関前 校庭 バスケコート１ バスケコート２ テニスコート 中庭 体育館前 体育館裏物置 駐輪場 校舎前(中庭) 水飲み場 校庭(野球場) 校舎裏ポンプ 中庭(掲示板) 校舎前(掲示板) 裏門 高校裏住宅街 公園 坂 道 林 住宅街]],
  [
    "バーベナ学園", "シャッフル島\\バーベナ学園",
    %w[校門 校庭 噴水前 プール テニスコート 体育館裏物置 体育館裏水飲み場 駐輪場 バス停 体育館前 校舎中庭 校舎裏 校舎玄関前 ゴミ捨て場１ ゴミ捨て場２ 通学路１ 通学路２ 住宅街１ 住宅街２ 神王家テスト]],
  [
    "DC住宅街", "ダ・カーポ島\\住宅街",
    %w[朝倉家１ 朝倉家２ 芳乃家１ 芳乃家２]],
  [
    "CL住宅街", "クラナド島\\住宅街",
    %w[古河パン１ 古河パン２ 岡崎家１ 岡崎家２]],
  [
    "SH住宅街", "シャッフル島\\住宅街",
    %w[神王家１ 神王家２ 魔王家１ 魔王家２ 芙蓉家１]],
]


def generate_data
  # 人物は登場しない
  print "[ACTOR]\n"
end

def get_map_state(map)
  return 100000 + map * 100
end

def generate_drama
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: locations2.rb,v $, $Revision: 1.9 $')
  Drama.map(LOCATIONS[0][1], 'day')
  Drama.cam(LOCATIONS[0][1], LOCATIONS[0][2][0])
  Drama.goto('MainPage')
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # 総合メニュー
  menu_list = LOCATIONS.map {|x| x[0] }
  Drama.selection_menu("総合メニュー", 0, menu_list) do |minfo|
    Drama.map(LOCATIONS[minfo.selection][1], 'day')
    Drama.transit_fsm_state(get_map_state(minfo.selection))
  end

  # マップごとのメニュー
  LOCATIONS.each_index do |loc|
    Drama.spinner_menu(LOCATIONS[loc][0],
                       get_map_state(loc),
                       LOCATIONS[loc][2]) do |minfo|
      case minfo.event_type
      when Drama::ENTRY
        Drama.cam(LOCATIONS[loc][1], LOCATIONS[loc][2][minfo.selection])
      when Drama::RETURN
        Drama.transit_fsm_state(loc)
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
