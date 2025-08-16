#!/usr/bin/env ruby
# 指定されたddsファイルが読み込み可能であるか確認する。

def check(path)
  ifp = open(path, "rb")
  bin = ifp.read(128)
  ifp.close
  return if bin == nil

  cdata = bin.unpack("C*")
  idata = bin.unpack("I*");

  if cdata[0] != ?D || cdata[1] != ?D || cdata[2] != ?S || cdata[3] != 0x20
    printf "%s\n\tmagic <%c%c%c%c>\n", path, \
    cdata[0], cdata[1], cdata[2], cdata[3]
  end

  # mipsは0のものが多いが、8-10の値もある
  # flags: 0x1007 = PIXELFORMAT | WIDTH | HEIGHT | CAPS
  #        0x80000 = LINEARSIZE
  #        0xa0000 = LINEARSIZE | MIPMAPCOUNT
  if idata[1] != 124 \
    || idata[2] != 0x1007 && idata[2] != 0x81007 && idata[2] != 0xa1007
    printf "%s\n\tsize=%d flags=0x%x h=%d w=%d pl=0x%x depth=%d mips=%d\n", \
    path, idata[1], idata[2], idata[3], idata[4], idata[5], idata[6], idata[7]
  end

  # FOURCC = 0x0004
  if idata[19] != 32 || idata[20] != 4 \
    || cdata[84] != ?D \
    || cdata[85] != ?X \
    || cdata[86] != ?T \
    || cdata[87] != ?1 && cdata[87] != ?3 && cdata[87] != ?5 \
    || idata[22] != 0
    printf "%s\n\tpixelfmt: size=%d flags=0x%x fourcc=<%c%c%c%c> bpp=%d\n", \
    path, idata[19], idata[20], \
    cdata[84],cdata[85],cdata[86],cdata[87], idata[22]
  end

  if idata[23] != 0 || idata[24] != 0 || idata[25] != 0 || idata[26] != 0
    printf "%s\n\tpixelfmt: r=0x%x g=0x%x b=0x%x a=0x%x\n", \
    path, idata[23], idata[24], idata[25], idata[26]
  end

  # caps: 0x1000 = DDSCAPS_TEXTURE
  #       0x401008 = DDSCAPS_MIPMAP | DDSCAPS_TEXTURE | DDSCAPS_COMPLEX
  if idata[27] != 0x1000 && idata[27] != 0x401008 || idata[28] != 0
    printf "%s\n\tcaps: 0x%x 0x%x\n", path, idata[27], idata[28]
  end
end

check(ARGV[0])
