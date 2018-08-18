#0003event-discount.cmd
#registerTester ignores lines which start with a # and blank lines
#the other interfaces also ignore blank lines

#the clerk id
100
#the clerk passcode
100

#this is plu 1 for 100.00
10000@2

#50% sale discount
/disc50

#subt (in case we're running this manually)
/subt

#tender it to cash
/tender0
