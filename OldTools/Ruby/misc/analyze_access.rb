#!/usr/bin/env ruby
# access.logを解析し、未知のキャラクタ・アイテムを表示する

charid = '2022011'	# ドラマ用?

def analyze_access_log(fd)
  char = Hash.new
  item = Hash.new
  
  while buf = fd.gets()
    buf.chomp!
    if buf =~ /^\[ \.\\chara\\(\d)\\(\d{5})\\/
      char[$1 + $2] = true
    end
    if buf =~ /^\[ \.\\item\\(\d)\\(\d{2})\\(\d{5})\\/
      item[$1 + $2 + $3] = true
    end
  end

  return [char.keys.sort, item.keys.sort]
end

def load_data(fd)
  data = Hash.new
  while buf = fd.gets
    buf.chomp!
    tmp = buf.split(',', 2)
    if tmp.length == 2 && tmp[1] != '?'
      data[tmp[0]] = tmp[1]
    end
  end
  return data
end

def adjust_char_data(data)
  newdata = Hash.new
  data.each_key do |key|
    newdata[key[0, key.length-1]] = data[1]
  end
  return newdata
end

def compare(found, listed)
  result = [[], []]

  found.each do |item|
    if listed.has_key?(item)
      result[1] << item	# すでにある
    else
      result[0] << item	# 新規
    end
  end
  return result
end

#----------------------------------------------------------------------

fd = open('access.log')
found = analyze_access_log(fd)
fd.close

fd = open('../@characters.csv')
chars = adjust_char_data(load_data(fd))
fd.close

fd = open('../@items.csv')
items = load_data(fd)
fd.close

result = compare(found[0], chars)
print "* New Characters\n"
print result[0].join(', ') + "\n\n"
print "* Listed Characters\n"
print result[1].join(', ') + "\n\n"

result = compare(found[1], items)
print "* New Items\n"
print result[0].join(', ') + "\n\n"
print "* Listed Items\n"
print result[1].join(', ') + "\n\n"

print "* Entries for item list\n"
result[0].each do |item|
  print "#{item},\n"
end
print "\n\n"

print "* Entries for datalist_0.txt\n"
(0 ... result[0].length).each do |i|
  print "#{i},#{result[0][i]},doll,#{charid},0,0,#{result[0][i]},\n"
end
