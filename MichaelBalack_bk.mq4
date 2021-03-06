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
input double    TakeProfit =20; // TakeProfit in pip
input double    StopLoss   =20; // StopLoss in pip    
input string    Begin    = "15:00";   
input string    End      = "20:00";  

double price_max = 0;
double price_min = 0;
datetime time_start = 0;
datetime time_end = 0;

enum TRADE_STATUS {
   None,
   WaitingForOpen,
   WaitingForClose,
   Closed
};

TRADE_STATUS m_BuyStop;
TRADE_STATUS m_SellStop;
bool m_Running = false;
bool m_Completed = false;
bool m_IsTriggered = false;
int  m_TradeCounter = 0;

bool m_buystop_ok = false;
bool m_selstop_ok = false;
int cnt = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("OnInit");
   Print("Current bar for USDCHF H1: ",iTime("USDCHF",PERIOD_H1,0),", ",  iOpen("USDCHF",PERIOD_H1,0),", ", 
                                      iHigh("USDCHF",PERIOD_H1,0),", ",  iLow("USDCHF",PERIOD_H1,0),", ", 
                                      iClose("USDCHF",PERIOD_H1,0),", ", iVolume("USDCHF",PERIOD_H1,0));
   time_start = StrToTime(Begin);
   time_end = StrToTime(End);
   datetime dt = CurTime();
   Print(time_start);
   Print(time_end);
   Print(dt);
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
//---
   Print("OnTick");
   
   if (m_Completed) return;
   
   int intCount=OrdersTotal();
   if (!m_Running) {
      if (intCount == 0) {
         m_Running = true;
      }
      else {
         Print("Close all oders before running EA. Total = ", intCount);
         return;
      }
   }
   else {   
      datetime dt=CurTime();
      if (!TimeCompare(dt, time_start)) return; // Waiting for Begin_time
      
      // Update min-max price
      price_min = min(Bid, price_min);
      price_max = max(Ask, price_max); 
       
      // Trigger when current time more than End_time
      if (TimeCompare(dt, time_end)) {
         if (!m_IsTriggered) {
            m_IsTriggered = true;
            Trigger();
            int check=OrdersTotal();
            if (check == m_TradeCounter) {
               Print("Its OK! ");
            }
            else {
               Print("Deo hieu.  check = ", check, " tradeNum = ", m_TradeCounter);
            }
         }
         else {
            if (m_IsTriggered > intCount) {
               Print("Done! ");
               m_Completed = true;
            }
            else {
               Print("Debug. m_Completed = ", m_Completed, " Total = ", intCount);
            }
         }    
      }
      
      // Just for testing (cnt)
      cnt++;
      if (cnt == 3) {
         Trigger();      
      }
   }
   
  }
//+------------------------------------------------------------------+

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
void Trigger()
{
   // coding something here
   if(!m_buystop_ok) {
      BuyStopFunc();
   }
   if(!m_selstop_ok) {
      SelStopFunc();
   }
}
void BuyStopFunc()
{
   //--- place market order to buy 1 lot
   // int ticket=OrderSend(Symbol(),OP_BUY,1,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
   double price = price_max+0.1;
   double sl = price - StopLoss * Point;
   double tp = price + TakeProfit * Point;
   Print("BuyStopFunc: ", " price=",price, " tp=",tp, " sl=",sl);
   int ticket=OrderSend(Symbol(),OP_BUYSTOP,LotSize,price,30,sl,tp,"ThieuDC",0,0,White);
   if(ticket<0)
     {
      Print("BuyStopFunc OrderSend failed with error #",GetLastError());
     }
   else {
      m_TradeCounter++;
      m_buystop_ok = true;
      m_selstop_ok = true;
      Print("BuyStopFunc OrderSend placed successfully");
   }
}

void SelStopFunc()
{
   double price = price_min-0.1;
   double sl = price + StopLoss * Point;
   double tp = price - TakeProfit * Point;
   Print("SelStopFunc: ", " price=",price, " tp=",tp, " sl=",sl);
   int ticket=OrderSend(Symbol(),OP_SELLSTOP,LotSize,price,30,sl,tp,"ThieuDC",0,0,White);
   if(ticket<0)
     {
      Print("SelStopFunc OrderSend failed with error #",GetLastError());
     }
   else {   
      m_TradeCounter++;
      m_buystop_ok = true;
      m_selstop_ok = true;
      Print("SelStopFunc OrderSend placed successfully");
   }
}