#!/usr/bin/env ruby

require 'libdrama.rb'

BGM = [
       ['DC', [
               ['世話好きお姫様', '1001001'],
               ['柔らかな微笑み', '1001002'],
               ['step step!', '1001003'],
               ['夢の中で', '1001004'],
               ['I love your smile', '1001005'],
               ['重なる手と手', '1001006'],
               ['/usr/local/bin/banana/', '1001007'],
               ['心を開く時', '1001008'],
               ['可愛い小悪魔さん', '1001009'],
               ['静かな過去', '1001010'],
               ['近くて遠くて', '1001011'],
               ['淡き想い〜恋心', '1001012'],
               ['いつものあいつ', '1001013'],
               ['乙女の秘密会議', '1001014'],
               ['嗚呼我等の熱き青春っ！', '1001015'],
               ['strenuous lady', '1001016'],
               ['sakura', '1001017'],
               ['sadness...', '1001018'],
               ['朝の吐息', '1001019'],
               ['陽のあたる教室', '1001020'],
               ['So Fine', '1001021'],
               ['夕焼けの教室', '1001022'],
               ['暖かな時間', '1001023'],
               ['星空をみつめて', '1001024'],
               ['Dream of Cherry tree', '1001025'],
               ['long long ago...', '1001026'],
               ['たった一つの大切な…', '1001027'],
               ['sweet bell', '1001028'],
               ['pain', '1001029'],
               ['too alone', '1001030'],
               ['消え行く運命', '1001031'],
               ['怪しい足音', '1001032'],
               ['Happy Carnival', '1001033'],
               ['変わらない日々', '1001034'],
               ['pillow talk', '1001035'],
               ['冷たい涙', '1001036'],
               ['静かに見つめられて', '1001037'],
               ['また、会える・・・よね？', '1001038'],
              ],
       ],

       ['CLANNAD', [
                    ['町、時の流れ、人', '1002001'],
                    ['渚', '1002002'],
                    ['渚？', '1002003'],
                    ['渚〜坂の下の別れ', '1002004'],
                    ['それは風のように', '1002005'],
                    ['は〜りぃすたーふぃっしゅ', '1002006'],
                    ['Etude pour les petites supercordes', '1002007'],
                    ['TOE', '1002010'],
                    ['Etude pour les petites supercordes？', '1002011'],
                    ['彼女の本気', '1002012'],
                    ['資料室のお茶会', '1002013'],
                    ['東風-tempo up-', '1002014'],
                    ['東風-afternoon-', '1002015'],
                    ['東風', '1002016'],
                    ['東風-piano-', '1002017'],
                    ['有意義な時間の過ごし方', '1002018'],
                    ['有意義な時間の過ごし方-guitar-', '1002019'],
                    ['有意義な時間の過ごし方-sax-', '1002020'],
                    ['馬鹿ふたり', '1002021'],
                    ['ダム', '1002022'],
                    ['灰燼に帰す', '1002023'],
                    ['同じ高みへ', '1002024'],
                    ['田舎小怪', '1002025'],
                    ['日々の遑', '1002026'],
                    ['存在', '1002027'],
                    ['存在-piano-', '1002028'],
                    ['存在-e piano-', '1002029'],
                    ['空に光る', '1002030'],
                    ['潮鳴り', '1002031'],
                    ['潮鳴りII', '1002032'],
                    ['白詰草', '1002033'],
                    ['遥かな年月', '1002034'],
                    ['遥かな年月-piano-', '1002035'],
                    ['夏時間', '1002036'],
                    ['カントリートレイン', '1002037'],
                    ['雪野原', '1002038'],
                    ['願いが叶う場所II', '1002039'],
                    ['願いが叶う場所', '1002040'],
                    ['幻想', '1002041'],
                    ['幻想II', '1002042'],
                    ['月の位相', '1002043'],
                    ['無間', '1002044'],
                    ['汐', '1002045'],
                   ],
       ],

       ['Shuffle', [
                    ['HAPPY RUN', '1003001'],
                    ['afternoon Tea Party', '1003002'],
                    ['雨上がりの朝に', '1003003'],
                    ['STEP DANCE', '1003004'],
                    ['Twin Fairy', '1003005'],
                    ['ああ、愛しき娘達よ', '1003006'],
                    ['Morning Bell', '1003007'],
                    ['木漏れ日の街', '1003008'],
                    ['Sunlight Summer', '1003009'],
                    ['HEY YOU！', '1003010'],
                    ['茜色に抱かれて', '1003011'],
                    ['こっちからあっち　あっちからこっち', '1003012'],
                    ['Notice!', '1003013'],
                    ['Don’t be afraid', '1003014'],
                    ['Perple Moon', '1003015'],
                    ['影ふみ', '1003016'],
                    ['滲む　鏡像', '1003017'],
                    ['With You…', '1003018'],
                    ['In the Dream', '1003019'],
                    ['HIMAWARI', '1003020'],
                   ],
       ]
      ]

MAP = 'その他\\アバターメイク'
CAM = 'z120'

def generate_data
  print "[ACTOR]\n"
end

def get_state(genre, menuitem = 0)
  return 1001001 + genre * 1000 + menuitem
end

def generate_drama
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: test_bgm2.rb,v $, $Revision: 1.3 $')
  Drama.indent do
    Drama.map(MAP, 'day')
    Drama.cam(MAP, CAM)
    Drama.transit_fsm_state(get_state(-1, 0))
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # ジャンル選択
  menu_item = BGM.map {|x| x[0]}
  Drama.selection_menu("ジャンル選択",
                       get_state(-1, 0), menu_item) do |minfo|
    Drama.transit_fsm_state(get_state(minfo.selection, 0))
  end

  # ジャンルごとに選択
  BGM.each_index do |genre|
    menu_list = BGM[genre][1].map {|x| x[0]} + ['戻る']
    Drama.selection_menu("#{BGM[genre][0]}の曲",
                         get_state(genre), menu_list) do |minfo|
      if minfo.selection < menu_list.length - 1
        Drama.play_bgm(BGM[genre][1][minfo.selection][1], 'short')
      else
        Drama.transit_fsm_state('short')
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

