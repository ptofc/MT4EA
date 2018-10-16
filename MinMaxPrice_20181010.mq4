//+------------------------------------------------------------------+
//|                                                MichaelBalack.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


input double    LotSize    =1;
input double    TakeProfit =10; // TakeProfit in pip
input double    StopLoss   =10; // StopLoss in pip    
input string    Begin    = "01:00";   
input string    End      = "10:00";  

// API
// StrToTime

double price_max = 0;
double price_min = 0;

enum TRADE_STATUS {
   None,
   WaitingForOpen,
   WaitingForClose,
   Closed
};

bool m_Completed = false;
bool m_IsTriggered = false;
int  m_TradeRecord[2];
int  m_TradeCounter = 0;
int cnt = 0;

bool checklog = false;
bool m_firstTime = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("OnInit version=", "002");
   Print("Current bar for USDCHF H1: ",iTime("USDCHF",PERIOD_H1,0),", ",  iOpen("USDCHF",PERIOD_H1,0),", ", 
                                      iHigh("USDCHF",PERIOD_H1,0),", ",  iLow("USDCHF",PERIOD_H1,0),", ", 
                                      iClose("USDCHF",PERIOD_H1,0),", ", iVolume("USDCHF",PERIOD_H1,0));
   m_TradeRecord[0] = -1;
   m_TradeRecord[1] = -1;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime dt=CurTime();
   string strCurrentTime = TimeToStr(dt, TIME_MINUTES);   
   
   switch(CheckTime(strCurrentTime)) {
   case -1: {
      // Before start time of day
      if (m_Completed) m_Completed = false; // refresh checking completed variable
      if (m_firstTime) m_firstTime = false;
   }
      break;
   case 1: {
      // After end time of day
   }
      break;
   case 0:
   default: {
      if (m_Completed) return;
      if (!m_firstTime) {
         Print("First time of day");
         price_min = Bid;
         price_max = Ask;
         m_firstTime = true;
      }
      // Update min-max price
      price_min = min(Bid, price_min);
      price_max = max(Ask, price_max);
      
      if (!m_IsTriggered) {
         Trigger();
         if (m_TradeCounter == 0) {
            Print("Something error but i dont know why ^^ ");
            m_Completed = true;
         }
      }
      else {
         //Print("Debug m_TradeCounter = ", m_TradeCounter);
         for (int i = 0; i < m_TradeCounter; i++) {
            int ticket = m_TradeRecord[i];
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY))
              {
               //Print("Ticket[MODE_HISTORY] #", ticket, " type=", OrderType());
               if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                  Print("Ticket[MODE_HISTORY] #", ticket, " type=", OrderType());
                  m_Completed = true;
               }
              }
            else if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
              {
               //Print("Ticket[MODE_TRADES] #", ticket, " type=", OrderType());
               if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                  Print("Ticket[MODE_TRADES] #", ticket, " type=", OrderType());
                  m_Completed = true;
               }
              }
            else
              {
               //Print("Could not select trade by ticket: #", ticket);
              }
         }
      }
   } // default
      break;
   }
   
}
void OnEndOfDay() {
   bool boolRes=OrderClose(OrderTicket(),OrderLots(),dblClosePrice,I_Slippage,clrWhite);
   for (int i = 0; i < m_TradeCounter; i++) {
      int ticket = m_TradeRecord[i];
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY))
        {
         if (OrderType() != 4 && OrderType() != 5) {
            Print("Ticket[MODE_HISTORY] #", ticket, " type=", OrderType());
            m_Completed = true;
         }
        }
      else if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         if (OrderType() != 4 && OrderType() != 5) {
            Print("Ticket[MODE_TRADES] #", ticket, " type=", OrderType());
            m_Completed = true;
         }
        }
      else
        {
        }
   }
}

double min(double a, double b)
{
   return a>b? b : a;
}
double max(double a, double b)
{
   return a>b? a : b;
}
bool TimeCompare(datetime current,datetime origin)
{
   if (current >= origin) {
      return true;
   }
   return false;
}
int CheckTime(string oriTime) {
   if (oriTime < Begin) return -1;
   else if (oriTime > End) return 1;
   else return 0;
}
bool isOnProcessingTime(string oriTime) {
   if (Begin <= oriTime && oriTime <= End) return true;
   return false;
}
bool isBeforeStartTime(string oriTime) {
   return Begin > oriTime? true: false;
}
bool isAfterEndTime(string oriTime) {
   return End < oriTime? true: false;
}
void Trigger()
{
   Print("Trigger: bid=", Bid, " ask=", Ask);
   m_IsTriggered = true;
   BuyStopFunc();
   SelStopFunc();
}
void BuyStopFunc()
{
   //--- place market order to buy 1 lot
   // int ticket=OrderSend(Symbol(),OP_BUY,1,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
   double price = price_max;// + 0.1;
   double sl = price - StopLoss * Point;
   double tp = price + TakeProfit * Point;
   Print("BuyStopFunc: ", " price=",price, " tp=",tp, " sl=",sl);
   int ticket=OrderSend(Symbol(),OP_BUYSTOP,LotSize,price,30,sl,tp,"ThieuDC",0,0,White);
   if(ticket<0)
     {
      Print("BuyStopFunc OrderSend failed with error #",GetLastError());
     }
   else {
      m_TradeRecord[m_TradeCounter] = ticket;
      m_TradeCounter++;
      Print("BuyStopFunc OrderSend placed successfully");
   }
}

void SelStopFunc()
{
   double price = price_min;// - 0.1;
   double sl = price + StopLoss * Point;
   double tp = price - TakeProfit * Point;
   Print("SelStopFunc: ", " price=",price, " tp=",tp, " sl=",sl);
   int ticket=OrderSend(Symbol(),OP_SELLSTOP,LotSize,price,30,sl,tp,"ThieuDC",0,0,White);
   if(ticket<0)
     {
      Print("SelStopFunc OrderSend failed with error #",GetLastError());
     }
   else {   
      m_TradeRecord[m_TradeCounter] = ticket;
      m_TradeCounter++;
      Print("SelStopFunc OrderSend placed successfully");
   }
}