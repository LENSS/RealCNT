#! /usr/bin/python
from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("topo4x4.txt", "r")

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

t.addChannel("DBG_USR3", sys.stdout)

noise = open("meyer-heavy.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(1, 17):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 17):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

t.getNode(1).bootAtTime(100000);
t.getNode(2).bootAtTime(200000);
t.getNode(3).bootAtTime(300000);
t.getNode(4).bootAtTime(400000);
t.getNode(5).bootAtTime(500000);
t.getNode(6).bootAtTime(600000);
t.getNode(7).bootAtTime(700000);
t.getNode(8).bootAtTime(800000);
t.getNode(9).bootAtTime(900000);
t.getNode(10).bootAtTime(1000000);
t.getNode(11).bootAtTime(1100000);
t.getNode(12).bootAtTime(1200000);
t.getNode(13).bootAtTime(1300000);
t.getNode(14).bootAtTime(1400000);
t.getNode(15).bootAtTime(1500000);
t.getNode(16).bootAtTime(1600000);
t.getNode(17).bootAtTime(1700000);

t.runNextEvent();
time = t.time()
while (time + 50000000000000 > t.time()):
  t.runNextEvent()

