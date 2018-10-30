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
input string    Begin      = "01:00";   
input string    End        = "10:00"; 
input string    EndDay     = "23:30";

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
bool m_checkingDone = false;
bool m_endDay = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("OnInit version=", "003");
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
      // Before start checking time of day
      //if (m_Completed) m_Completed = false; // refresh checking completed variable
      //if (m_firstTime) m_firstTime = false;
      //if (m_checkingDone) m_checkingDone = false;
      if (m_endDay) m_endDay = false;
   }
      break;
   case 0: {
      if (!m_firstTime) {
         m_firstTime = true;
         Print("On first checking of day");
         OnStartTime();
      }
      UpdateMinMaxPrice();
   }
      break;
   case 1: {
      // After checking time
      if (!m_checkingDone) {
         Print("Process completed");
         m_checkingDone = true;
         OnEndTime();
      }
   }
      break;
   case 2: {
      // End of day
      if (!m_endDay) {
         m_endDay = true;
         OnEndOfDay();
         Refresh();
      }
   }
      break;
   default:
      break;
   }
   
}

void Refresh() {
   m_TradeRecord[0] = -1;
   m_TradeRecord[1] = -1;
   m_TradeCounter = 0;
   if (m_Completed) m_Completed = false; // refresh checking completed variable
   if (m_firstTime) m_firstTime = false;
   if (m_checkingDone) m_checkingDone = false;
}
void UpdateMinMaxPrice(){
   // Update min-max price
   price_min = min(Bid, price_min);
   price_max = max(Ask, price_max);
}
void OnStartTime(){
   price_min = Bid;
   price_max = Ask;
   m_firstTime = true;
}
void OnEndTime(){
   Trigger();
}
bool CheckCompleted() {
   bool isTrading = false;
   for (int i = 0; i < m_TradeCounter; i++) {
      int ticket = m_TradeRecord[i];
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY))
        {
         isTrading = true;
        }
      else
        {
         //Print("Could not select trade by ticket: #", ticket);
        }
   }
   return !isTrading;
}

void OnEndOfDay() {
   for (int i = 0; i < m_TradeCounter; i++) {
      int ticket = m_TradeRecord[i];
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) //opened and pending orders
        {
         if (OrderType() == OP_BUY) {
            if (!OrderClose(ticket,OrderLots(),Ask,3,Red)) {
               OrderClose(ticket,OrderLots(),Bid,3,Red);
            }
         }
         else if (OrderType() == OP_SELL) {
            if (!OrderClose(ticket,OrderLots(),Ask,3,Red)) {
               OrderClose(ticket,OrderLots(),Bid,3,Red);
            }
         }
         else {
            // OrderDelete(ticket);
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
   else if (oriTime > EndDay) return 2;
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
   Print("Trigger: price_max=", price_max, " price_min=", price_min);
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
