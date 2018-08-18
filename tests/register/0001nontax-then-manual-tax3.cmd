#0001nontax-then-manual-tax3.cmd
#registerTester ignores lines which start with a # and blank lines
#the other interfaces also ignore blank lines

#the clerk id
100
#the clerk passcode
100

#load a non-taxable customer
12345/cust

#this is plu 1 for 100.00
10000@1

#this should override the customer's tax setting
/taxable

#subt (in case we're running this manually)
/subt

#tender it to cash
/tender0
