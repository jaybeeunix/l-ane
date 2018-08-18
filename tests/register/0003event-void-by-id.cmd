#0003event-void-by-id.cmd
#registerTester ignores lines which start with a # and blank lines
#the other interfaces also ignore blank lines

#the clerk id
100
#the clerk passcode
100

#this is plu 2 for 150.00
15000@2

#subt (in case we're running this manually)
/subt

/tender0

100
100
%{lastSaleId}/voidById
y

#so the register can remain open
/cancel
