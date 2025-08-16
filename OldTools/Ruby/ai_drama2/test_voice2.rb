#!/usr/bin/env ruby
# �ܥ����Υƥ��ȡ�
# ���: ��Ȥ��¸�ߤ��ʤ��ޥåס��������֥ץꥻ�åȤ�Ȥ�����
# adv_presetdata.csv�ν񤭴�����ɬ��

require 'libdrama.rb'
require 'libcommon.rb'

# ����饯���������Ϥ���
def generate_data
  print "[ACTOR]\n"
  print "0,,doll,2022021,0,0,10100010,10200000,10400000,10500040,10600010,10700010,\n"
  # �դ�Ȥ���硢�������0�֤Υ���饯���ˤ��롣���������⡼�����Ϥ��ʤ�
  print "1,,doll,3992010,0,0,10100130,10200280,10500000,10400000,\n"
end

# �ܥ���ID���ϰ�
VOICE_RANGES = [
  [10001, 10150],
  [20001, 20150],
  [30001, 30200],
]

# ���ݷϥܥ�����ID�ꥹ��
BATOU_VOICES = [30118,30119,30120,30121,30125,30126,30127,30129,30134,30135,30136,30137,30143,30145,30149,30150]

# ���ݲ���������
BATOU_COUNTS = [20, 50, 100, 1000, 1000000]


def generate_drama
  charId = 0
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: test_voice2.rb,v $, $Revision: 1.11 $')
  Drama.indent do
    Drama.map(CONFIG_MAP, 'day')
    Drama.cam(CONFIG_MAP, CONFIG_CAM)
    Drama.char(charId, 'center', 'front')
    Drama.transit_fsm_state(0)
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # ���
  menu_list = %w[���롼��0 ���롼��1 ���롼��2 �ץꥻ�å� ���ڥ����]
  Drama.selection_menu("���", 0, menu_list) do |minfo|
    case minfo.selection
    when 0..2
      Drama.transit_fsm_state(10000 + 1000 * minfo.selection)
    when 3
      Drama.transit_fsm_state(20000)
    when 4
      Drama.transit_fsm_state(30000)
    end
  end

  # ���롼�פ���
  VOICE_RANGES.each_index do |g|
    menu_list = (VOICE_RANGES[g][0]..VOICE_RANGES[g][1]).map {|x| "�ܥ���#{x}"}
    Drama.spinner_menu("���롼��#{g}",
                       10000 + 1000 * g, menu_list) do |minfo|
      case minfo.event_type
      when Drama::ENTRY
        Drama.play_voice(VOICE_RANGES[g][0] + minfo.selection, charId)
	#�����ǥܥ����������ԤäƤ��ɤ��������������ʤ�ʤ��ʤäƤ��ޤ�
	#Drama.wait_voice(charId)
      when Drama::RETURN
        Drama.transit_fsm_state(g)
      end
    end
  end

  # �ץꥻ�å�
  menu_list = %w[����a�ǥ� ����b�ǥ� ����c�ǥ� ����a�ĥ� ����b�ĥ� ����c�ĥ� ���]
  Drama.selection_menu("�ץꥻ�å�", 20000, menu_list) do |minfo|
    case minfo.selection
    when 0
      Drama.emotion(charId, 'sheepish')
      play_wait_voice(10111, charId)
      play_wait_voice(10112, charId)
      Drama.mwait(500)
      play_wait_voice(10113, charId)
    when 1
      Drama.emotion(charId, 'sheepish')
      play_wait_voice(20111, charId)
      play_wait_voice(20112, charId)
      Drama.mwait(500)
      play_wait_voice(20113, charId)
    when 2
      Drama.emotion(charId, 'sheepish')
      play_wait_voice(30111, charId)
      play_wait_voice(30112, charId)
      Drama.mwait(500)
      play_wait_voice(30113, charId)
    when 3
      Drama.emotion(charId, 'signifier')
      play_wait_voice(10111, charId)
      play_wait_voice(10117, charId)
      Drama.mwait(500)
      play_wait_voice(10116, charId)
    when 4
      Drama.emotion(charId, 'signifier')
      play_wait_voice(20111, charId)
      play_wait_voice(20117, charId)
      Drama.mwait(500)
      play_wait_voice(20116, charId)
    when 5
      Drama.emotion(charId, 'signifier')
      play_wait_voice(30111, charId)
      play_wait_voice(30117, charId)
      Drama.mwait(500)
      play_wait_voice(30116, charId)
    when 6
      Drama.transit_fsm_state(3)
    end
  end

  # ���ڥ����
  menu_item = BATOU_COUNTS.map {|x| "#{x}��"} + ['���']
  Drama.selection_menu("���ڥ����",
		       30000,
                       menu_item) do |minfo|
    if minfo.selection == BATOU_COUNTS.length
      Drama.transit_fsm_state(4)
    else
      Drama.set_var(14, BATOU_COUNTS[minfo.selection])
      Drama.transit_fsm_state(40000)
    end
  end

  Drama.if_fsm_state(40000)
  Drama.indent do
    Drama.set_var(14, "var.14", '-', 1)
    Drama.test("var.14", '==', 0) do
      Drama.transit_fsm_state(30000)
    end
    Drama.endtest

    # 5���1�󡢻ؤ�ؤ�
    Drama.set_var(0, "var.14")
    Drama.set_var(0, "var.0", '/', 5)
    Drama.set_var(0, "var.0", '*', 5)
    Drama.set_var(0, "var.14", '-', "var.0")
    Drama.test("var.0", '==', 0) do
      Drama.emotion(charId, 'signifier')
    end
    Drama.endtest

    # ����η�̤˱������ܥ������������
    Drama.set_var(0, "random(0,#{BATOU_VOICES.length - 1})")
    Drama.test("var.0", '!=', "var.0")
    (0 ... BATOU_VOICES.length).each do |i|
      Drama.elsetest("var.0", '==', i) do
        play_wait_voice(BATOU_VOICES[i], charId)
      end
    end
    Drama.endtest
    Drama.restart_fsm
  end

  Drama.catch_all do
    Drama.amsg("FSM�۾�", "���顼")
  end

  Drama.end_fsm_block
  Drama.page_footer
end

def play_wait_voice(voiceId, charId)
  Drama.play_voice(voiceId, charId)
  Drama.wait_voice(charId)
end

if ARGV[0] == "-data"
  generate_data
else
  generate_drama
end
