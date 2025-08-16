#!/usr/bin/env ruby

require 'libdrama.rb'

BGM = [
       ['DC', [
               ['���ù�����ɱ��', '1001001'],
               ['���餫�����Ф�', '1001002'],
               ['step step!', '1001003'],
               ['̴�����', '1001004'],
               ['I love your smile', '1001005'],
               ['�Ťʤ��ȼ�', '1001006'],
               ['/usr/local/bin/banana/', '1001007'],
               ['���򳫤���', '1001008'],
               ['�İ��������⤵��', '1001009'],
               ['�Ť��ʲ��', '1001010'],
               ['�᤯�Ʊ󤯤�', '1001011'],
               ['ø���ۤ�������', '1001012'],
               ['���Ĥ�Τ�����', '1001013'],
               ['��������̩���', '1001014'],
               ['�˸Ʋ�����Ǯ���Ľդá�', '1001015'],
               ['strenuous lady', '1001016'],
               ['sakura', '1001017'],
               ['sadness...', '1001018'],
               ['ī����©', '1001019'],
               ['�ۤΤ����붵��', '1001020'],
               ['So Fine', '1001021'],
               ['ͼ�Ƥ��ζ���', '1001022'],
               ['�Ȥ��ʻ���', '1001023'],
               ['������ߤĤ��', '1001024'],
               ['Dream of Cherry tree', '1001025'],
               ['long long ago...', '1001026'],
               ['���ä���Ĥ����ڤʡ�', '1001027'],
               ['sweet bell', '1001028'],
               ['pain', '1001029'],
               ['too alone', '1001030'],
               ['�ä��Ԥ���̿', '1001031'],
               ['������­��', '1001032'],
               ['Happy Carnival', '1001033'],
               ['�Ѥ��ʤ�����', '1001034'],
               ['pillow talk', '1001035'],
               ['�䤿����', '1001036'],
               ['�Ť��˸��Ĥ����', '1001037'],
               ['�ޤ����񤨤롦������͡�', '1001038'],
              ],
       ],

       ['CLANNAD', [
                    ['Į������ή�졢��', '1002001'],
                    ['��', '1002002'],
                    ['��', '1002003'],
                    ['�����β����̤�', '1002004'],
                    ['��������Τ褦��', '1002005'],
                    ['�ϡ��ꤣ�������դ��ä���', '1002006'],
                    ['Etude pour les petites supercordes', '1002007'],
                    ['TOE', '1002010'],
                    ['Etude pour les petites supercordes��', '1002011'],
                    ['������ܵ�', '1002012'],
                    ['�������Τ����', '1002013'],
                    ['����-tempo up-', '1002014'],
                    ['����-afternoon-', '1002015'],
                    ['����', '1002016'],
                    ['����-piano-', '1002017'],
                    ['ͭ�յ��ʻ��֤βᤴ����', '1002018'],
                    ['ͭ�յ��ʻ��֤βᤴ����-guitar-', '1002019'],
                    ['ͭ�յ��ʻ��֤βᤴ����-sax-', '1002020'],
                    ['�ϼ��դ���', '1002021'],
                    ['����', '1002022'],
                    ['�����˵���', '1002023'],
                    ['Ʊ����ߤ�', '1002024'],
                    ['�ļ˾���', '1002025'],
                    ['�������', '1002026'],
                    ['¸��', '1002027'],
                    ['¸��-piano-', '1002028'],
                    ['¸��-e piano-', '1002029'],
                    ['���˸���', '1002030'],
                    ['Ĭ�Ĥ�', '1002031'],
                    ['Ĭ�Ĥ�II', '1002032'],
                    ['�����', '1002033'],
                    ['�ڤ���ǯ��', '1002034'],
                    ['�ڤ���ǯ��-piano-', '1002035'],
                    ['�ƻ���', '1002036'],
                    ['����ȥ꡼�ȥ쥤��', '1002037'],
                    ['���', '1002038'],
                    ['�ꤤ���𤦾��II', '1002039'],
                    ['�ꤤ���𤦾��', '1002040'],
                    ['����', '1002041'],
                    ['����II', '1002042'],
                    ['��ΰ���', '1002043'],
                    ['̵��', '1002044'],
                    ['��', '1002045'],
                   ],
       ],

       ['Shuffle', [
                    ['HAPPY RUN', '1003001'],
                    ['afternoon Tea Party', '1003002'],
                    ['���夬���ī��', '1003003'],
                    ['STEP DANCE', '1003004'],
                    ['Twin Fairy', '1003005'],
                    ['������������̼ã��', '1003006'],
                    ['Morning Bell', '1003007'],
                    ['��ϳ�����γ�', '1003008'],
                    ['Sunlight Summer', '1003009'],
                    ['HEY YOU��', '1003010'],
                    ['�������������', '1003011'],
                    ['���ä����餢�ä������ä����餳�ä�', '1003012'],
                    ['Notice!', '1003013'],
                    ['Don��t be afraid', '1003014'],
                    ['Perple Moon', '1003015'],
                    ['�Ƥդ�', '1003016'],
                    ['���ࡡ����', '1003017'],
                    ['With You��', '1003018'],
                    ['In the Dream', '1003019'],
                    ['HIMAWARI', '1003020'],
                   ],
       ]
      ]

MAP = '����¾\\���Х����ᥤ��'
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

  # ����������
  menu_item = BGM.map {|x| x[0]}
  Drama.selection_menu("����������",
                       get_state(-1, 0), menu_item) do |minfo|
    Drama.transit_fsm_state(get_state(minfo.selection, 0))
  end

  # �����뤴�Ȥ�����
  BGM.each_index do |genre|
    menu_list = BGM[genre][1].map {|x| x[0]} + ['���']
    Drama.selection_menu("#{BGM[genre][0]}�ζ�",
                         get_state(genre), menu_list) do |minfo|
      if minfo.selection < menu_list.length - 1
        Drama.play_bgm(BGM[genre][1][minfo.selection][1], 'short')
      else
        Drama.transit_fsm_state('short')
      end
    end                         
  end

  Drama.catch_all do
    Drama.amsg("FSM�۾�", "���顼")
  end

  Drama.end_fsm_block

  Drama.page_footer
end

if ARGV[0] == "-data"
  generate_data
else
  generate_drama
end

