"""Render original, deterministic boss scores. No recordings, samples or borrowed melodies.
Requires numpy and ffmpeg; runtime only needs the exported Ogg Vorbis files.
"""
from pathlib import Path
import subprocess, tempfile, json
import numpy as np
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'assets/music'
SCORES=[
 ('Clockwork Overture',128,45,'orchestra'),('Crystal Aria',112,50,'glass'),
 ('Last Auditorium',138,43,'orchestra'),('Velvet Voltage',118,45,'funk'),
 ('Cinder Boogie',144,40,'rock'),('Parade Forever',126,48,'disco'),
 ('Feedback Crown',148,40,'metal'),('Cloud Nine',122,53,'gospel'),
 ('Neon Audition',132,50,'dance'),('Midnight Incantation',104,45,'jazz'),
 ('Golden Groove',124,43,'disco'),('Soul Signal',130,46,'soul')]
def render(index,title,bpm,root,genre):
 beat=60/bpm; length=beat*64; count=round(length*RATE)
 audio=np.zeros((count,2)); extra=np.zeros_like(audio); rng=np.random.default_rng(2307+index)
 major=genre in ['disco','gospel','dance','soul','funk','rock']
 scale=[0,2,4 if major else 3,5,7,9 if major else 8,11 if major else 10,12]
 progression=[0,5,3,4] if major else [0,5,3,6]
 def add(target,start,duration,midi,gain,kind,pan=0):
  n=min(round(duration*RATE),count); t=np.arange(n)/RATE; frequency=440*2**((midi-69)/12)
  phase=2*np.pi*frequency*t
  if kind=='bass': value=np.sin(phase)+.22*np.sin(2*phase)
  elif kind=='keys': value=np.sin(phase)+.32*np.sin(2*phase)*np.exp(-t*7)+.12*np.sin(4*phase)
  elif kind=='glass': value=np.sin(phase)+.24*np.sin(phase*2.76)+.13*np.sin(phase*4.1)
  elif kind=='guitar': value=np.tanh(1.5*(np.sin(phase)+.35*np.sin(2*phase)+.15*np.sin(3*phase)))
  elif kind=='organ': value=np.sin(phase)+.28*np.sin(2*phase)+.18*np.sin(3*phase)
  elif kind=='brass': value=(np.sin(phase)+.35*np.sin(2*phase)+.18*np.sin(3*phase))*(1+.06*np.sin(2*np.pi*5*t))
  else: value=np.sin(phase)+.2*np.sin(2*phase)
  env=np.minimum(t/.008,1)*np.exp(-t/(duration*.48))*np.minimum((duration-t)/.035,1).clip(0,1)
  value=value*env*gain
  samples=np.column_stack((value*np.sqrt((1-pan)/2),value*np.sqrt((1+pan)/2)))
  begin=round(start*RATE)%count; available=min(n,count-begin)
  target[begin:begin+available]+=samples[:available]
  if available<n:target[:n-available]+=samples[available:]
 def drum(target,at,kind,gain):
  duration={'kick':.22,'snare':.15,'hat':.07,'clap':.18}[kind]
  t=np.arange(round(duration*RATE))/RATE; noise=rng.uniform(-1,1,len(t))
  if kind=='kick':v=np.sin(2*np.pi*(47*t+7*(1-np.exp(-t*30))))*np.exp(-t*20)
  elif kind=='snare':v=(noise*.65+np.sin(2*np.pi*185*t)*.35)*np.exp(-t*27)
  elif kind=='clap':v=noise*np.exp(-t*24)*(1+.4*np.sin(2*np.pi*45*t))
  else:v=(noise-np.roll(noise,1))*.45*np.exp(-t*65)
  start=round(at*RATE);n=min(len(v),count-start)
  target[start:start+n]+=v[:n,None]*gain
 lead='keys' if genre=='jazz' else ('glass' if genre=='glass' else ('guitar' if genre in ['rock','metal'] else 'brass'))
 chord_kind='organ' if genre in ['gospel','soul'] else ('guitar' if genre in ['rock','metal'] else 'keys')
 motifs=[[0,4,2,6,4,1,2,4],[4,2,1,0,2,4,6,5],[0,2,4,7,6,4,2,1],[2,4,1,5,4,2,0,4]]
 motif=motifs[index%4]
 for bar in range(16):
  chord=progression[(bar//2)%4]; base=root+scale[chord]
  for pulse in range(4):
   when=(bar*4+pulse)*beat
   if genre in ['disco','dance','gospel'] or pulse in [0,2]:drum(audio,when,'kick',.32)
   if pulse in [1,3]:drum(audio,when,'snare' if genre in ['rock','metal','orchestra'] else 'clap',.15)
   for off in [0,.5]:drum(audio,when+off*beat,'hat',.045 if off else .035)
   bass_note=base+(7 if pulse==2 else (12 if pulse==3 else 0))
   add(audio,when,.36*beat,bass_note,.24,'bass',-.05)
   if genre in ['funk','disco','soul']:add(audio,when+.5*beat,.25*beat,bass_note,.13,'bass')
   for note in [0,4 if major else 3,7,10 if genre=='jazz' else 12]:
    add(audio,when+(.5 if genre in ['disco','funk','dance'] else 0)*beat,.75*beat,base+12+note,.065,chord_kind,-.3)
   # A/B melodic phrases, with response and breathing space every fourth bar.
   if not (bar%4==3 and pulse>=2):
    degree=motif[(bar*4+pulse)%8]
    octave=12 if bar in [8,9,12,13] else 0
    add(audio,when+.12*beat,.72*beat,root+24+scale[degree]+octave,.13,lead,.22)
   for off in [0,.5]:
    step=(pulse*2+int(off*2)+bar)%4
    add(extra,when+off*beat,.27*beat,base+24+[0,3 if not major else 4,7,12][step],.095,'glass' if genre=='glass' else 'keys',(-.4 if step%2 else .4))
   if pulse in [0,2]:drum(extra,when+.5*beat,'kick',.12)
  if bar%4==3:
   for i in range(4):drum(extra,(bar*4+3+i*.25)*beat,'snare',.07+i*.025)
 for target in [audio,extra]:
  dry=target.copy()
  for delay,gain in [(.13,.13),(.27,.09),(.43,.05)]:target+=np.roll(dry,round(delay*RATE),axis=0)[:,::-1]*gain
 peak=max(np.abs(audio).max(),.01);audio*=.65/peak;extra*=.65/peak
 OUT.mkdir(parents=True,exist_ok=True)
 for suffix,data in [('',audio),('-intensity',extra)]:
  pcm=np.clip(data,-.95,.95).astype('<f4').tobytes()
  subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','f32le','-ar',str(RATE),'-ac','2','-i','pipe:0','-c:a','libvorbis','-q:a','3',str(OUT/f'boss-{index:02d}{suffix}.ogg')],input=pcm,check=True)
 return {'title':title,'bpm':bpm,'genre':genre,'duration':length,'root_midi':root,'bars':16}
if __name__=='__main__':
 metadata=[render(i,*score) for i,score in enumerate(SCORES)]
 (OUT/'scores.json').write_text(json.dumps(metadata,indent=2)+'\n')
 print('Rendered 12 original stereo themes plus 12 synchronized intensity layers.')
