//+------------------------------------------------------------------+
//|                                   support_ressistance_zigzag.mq4 |
//|                                                  EslamAhmedKamel |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "EslamAhmedKamel"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
//
// Inputs
//
// zizag inputs
input int InpDepth     = 12 ;  // Depth
input int InpDeviation = 5  ;  // Deviation
input int InpBackStep  = 3  ;  // Backstep

// peak analysis inputs
input int InpGapPoints   = 100  ; // Minimum gap between peaks in points
input int InpSensitivity = 2    ; // Peak Sensitvity
input int InpLookBack    = 50   ; // look back period

// Drawing Inputs
input string InpPrefix     = "SRLevel_" ; // object name prefix
input color  InpLineColor  = clrYellow  ; // line color
input int    InpLineWeight = 2          ; // line weight

double srLevels[] ;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
// clean any support and ressistance level you have drown before
   ObjectsDeleteAll(0,InpPrefix,0,  OBJ_HLINE) ;
   ChartRedraw(0);
   ArrayResize(srLevels, InpLookBack) ;
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,InpPrefix,0,  OBJ_HLINE) ;
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
// convert points to price gap
   static double levelGap = InpGapPoints * SymbolInfoDouble(Symbol(), SYMBOL_POINT);

// only calculate on new bars
   if(rates_total == prev_calculated)
     {
      return (rates_total);
     }
// get the most recent lookback peaks
   double zz = 0 ;
   double zzPeaks[] ;
   int zzCount = 0 ;
   ArrayResize(zzPeaks, InpLookBack);
   ArrayInitialize(zzPeaks, 0.0);

   for(int i=1; i<rates_total && zzCount < InpLookBack ; i++)
     {
      zz = iCustom(Symbol(), Period(), "ZigZag",InpDepth, InpDeviation, InpBackStep, 0, i);
      if(zz !=0 && zz != EMPTY_VALUE)
        {
         zzPeaks[zzCount] = zz ;
         zzCount++ ;
        }
     }
   ArraySort(zzPeaks)  ;

// Search grouping and set levels
   int srCounter = 0 ;
   double price = 0 ;
   int priceCount = 0 ;
   ArrayInitialize(srLevels, 0.0);
   for(int i=InpLookBack-1; i>=0; i--)
     {
      price += zzPeaks[i] ;
      priceCount++ ;
      if(i == 0 || (zzPeaks[i]-zzPeaks[i-1])> levelGap)
        {
         if(priceCount > InpSensitivity)
           {
            price = price/priceCount ;
            srLevels[srCounter] = price;
            srCounter ++ ;
           }
           price = 0 ;
           priceCount = 0 ;
        }
         drawLevel();
     }


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

void drawLevel()
{
   for(int i=0;i<InpLookBack;i++)
     {
      string name = InpPrefix + IntegerToString(i);
      if(srLevels[i]==0)
        {
         ObjectDelete(0,name) ;
         continue ;
        }
      if(ObjectFind(0 , name) < 0)
        {
         ObjectCreate(0,name, OBJ_HLINE , 0 , 0  ,srLevels[i]);
         ObjectSetInteger(0,name , OBJPROP_COLOR , InpLineColor);
         ObjectSetInteger(0,name , OBJPROP_WIDTH , InpLineWeight);
         ObjectSetInteger(0,name , OBJPROP_SELECTABLE , true);
        }  
      else
        {
            ObjectSetDouble(0,name, OBJPROP_PRICE , srLevels[i]);
        }  
     }
     ChartRedraw();
}