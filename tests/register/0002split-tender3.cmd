#0002split-tender3.cmd
#registerTester ignores lines which start with a # and blank lines
#the other interfaces also ignore blank lines

#the clerk id
100
#the clerk passcode
100

#this is plu 1 for 100.00
10000@2

#subt (in case we're running this manually)
/subt

#tender it to cash
2500/tender0
/subt
#different final tender
3500/tender1
4000/tender0

