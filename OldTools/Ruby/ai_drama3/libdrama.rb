class MenuItemInfo
  attr_accessor :text, :base_state, :items
  attr_accessor :event_type, :selection, :selected_value
end

class Drama
  @@level = 0
  @@indent = ''
  @@selection_se = false

  ENTRY = 1
  ACTION = 2
  EXIT = 3
  RETURN = 4
  attr_reader :ENTRY, :ACTION, :EXIT

  # ----------------------------------------------------------------------
  # ����ǥ�ȴ���

  def Drama.enter
    @@level = @@level + 1
    @@indent = "    " * @@level
  end

  def Drama.leave
    @@level = @@level - 1
    @@indent = "    " * @@level
  end

  def Drama.indent
    enter
    yield
    leave
  end

  # ----------------------------------------------------------------------
  # �ڡ�������

  def Drama.page_header(sheetname)
    print "#{@@indent}#sheetcolor,0xffffffff\n"
    print "#{@@indent}PAGEHEADER,name\\#{sheetname},\n"
    enter
  end

  def Drama.page_footer
    leave
    print "#{@@indent}PAGEFOOTER\n"
  end

  # ----------------------------------------------------------------------

  # char(CHARID, {center,left,right}, {front,left,right,dir\\ANGLE})
  def Drama.char(charid, pos, dir)
    print "#{@@indent}EVTCHR_SET,id\\#{charid},pos\\#{pos},dir\\#{dir},\n"
  end

  # exit(CHARID)
  def Drama.exit(charid)
    print "#{@@indent}EVTCHR_EXIT,id\\#{charid},\n"
  end

  # move(CHARID, {center,left,right}, {run,walk})
  def Drama.move(charid, pos, type)
    print "#{@@indent}EVTCHR_MOVE,id\\#{charid},pos\\#{pos},movetype\\#{type},\n"
  end

  # cwait(CHARID, {all,move})
  def Drama.cwait(charid, type)
    print "#{@@indent}EVTCHR_WAIT,id\\#{charid},#{type},\n"
  end

  # emotion(CHARID, EMOTION_ID)
  def Drama.emotion(charid, emoid)
    print "#{@@indent}EMOTION_SET,id\\#{charid},emo\\#{emoid},\n"
  end

  def Drama.wait_emotion(charid)
    print "#{@@indent}EMOTION_WAIT,id\\#{charid},\n"
  end

  # ----------------------------------------------------------------------

  AREA_TO_NAME = {
    # ������area�ˤ�"������������\\�����ر२�ꥢ"�ʤɤΤ褦��
    # "���ꥢ"���դ��Ƥ����������äƤ�ʤ��Ƥ�褤�褦�����椫���ѹ����줿
    "dacapo"  => "������������\\�����ر�",
    "clannad" => "����ʥ���\\����⹻",
    "shuffle" => "����åե���\\�С��٥ʳر�",
  }

  # map(area, {morn,day,eve,night,earlymorning})
  def Drama.map(area, timezone)
    if AREA_TO_NAME.has_key?(area)
      area = AREA_TO_NAME[area]
    end
    print "#{@@indent}CHANGEMAP,map\\#{area},timezone\\#{timezone},\n"
  end

  # ----------------------------------------------------------------------

  # play_bgm(BGM_ID, {short,TODO})
  def Drama.play_bgm(bgmid, time)
    print "#{@@indent}BGM_PLAY,id\\#{bgmid},time\\#{time},\n"
  end

  # stop_bgm({none, TODO})
  def Drama.stop_bgm(time)
    print "#{@@indent}BGM_STOP,time\\#{time},\n"
  end

  def Drama.play_se(seid, volume)
    print "#{@@indent}SE_PLAY,id\\#{seid},volume\\#{volume},\n"
  end

  def Drama.play_loopse(seid, volume)
    print "#{@@indent}LOOPSE_PLAY,id\\#{seid},volume\\#{volume},\n"
  end

  def Drama.stop_loopse(seid)
    print "#{@@indent}SE_PLAY,id\\#{seid},\n"
  end

  # play_voice(VOICE_ID, CHARID)
  # wait_voice(CHARID)
  # �ʤ��������ν��֤��㤦�� �ץ�ե�������id\nnn�ǤϤʤ�����

  def Drama.play_voice(voiceid, charid)
    print "#{@@indent}VOICE_PLAY,id\\#{voiceid},chara\\#{charid},\n"
  end

  def Drama.wait_voice(charid)
    print "#{@@indent}VOICE_WAIT,chara\\#{charid},\n"
  end

  # fade_in(COLOR, TIME, WAIT)
  #  COLOR = black,white, color/RRGGBB
  #  TIME = none, short, normal, long, time\n_SEC
  #  WAIT = wait�ޤ��϶���
  def Drama.fade_in(color, time, wait)
    print "#{@@indent}FADE_IN,color\\#{color},time\\#{time},#{wait},\n"
  end

  def Drama.fade_out(color, time, wait)
    print "#{@@indent}FADE_OUT,color\\#{color},time\\#{time},#{wait},\n"
  end

  # flash({front, rear}, {,wait})
  def Drama.flash(type, wait)
    print "#{@@indent}FLASH,type\\#{type},#{wait},\n"
  end

  # filter(MASK)
  #  MASK = "AARRGGBB"
  def Drama.filter(mask)
    print "#{@@indent}FILTER,color\\#{mask},\n"
  end

  # ----------------------------------------------------------------------

  def Drama.cam(area, loc)
    if AREA_TO_NAME.has_key?(area)
      area = AREA_TO_NAME[area]
    end
    print "#{@@indent}CAM_SET,preset\\#{area}\\#{loc},\n"
  end

  # ----------------------------------------------------------------------

  # ��Ȥ��ƻȤ���ɽ�����ѷ����롣
  #
  # "var.n" -> variable\VAR_NAME
  # "flag.n" -> flag\FLAGNAME
  # "random(N,N): -> value_random\NUMBER\~\NUMBER
  # "on" �ޤ��� "off" -> on_off\{on,off}
  # Fixnum �ޤ��� /[0-9]+/ -> value_number\NUMBER
  # ����¾("selection"�ʤ�) -> ���Τޤ�
  def Drama.normalize_expr(arg)
    if arg.class == Fixnum || arg =~ /^\d+$/
      return "value_number\\#{arg}"
    elsif arg =~ /^random\((\d+),(\d+)\)$/
      # TODO: �����ǧ��Ƥ��ʤ�
      return "value_random\\#{$1}\\~\\#{$2}"
    elsif arg =~ /^(var|variable)\.(.*)/
      return "variable\\value.#{$2}"
    elsif arg =~ /^flag\.(.*)/
      return "variable\\flag.#{$1}"
    elseif arg == "on" || arg == "off"
      return "on_off\\#{arg}"
    else
      return arg
    end
  end

  # set_flag(FLAG_ID, {on,off})
  def Drama.set_flag(flag, value)
    print "#{@@indent}FLAG_SET,flag\\flag.#{flag},on_off\\#{value},\n"
  end

  # set_var(VAR_ID, ...)
  # ��: ���٤Ƥι���Ȥ߹�碌���Ȥ���櫓�ǤϤʤ���
  # �㤨��"�ѿ������+�ѿ�"�η����α黻�ϤǤ��ʤ���
  def Drama.set_var(var, *arg)
    # ���: VARIABLE_SET��ñ��黻��VARIABLE_CALC�����黻
    if arg.length == 1
      lhs = normalize_expr(arg[0])
      print "#{@@indent}VARIABLE_SET,variable\\value.#{var},set\\#{lhs},\n"
    elsif arg.length == 3
      lhs = normalize_expr(arg[0])
      rhs = normalize_expr(arg[2])
      print "#{@@indent}VARIABLE_CALC,variable\\value.#{var},left\\#{lhs},op\\#{arg[1]},right\\#{rhs},\n"
    else
      die "Error: wrong arguments"
    end
  end

  # test(LHS, OP, RHS), elsetest, endtest
  # LHS: variable, flag, selection�Τ����줫
  # RHS: variable, flag, number, on_off�Τ����줫
  def Drama.test(lhs, op, rhs)
    lhs = normalize_expr(lhs); rhs = normalize_expr(rhs)
    print "#{@@indent}IF,#{lhs},#{op},#{rhs},\n"
    if defined? yield
      enter; yield; leave
    end
  end

  def Drama.elsetest(lhs, op, rhs)
    lhs = normalize_expr(lhs); rhs = normalize_expr(rhs)
    print "#{@@indent}ELSEIF,#{lhs},#{op},#{rhs},\n"
    if defined? yield
      enter; yield; leave
    end
  end

  def Drama.catch_all
    Drama.elsetest("var.0", "==", "var.0")
    if defined? yield
      enter; yield; leave
    end
  end

  def Drama.endtest
    print "#{@@indent}ENDIF,\n"
  end

  def Drama.menu(item)
    print "#{@@indent}SELECTION_ADD,msg\\#{item},\n"
  end

  def Drama.select_menu
    print "#{@@indent}SELECTION_START,\n"
  end

  def Drama.mwait(msec)
    print "#{@@indent}WAIT,#{msec}\\msec,\n"
  end

  def Drama.goto(sheetname)
    print "#{@@indent}PAGEJUMP,name\\#{sheetname},\n"
  end

  # ----------------------------------------------------------------------

  def Drama.close_msg
    print "#{@@indent}ADVMSG_CLOSE,\n"
  end

  # �����ꤷ��CHARID�����̤��о줷�Ƥ���ɬ�פ���
  # %[value.n]��%[flag.n]��%[master.name]���ִ������
  def Drama.msg(text, charid)
    print "#{@@indent}ADVMSG_SET,msg\\#{text},name\\id\\#{charid},\n"
  end

  def Drama.amsg(*args)
    text = args[0]
    name = (args.length > 1) ? args[1] : ""
    print "#{@@indent}ADVMSG_SET,msg\\#{text},name\\name\\#{name},\n"
  end

  def Drama.comment(text)
    print "#{@@indent}##{text},\n"
  end

  #----------------------------------------------------------------------
  # ���֥ޥ���
  #
  # �Ȥ���
  # begin_fsm_block
  # if_fsm_state(xxx)
  #   ���֤�xxx�λ��ν���
  #   set_fsm_state(yyy)
  # if_fsm_state(yyy)
  #   ���֤�yyy�λ��ν���
  #   set_fsm_state(xxx)
  # end_fsm_block
  # restart_fsm

  FSM_STATE_VAR = 'fsm_state'
  FSM_STACK_VAR = 'fsm_stack'
  @@fsm_stack_depth = 0

  def Drama.begin_fsm_block
    test("var.0", "!=", "var.0")
    (0...@@fsm_stack_depth).each do |i|
      set_var("#{FSM_STACK_VAR}#{i}", -1) # �����å�������
    end
  end

  def Drama.if_fsm_state(state)
    elsetest("var.#{FSM_STATE_VAR}", "==", state)
  end

  def Drama.end_fsm_block
    endtest
  end

  def Drama.restart_fsm
    goto("MainPage")
  end

  def Drama.transit_fsm_state(state)
    set_var(FSM_STATE_VAR, state)
  end

  def Drama.call(new_state, return_state)
    # 9<-8, 8<-7 ... 1<-0, 0<-return_state
    (@@fsm_stack_depth - 2).downto(0) do |i|
      set_var("#{FSM_STACK_VAR}#{i+1}", "var.#{FSM_STACK_VAR}#{i}")
    end
    set_var("#{FSM_STACK_VAR}#{0}", return_state)
    transit_fsm_state(new_state)
  end

  def Drama.return
    # new_state<-0, 0<-1, 1<-2, ... 8<-9
    transit_fsm_state("#{FSM_STACK_VAR}#{0}")
    0.upto(@@fsm_stack_depth - 2) do |i|
      set_var("#{FSM_STACK_VAR}#{i}", "var.#{FSM_STACK_VAR}#{i+1}")
    end
  end

  #----------------------------------------------------------------------
  # �ּ��ס����ס�ȴ����פ�3���ɽ������
  # ʣ���ι��ܤ򼡡��˻���륹�ԥʥ����פΥ�˥塼����
  # 
  #	item_list = [Dot, Line, Triangle]
  #	Drama.spinner_menu(base_state, item_list) do |minfo|
  #       case minfo.event_type
  #       when Drama::ENTRY
  #         case minfo.selection
  #	    when 0
  #	      �ɥå�����
  #	    when [1, ENTRY]
  #	      �饤�����
  #	    when [2, ENTRY]
  #	      ���ѷ�����
  #         end
  #       when Drama::EXIT
  #	    �ɥåȾõ� if minfo.selection == 0
  #	  when Drama::RETURN
  #	    Drama.transit_fsm_state(exit_state)
  #	end
  # �ϡ�
  #	if_fsm_state(base_state + 0)
  #	  �ɥå�����
  #	  ��˥塼��ɽ���������򤵤���
  #	  �ɥåȾõ�
  #	  ��˥塼1�����򤷤���base_state+2������
  #	  ��˥塼2�����򤷤���base_state+1������
  #	  ��˥塼3�����򤷤���exit_state������
  #	if_fsm_state(base_state + 1)
  #	  �饤�����
  #	  ��˥塼��ɽ���������򤵤���
  #	  ��˥塼1�����򤷤���base_state+2������
  #	  ��˥塼2�����򤷤���base_state+1������
  #	  ��˥塼3�����򤷤���exit_state������
  #	if_fsm_state(base_state + 2)
  #	  ���ѽ���
  #	  ��˥塼��ɽ���������򤵤���
  #	  ��˥塼1�����򤷤���base_state+2������
  #	  ��˥塼2�����򤷤���base_state+1������
  #	  ��˥塼3�����򤷤���exit_state������
  # ��Ʊ����
  def Drama.spinner_menu(text, base_state, items)
    minfo = MenuItemInfo.new
    minfo.text = text
    minfo.base_state = base_state
    minfo.items = items

    (0 ... items.length).each do |i|
      minfo.selection = i
      minfo.selected_value = items[i]

      comment("spinner:#{text} menu:#{i}")
      if_fsm_state(base_state + i)
      indent do
        next_item = (i + 1) % items.length
        prev_item = (i - 1 + items.length) % items.length

        # ENTRY���������
        minfo.event_type = ENTRY
        yield minfo

        # ��˥塼����
        menu("����: #{items[next_item]}")
        menu("����: #{items[prev_item]}")
        menu("����� (����: #{items[i]})")
        select_menu

        # EXIT���������
        minfo.event_type = EXIT
        yield minfo

        # ��������
        test("selection", "==", 0)
        indent do
          play_se("����å�", 100) if @@selection_se
          transit_fsm_state(base_state + next_item)
        end
        elsetest("selection", "==", 1)
        indent do
          play_se("����å�", 100) if @@selection_se
          transit_fsm_state(base_state + prev_item)
        end
        elsetest("selection", "==", 2)
        indent do
          play_se("����󥻥룲", 100) if @@selection_se
          minfo.event_type = RETURN
          yield minfo
        end
        endtest
        restart_fsm
      end
    end
  end

  #----------------------------------------------------------------------
  # �ּ��ס����סּ¹ԡפ�3���ɽ������
  # ʣ���ι��ܤ���1��������򤵤��륳�ޥ�ɥ����פΥ�˥塼����
  # 
  #	cmd_list = [��������, ������, �ɤ���]
  #	Drama.selection_menu("", base_state, cmd_list) do |minfo|
  #	  case minfo.selection
  #	  when 0
  #	    ��Ʈ����
  #	  when 1
  #	    ��ˡ����
  #	  when 2
  #	    ƻ�����
  #	  end
  #	end
  # �ϡ�
  #	Drama.if_fsm_state(base_state + 0)
  #	  ��˥塼��ɽ���������򤵤���
  #	  ��˥塼1�����򤷤���base_state+2������
  #	  ��˥塼2�����򤷤���base_state+1������
  #	  ��˥塼3�����򤷤�����Ʈ����
  #	  Drama.restart_fsm
  #	Drama.if_fsm_state(base_state + 1)
  #	  ��˥塼��ɽ���������򤵤���
  #	  ��˥塼1�����򤷤���base_state+0������
  #	  ��˥塼2�����򤷤���base_state+2������
  #	  ��˥塼3�����򤷤�����ˡ����
  #	  Drama.restart_fsm
  #	Drama.if_fsm_state(base_state + 2)
  #	  ��˥塼��ɽ���������򤵤���
  #	  ��˥塼1�����򤷤���base_state+0������
  #	  ��˥塼2�����򤷤���base_state+1������
  #	  ��˥塼3�����򤷤���ƻ�����
  #	  Drama.restart_fsm
  # ��Ʊ��

  def Drama.selection_menu(text, base_state, items)
    minfo = MenuItemInfo.new
    minfo.text = text
    minfo.base_state = base_state
    minfo.items = items

    (0 ... items.length).each do |i|
      minfo.event_type = ACTION
      minfo.selection = i
      minfo.selected_value = items[i]

      comment("selection_menu:#{text} menu:#{i}")
      if_fsm_state(base_state + i)
      indent do
        next_item = (i + 1) % items.length
        prev_item = (i - 1 + items.length) % items.length
        menu("�����������")
        menu("�����������")
        menu("#{items[i]} (#{i+1}/#{items.length})")
        select_menu

        test("selection", "==", 0)
        indent do
          play_se("����å�", 100) if @@selection_se
          transit_fsm_state(base_state + next_item)
        end
        elsetest("selection", "==", 1)
        indent do
          play_se("����å�", 100) if @@selection_se
          transit_fsm_state(base_state + prev_item)
        end
        elsetest("selection", "==", 2)
        indent do
          play_se((i == 0 ? "����󥻥룲" : "���겻��"), 100) if @@selection_se
          yield minfo
        end
        endtest
        restart_fsm
      end
    end
  end
end
