#0000simple-negative-price.cmd
#registerTester ignores lines which start with a # and blank lines
#the other interfaces also ignore blank lines

#the clerk id
100
#the clerk passcode
100

#this is plu 2 for 100.00
1*-10000@2

#subt (in case we're running this manually)
/subt

#tender it to cash
/tender0
