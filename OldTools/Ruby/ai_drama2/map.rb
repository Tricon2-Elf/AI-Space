#!/usr/bin/env ruby
# ������ɸ���ǧ���롣
# xNyNdN, z120�Ȥ����ץꥻ�å��ͤ�ɬ��(rewrite_adv_presets.rb����)

require 'libdrama.rb'

MAP_TYPE = 'default'

MAP_DEFS = {
  "default" => {
    'desc' => "�ǥե����",
    'list' => [
      "������������\\�����ر�",
      "����ʥ���\\����⹻",
      "����åե���\\�С��٥ʳر�",
    ],
  },
  "town" => {
    'desc' => "��Ź��",
    'list' => [
      "������������\\��Ź��",
      "����ʥ���\\��Ź��",
      "����åե���\\��Ź��",
    ],
  },
  "classroom" => {
    'desc' => "����",
    'list' => [
      "������������\\�����رඵ��",
      "����ʥ���\\����⹻����",
      "����åե���\\�С��٥ʳرඵ��",
    ],
  },
  "akiba" => {
    'desc' => "������",
    'list' => [
      "�����ϥХ���\\�����ϥХ�",
      "�����ϥХ���\\UDX",
    ],
  },
  "myroom" => {
    'desc' => "�ޥ��롼��",
    'list' => [
      "�ޥ��롼��\\�ޥ��롼��(6��)",
      "�ޥ��롼��\\�ޥ��롼��(8��)",
      "�ޥ��롼��\\�ޥ��롼��(10��)",
      "�ޥ��롼��\\�ޥ��롼��(12.5��)",
    ],
  },
  "hometown" => {
    'desc' => "����",
    'list' => [
      "������������\\����",
      "����ʥ���\\����",
      "����åե���\\����",
    ],
  },
  "misc1" => {
    'desc' => "����¾1",
    'list' => [
      "����¾\\���ơ���",
      "����¾\\������",
      "����¾\\���Х����ᥤ��",
    ],
  },
  "misc2" => {
    'desc' => "����¾1",
    'list' => [
      "����¾\\�ż���",
      "����¾\\�����ĥӥ���",
      "����¾\\��ȿ�Գ�Υ����",
      "����¾\\�ƥ���",
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
    # �ޥåץǡ����Ϥ�����ˤ����ɤ�ľ���Τǡ������ǤϷڤ��ޥåפ�����
    Drama.map('����¾\\���Х����ᥤ��', 'day')
    Drama.cam('����¾\\���Х����ᥤ��', 'z120')
    Drama.transit_fsm_state(get_navi_state())
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # �ʥ�
  nrStates = 0
  Drama.selection_menu("�ޥå�����",
                       get_navi_state(),
                       map_list.map{|x| x.sub(/\\/,'/')}) do |minfo|
    Drama.map(map_list[minfo.selection], 'day')
    Drama.cam(map_list[minfo.selection], "x4y4d0")
    Drama.transit_fsm_state(get_move_state(minfo.selection, 4, 4, 0))
  end

  # ��ư
  map_list.each_index do |map_index|
    map = map_list[map_index]
    (0 ... XY_MAX).each do |x|
      (0 ... XY_MAX).each do |y|
	(0 ... 4).each do |d|
	  curr = "x#{x}y#{y}d#{d}"
	  menu_list = [
	    "X+1: #{curr}��x#{x+1}y#{y}d#{d}",
	    "X-1: #{curr}��x#{x-1}y#{y}d#{d}",
	    "Y+1: #{curr}��x#{x}y#{y+1}d#{d}",
	    "Y-1: #{curr}��x#{x}y#{y-1}d#{d}",
	    "D+1: #{curr}��x#{x}y#{y}d#{d+1}",
	    "D-1: #{curr}��x#{x}y#{y}d#{d-1}",
	    "�ޥå���������"]

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
