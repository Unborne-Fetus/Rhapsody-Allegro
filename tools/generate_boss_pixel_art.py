"""Generate deterministic, original 64x88 pixel-art sprites for Allegro's 12 musical bosses.
6 genuine poses each: idle A/B, movement L/R, windup, recoil.
No copyrighted recordings, lyrics, faces or outside artwork.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import math,base64
OUT = Path(__file__).resolve().parents[1] / 'assets'
W,H = 64,88
INK='#171522'; BLACK='#0c1220'; WHITE='#fce8d0'; GOLD='#ffda79'
BOSSES=[
 ('METRONOME','#ef7854','#8a3748','#f5c86b','#b9d5d9','#28243d','#f5ce8d','metronome'),
 ('GLASS CANTOR','#54dfd7','#3a7991','#e6f8fa','#b8eee9','#264459','#f8ece2','cantor'),
 ('CONDUCTOR','#c5a0ff','#33285a','#f4e9ff','#e6d3d1','#242039','#f7e3ce','conductor'),
 ('VELVET FUSE','#ee6ba8','#71375e','#fbb5d0','#efd0ab','#222034','#ead5bd','crooner'),
 ('CINDER KING','#ff9351','#b8493f','#f7d477','#e4b591','#342b35','#efd1aa','cinder'),
 ('EVERLASTING PARADE','#6de6c8','#6652a3','#f4d579','#bb785b','#28284d','#f4ccae','parade'),
 ('FEEDBACK TYRANT','#b69bff','#4c3c87','#ee7ca3','#e0ac90','#26233d','#f2d1bb','rocker'),
 ('STORM SISTERS','#79d1ff','#387ba9','#d1f5fa','#c4896e','#243d6d','#f4dbbe','sisters'),
 ('STAR ASCENDANT','#ff6eb9','#9c337f','#ffe1a0','#b9815e','#41305d','#efc4a5','star'),
 ('SPELLBOUND EMPRESS','#b19aec','#49377d','#d6c3ff','#98634b','#2e2a52','#e0a88b','empress'),
 ('DISCO ALCHEMIST','#ffcb64','#bb7b3b','#f5eaa2','#a96f55','#43385e','#efc49d','alchemist'),
 ('SOUL MARSHAL','#fa6f60','#8c334b','#ffe4a0','#87523f','#28243b','#cb8e76','marshal'),
]

def rect(d,x,y,w,h,c,outline=None):
 if w<=0 or h<=0:return
 d.rectangle([round(x),round(y),round(x+w-1),round(y+h-1)],fill=c,outline=outline)
def poly(d,pts,c,outline=None):
 d.polygon([(round(x),round(y)) for x,y in pts],fill=c)
 if outline:d.line([(round(x),round(y)) for x,y in pts+[pts[0]]],fill=outline,width=2,joint='curve')
def line(d,points,c,w=2):d.line([(round(x),round(y)) for x,y in points],fill=c,width=w,joint='curve')
def ellipse(d,box,c,outline=None,width=1):d.ellipse(box,fill=c,outline=outline,width=width)

def sprite(index,frame):
 name,accent,coat,shine,skin,pants,shoes,style=BOSSES[index]
 img=Image.new('RGBA',(W,H))
 d=ImageDraw.Draw(img)
 action=frame==4;hurt=frame==5
 walk=frame in (2,3)
 stride= (-4 if frame==2 else 4 if frame==3 else 0)
 bx=(2 if hurt else 0)
 bob=(1 if frame==1 else -2 if action else 0)
 by=bob+(2 if hurt else 0)
 # underfoot contact shadow, pixel squares not baked into a dark rectangle
 rect(d,18,84,28,2,'#13172b')
 rect(d,25,85,14,1,'#2b2b40')
 # signature props worn BEHIND body
 if style in ('conductor','crooner','cinder','empress','marshal'):
  poly(d,[(17+bx,39+by),(13+bx,72),(7+bx,79),(29+bx,73)],coat,INK)
  poly(d,[(47+bx,39+by),(51+bx,72),(57+bx,79),(34+bx,73)],accent,INK)
 if style=='cantor':
  for x,y in ((10,32),(54,32),(12,14),(49,11)):
   poly(d,[(x,y+12),(x-4,y+4),(x+2,y-6),(x+6,y+4)],accent,INK)
 if style=='rocker':
  for x in [6,55]:
   rect(d,x,40,4,23,coat,INK);rect(d,x,42,3,8,accent)
 if style=='sisters':
  # paired vocalists have two independent faces and dresses, not one monster
  for off,hand in ((-13,-1),(13,1)):
   cx=32+off+bx
   poly(d,[(cx-9,47),(cx+9,47),(cx+13,79),(cx-13,79)],'#3985ba' if off<0 else '#50aeb9',INK)
   rect(d,cx-6,57,12,4,shine);rect(d,cx-4,42,8,13,skin,INK)
   rect(d,cx-9,16+by,18,22,'#222c53' if off<0 else '#45446d',INK)
   ellipse(d,[cx-7,22+by,cx+7,42+by],skin,INK,2)
   rect(d,cx-6,28+by,3,2,INK);rect(d,cx+3,28+by,3,2,INK)
   rect(d,cx-12,46+by,5,14,skin,INK);rect(d,cx+7,45+by,5,14,skin,INK)
   rect(d,cx-7,77,6,5,shoes,INK);rect(d,cx+2,77,6,5,shoes,INK)
   if off<0:
    line(d,[(cx+11,48),(cx+15,29+(6 if action else 0))],GOLD,3)
    ellipse(d,[cx+11,25,cx+19,34],WHITE,INK,2)
   else:
    line(d,[(cx+10,49),(cx+16,34+(4 if action else 0))],INK,3)
    ellipse(d,[cx+13,27,cx+21,35],WHITE,INK,2)
  if action:
   poly(d,[(9,12),(22,7),(28,13),(22,16)],GOLD)
   poly(d,[(35,8),(44,4),(52,13),(45,16)],shine)
  return img
 # legs, with separate walking stride keyed into each pose
 lx=22+stride;rx=36-stride
 rect(d,lx-6,62,12,19,pants,INK);rect(d,lx-5,67,3,11,accent)
 rect(d,rx-5,62,12,19,pants,INK);rect(d,rx-4,66,3,9,accent)
 poly(d,[(lx-6,79),(lx+6,79),(lx+8,84),(lx-9,84)],shoes,INK)
 poly(d,[(rx-5,79),(rx+7,79),(rx+9,84),(rx-9,84)],shoes,INK)
 rect(d,lx-7,82,15,2,INK);rect(d,rx-7,82,15,2,INK)
 # torso / expressive stage costume
 if style=='cantor':
  poly(d,[(20+bx,43+by),(43+bx,43+by),(54+bx,77),(11+bx,77)],coat,INK)
  poly(d,[(29+bx,44+by),(36+bx,44+by),(43+bx,72),(21+bx,72)],shine)
  rect(d,29+bx,54+by,6,10,accent)
 elif style=='star':
  poly(d,[(20+bx,40+by),(45+bx,40+by),(47+bx,65),(18+bx,65)],coat,INK)
  rect(d,25+bx,42+by,15,19,accent);rect(d,29+bx,45+by,7,8,WHITE)
  poly(d,[(25,62),(40,62),(47,70),(17,70)],accent,INK)
 else:
  rect(d,17+bx,39+by,30,28,INK)
  rect(d,19+bx,40+by,26,25,coat)
  rect(d,26+bx,41+by,12,22,shine)
  rect(d,23+bx,44+by,5,16,accent)
  rect(d,38+bx,44+by,5,16,accent)
  rect(d,28+bx,63+by,9,3,INK)
 # costume trim + distinct emblem
 if style in ('metronome','conductor','marshal'):
  rect(d,24+bx,43+by,4,4,GOLD);rect(d,37+bx,43+by,4,4,GOLD)
  rect(d,28+bx,53+by,9,3,GOLD)
 elif style=='rocker':
  rect(d,19+bx,41+by,7,5,accent);rect(d,40+bx,41+by,5,5,accent)
  rect(d,30+bx,54+by,5,3,WHITE)
 elif style=='parade':
  rect(d,19+bx,41+by,7,5,GOLD);rect(d,38+bx,41+by,6,5,GOLD)
  rect(d,28+bx,55+by,9,4,accent)
 elif style=='alchemist':
  rect(d,25+bx,44+by,14,16,WHITE);rect(d,29+bx,47+by,6,7,accent)
 # arms and hands keyed independently
 lefty=48+by+(4 if frame==2 else -4 if frame==3 else -8 if action else 2 if hurt else 0)
 righty=48+by+(-4 if frame==2 else 4 if frame==3 else -10 if action else 2 if hurt else 0)
 line(d,[(20+bx,44+by),(10+bx,53+by),(10+bx,lefty+7)],INK,8)
 line(d,[(20+bx,44+by),(10+bx,53+by),(10+bx,lefty+7)],coat,5)
 line(d,[(44+bx,44+by),(54+bx,51+by),(54+bx,righty+7)],INK,8)
 line(d,[(44+bx,44+by),(54+bx,51+by),(54+bx,righty+7)],coat,5)
 rect(d,7+bx,lefty+5,7,7,skin,INK)
 rect(d,51+bx,righty+5,7,7,skin,INK)
 # face shape
 rect(d,24+bx,34+by,16,9,skin)
 ellipse(d,[19+bx,12+by,46+bx,39+by],INK)
 ellipse(d,[22+bx,16+by,43+bx,37+by],skin)
 rect(d,21+bx,23+by,3,6,skin)
 rect(d,43+bx,23+by,2,6,skin)
 # faces styled differently
 if style=='metronome':
  rect(d,23+bx,13+by,19,24,shine,INK)
  rect(d,25+bx,17+by,15,12,WHITE)
  rect(d,31+bx,19+by,3,10,INK);rect(d,32+bx,23+by,8,2,INK)
  ellipse(d,[29+bx,25+by,35+bx,31+by],accent,INK)
  # tall metronome counterweight headpiece
  poly(d,[(24+bx,15+by),(32+bx,2+by),(40+bx,15+by)],GOLD,INK)
  rect(d,30+bx,4+by,4,16,coat)
 elif style=='cantor':
  poly(d,[(18+bx,20+by),(24+bx,8+by),(30+bx,16+by),(35+bx,4+by),(46+bx,23+by)],accent,INK)
  rect(d,22+bx,18+by,20,4,shine)
  rect(d,27+bx,26+by,3,3,INK);rect(d,38+bx,26+by,3,3,INK)
  rect(d,31+bx,33+by,6,2,coat)
 elif style=='conductor':
  rect(d,18+bx,10+by,28,9,INK);rect(d,20+bx,4+by,24,9,pants,INK)
  rect(d,19+bx,12+by,26,3,accent)
  rect(d,25+bx,26+by,3,3,INK);rect(d,39+bx,26+by,3,3,INK)
  line(d,[(29+bx,34+by),(38+bx,34+by)],INK,2)
 elif style=='crooner':
  rect(d,18+bx,12+by,28,8,INK)
  rect(d,22+bx,9+by,24,8,coat)
  rect(d,23+bx,13+by,18,3,accent)
  rect(d,27+bx,26+by,3,3,INK);rect(d,38+bx,26+by,3,3,INK)
  rect(d,31+bx,33+by,6,2,coat)
  poly(d,[(34,41),(39,41),(34,47)],accent)
 elif style=='cinder':
  poly(d,[(17+bx,18+by),(22+bx,9+by),(21+bx,5+by),(30+bx,10+by),(34+bx,2+by),(43+bx,7+by),(47+bx,19+by)],INK)
  rect(d,25+bx,11+by,18,7,BLACK)
  rect(d,26+bx,26+by,3,3,INK);rect(d,39+bx,26+by,3,3,INK)
  rect(d,33+bx,34+by,6,2,INK)
  poly(d,[(46+bx,36),(54+bx,22),(49+bx,15),(57+bx,9),(56+bx,40)],accent,INK)
 elif style=='parade':
  ellipse(d,[19+bx,3+by,46+bx,21+by],INK)
  rect(d,23+bx,5+by,18,8,accent)
  rect(d,23+bx,17+by,20,6,INK)
  rect(d,25+bx,18+by,17,3,shine)
  rect(d,27+bx,27+by,3,3,INK);rect(d,39+bx,27+by,3,3,INK)
 elif style=='rocker':
  for cx,cy,w,h in ((18,9,9,14),(25,3,11,18),(35,6,12,14),(42,13,8,14)):
   rect(d,cx+bx,cy+by,w,h,INK);rect(d,cx+bx+2,cy+by+2,w-3,h-4,accent)
  rect(d,26+bx,25+by,5,4,INK);rect(d,37+bx,25+by,5,4,INK)
  rect(d,29+bx,34+by,10,2,INK)
 elif style=='star':
  rect(d,19+bx,12+by,26,12,pants,INK)
  rect(d,25+bx,12+by,14,6,accent)
  rect(d,24+bx,14+by,20,3,shine)
  rect(d,27+bx,26+by,3,3,INK);rect(d,37+bx,26+by,3,3,INK)
  poly(d,[(33,5),(35,9),(41,9),(37,12),(39,17),(33,14),(27,17),(29,12),(25,9),(31,9)],GOLD,INK)
 elif style=='empress':
  ellipse(d,[14+bx,5+by,49+bx,28+by],INK)
  ellipse(d,[18+bx,7+by,45+bx,24+by],coat)
  rect(d,17+bx,18+by,29,12,INK)
  rect(d,22+bx,23+by,20,5,coat)
  rect(d,27+bx,26+by,3,3,INK);rect(d,38+bx,26+by,3,3,INK)
  rect(d,31+bx,34+by,7,2,INK)
  rect(d,21+bx,10+by,4,3,shine);rect(d,40+bx,10+by,4,3,shine)
 elif style=='alchemist':
  ellipse(d,[16+bx,6+by,49+bx,25+by],INK)
  rect(d,19+bx,9+by,25,13,coat)
  rect(d,21+bx,22+by,25,7,INK)
  rect(d,23+bx,23+by,21,4,shine)
  rect(d,26+bx,26+by,6,4,INK);rect(d,36+bx,26+by,6,4,INK)
  rect(d,28+bx,27+by,3,2,accent);rect(d,38+bx,27+by,3,2,accent)
 else: # marshal
  rect(d,18+bx,8+by,27,12,INK)
  rect(d,20+bx,10+by,23,5,accent)
  rect(d,21+bx,7+by,18,3,GOLD)
  rect(d,27+bx,26+by,3,3,INK);rect(d,38+bx,26+by,3,3,INK)
  rect(d,30+bx,34+by,7,2,INK)
 # musical accessories / performances all bosses musicians
 if style in ('metronome','conductor'):
  ey=9 if action else 29+(frame%2)*3
  line(d,[(55+bx,righty+7),(56+bx,ey+by)],INK,4)
  line(d,[(55+bx,righty+7),(56+bx,ey+by)],GOLD,2)
  if action:poly(d,[(46,9),(50,2),(54,9)],shine)
 elif style=='cantor':
  poly(d,[(51+bx,righty+7),(56+bx,righty-6),(61+bx,righty+4),(55+bx,righty+10)],accent,INK)
  if action:
   poly(d,[(1,35),(9,27),(11,36),(8,42)],shine)
 elif style=='crooner':
  line(d,[(53+bx,righty+7),(54+bx,righty-3)],INK,4)
  ellipse(d,[50+bx,righty-12,59+bx,righty-3],WHITE,INK,2)
  if action:
   rect(d,58,17,3,4,accent);rect(d,60,11,2,4,shine)
 elif style=='cinder':
  line(d,[(52+bx,righty+6),(57+bx,righty-3)],GOLD,3)
  poly(d,[(52,righty-4),(56,righty-17 if action else righty-11),(60,righty-7),(58,righty-1)],accent)
 elif style=='parade':
  ellipse(d,[1,9,17,25],INK)
  ellipse(d,[3,11,15,23],shine)
  rect(d,8,13,2,10,WHITE)
  for xx,yy in ((4,8),(17,4),(51,6),(59,18)):
   rect(d,xx,yy,3,3,GOLD)
 elif style=='rocker':
  # pink razor-edged guitar with visible neck and strings
  poly(d,[(13,57),(20,46),(27,53),(37,43),(42,56),(29,60),(23,69)],accent,INK)
  line(d,[(28,53),(58,27 if action else 36)],GOLD,6)
  line(d,[(28,53),(58,27 if action else 36)],WHITE,2)
 elif style=='star':
  line(d,[(52+bx,righty+6),(55+bx,righty-4)],INK,4)
  ellipse(d,[51+bx,righty-12,59+bx,righty-4],WHITE,INK)
  for xx,yy in ((11,8),(50,11),(56,38)):
   rect(d,xx,yy,3,3,GOLD)
 elif style=='empress':
  # Floating ivory piano keys on left, microphone on right
  for xx in range(4,20,5):
   rect(d,xx,44+(xx%3)*2,4,19,WHITE,INK)
   rect(d,xx+2,44+(xx%3)*2,2,10,INK)
  line(d,[(54+bx,righty+7),(53+bx,righty-5)],GOLD,3)
  ellipse(d,[50+bx,righty-13,57+bx,righty-5],shine,INK)
 elif style=='alchemist':
  ellipse(d,[1,48,24,72],BLACK,accent,3)
  ellipse(d,[6,53,19,67],shine)
  ellipse(d,[10,58,15,63],INK)
  rect(d,55,45+(4 if action else 0),5,12,GOLD,INK)
 elif style=='marshal':
  line(d,[(54+bx,righty+6),(56+bx,righty-2)],GOLD,3)
  ellipse(d,[51+bx,righty-11,60+bx,righty-2],WHITE,INK)
  rect(d,20+bx,43+by,5,5,GOLD)
  rect(d,39+bx,43+by,5,5,GOLD)
 if action and style not in ('sisters','cantor','crooner','parade','rocker','star'):
  rect(d,2,28,3,4,accent);rect(d,5,21,3,4,shine)
 if hurt:
  rect(d,8,10,5,2,WHITE);rect(d,11,7,2,5,accent)
 return img

def main():
 atlas=Image.new('RGBA',(W*12,H*6))
 for i in range(12):
  for pose in range(6):
   atlas.alpha_composite(sprite(i,pose),(i*W,pose*H))
 # Source is regenerated deterministically; only the compact indexed atlas is shipped.
 OUT.mkdir(parents=True, exist_ok=True)
 # cheap color quantization with alpha=0 transparent index
 bg=Image.new('RGB',atlas.size,INK);bg.paste(atlas,mask=atlas.getchannel('A'))
 for n in (128,):
  q=bg.quantize(colors=n,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE)
  import numpy as np
  arr=np.array(q)
  # Transparent index 255 requires a full 256-entry PLTE; otherwise
  # PNG importers treat the background pixels as opaque black.
  arr[np.asarray(atlas.getchannel('A'))==0]=255
  fin=Image.fromarray(arr,'P')
  palette=q.getpalette()
  palette += [0]*max(0,768-len(palette))
  fin.putpalette(palette)
  fin.info['transparency']=255
  fin.save(OUT/'bosses-pixel.png',optimize=True)
  print('Wrote assets/bosses-pixel.png:', (OUT/'bosses-pixel.png').stat().st_size, 'bytes')
 print('Pose atlas:', atlas.size, '| 12 bosses x 6 animations')
if __name__=='__main__':main()