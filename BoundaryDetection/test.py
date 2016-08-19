#! /usr/bin/python
import sys
from TOSSIM import *

t = Tossim([])
#m = t.mac()
r = t.radio()

#t.addChannel("GENERAL", sys.stdout)
#t.addChannel("NeighborManagement", sys.stdout)
t.addChannel("BoundaryDetection", sys.stdout)

#for i in range(49):
#  m = t.getNode(i)
#  m.bootAtTime((31 + t.ticksPerSecond() / 10) * i + 1)

f = open("linkgain_hole.out", "r")
for line in f:
  s = line.split()
  if s:
    if s[0] == "gain":
      #print " ", s[1], " ", s[2], " ", s[3];
      r.add(int(s[1]), int(s[2]), float(s[3]))

noise = open("meyer-heavy.txt", "r")
for line in noise:
  s = line.strip()
  if s:
    val = int(s)
    for i in range(400):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(400):
  print "creating noise model for ", i;
  t.getNode(i).createNoiseModel()

for i in range(400):
  t.getNode(i).bootAtTime(i * 2351217 + 23542399)

#for i in range(1000):
#  t.runNextEvent()

t.runNextEvent();
time = t.time()
while (time + 50000000000000 > t.time()):
  t.runNextEvent()
